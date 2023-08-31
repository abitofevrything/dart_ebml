import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import '../schema/predefined_schema.dart';
import '../schema/resolved_schema.dart';
import '../schema/schema.dart';
import 'element.dart';

const bitsPerByte = 8;
const vIntMax = 72057594037927934;
const nanosecondsPerMicrosecond = 1000;

class EbmlCodec extends Codec<Element, List<int>> {
  final Schema schema;

  final bool isLenient;

  const EbmlCodec(this.schema, {this.isLenient = false});

  @override
  EbmlEncoder get encoder => EbmlEncoder(schema);

  @override
  EbmlDecoder get decoder => EbmlDecoder(schema, isLenient: isLenient);
}

class EbmlDecoder extends Converter<List<int>, Element> {
  final Schema schema;

  final bool isLenient;

  const EbmlDecoder(this.schema, {this.isLenient = false});

  @override
  Element convert(List<int> input) {
    final outputSink = _ValueSink<Element>();
    final inputSink = startChunkedConversion(outputSink);

    inputSink.add(input);
    return outputSink.data as Element;
  }

  @override
  EbmlDecoderSink startChunkedConversion(Sink<Element> sink) => EbmlDecoderSink(
        sink,
        schema,
        isLenient: isLenient,
      );
}

class EbmlDecoderSink extends ByteConversionSink {
  final Sink<Element> output;
  final ResolvedSchema schema;
  final bool isLenient;

  EbmlDecoderSink(this.output, Schema schema, {this.isLenient = false})
      : schema = schema.resolve() {
    _startConversion();
  }

  static const _initialCapacity = 32;
  int _bufferFillIndex = 0;
  int _bufferReadIndex = 0;
  Uint8List _buffer = Uint8List(_initialCapacity);

  Completer<void> _nextChunkCompleter = Completer();
  Future<void> get _nextChunk => _nextChunkCompleter.future;

  @override
  void add(List<int> chunk) {
    if (_bufferFillIndex + chunk.length >= _buffer.length) {
      final oldBuffer = _buffer;
      final newLength = 1 << (_bufferFillIndex + chunk.length).bitLength;
      _buffer = Uint8List(newLength);
      _buffer.setRange(0, oldBuffer.length, oldBuffer);
    }

    _buffer.setRange(_bufferFillIndex, _bufferFillIndex + chunk.length, chunk);
    _bufferFillIndex += chunk.length;

    _nextChunkCompleter.complete();
    _nextChunkCompleter = Completer();
  }

  bool isClosed = true;

  @override
  void close() {
    // Any awaiting _read calls should error, as we are expecting input
    _nextChunkCompleter.completeError(FormatException('Unexpected end of input'));

    // Setting these to 0 will cause future calls to _read to also error
    _bufferReadIndex = 0;
    _bufferFillIndex = 0;

    output.close();
  }

  void _compact() {
    final unreadDataLength = _bufferFillIndex - _bufferReadIndex;

    final oldBuffer = _buffer;
    _buffer = Uint8List(max(1 << unreadDataLength.bitLength, _initialCapacity));
    _buffer.setRange(0, unreadDataLength, oldBuffer, _bufferReadIndex);

    _bufferReadIndex = 0;
    _bufferFillIndex = unreadDataLength;
  }

  Future<Uint8List> _read(int bytes) async {
    final result = Uint8List(bytes);
    int resultIndex = 0;
    int remaining = bytes;

    while (remaining > 0) {
      final toRead = min(remaining, _bufferFillIndex - _bufferReadIndex);
      result.setRange(
        resultIndex,
        resultIndex + toRead,
        _buffer,
        _bufferReadIndex,
      );
      _bufferReadIndex += toRead;
      resultIndex += toRead;
      remaining -= toRead;

      if (remaining > 0) {
        await _nextChunk;
      }
    }

    if (_bufferReadIndex > _buffer.length - (_buffer.length ~/ 4)) {
      // If over 75% of the buffer is read, compact it down
      _compact();
    }

    return result;
  }

  // Stream properties
  var _maxIDLength = 4;
  var _maxSizeLength = 8;
  Path _currentPath = const Path([]);
  var _currentSchema = headerSchema;

  void _startConversion() async {
    // Read header
    await _readAndOutputElement();

    // Read body
    _currentSchema = schema;
    await _readAndOutputElement();
    return;
  }

  Element? _overRead;
  int? _overReadSize;

  Future<({Element element, int size})> _readAndOutputElement({int? parentLength}) async {
    if (_overRead != null) {
      final result = (element: _overRead!, size: _overReadSize!);
      _overRead = null;
      _overReadSize = null;
      return result;
    }

    final (:id, length: idLength) = await _readElementId();
    final schemaElement = _getIdMapping()[_currentPath]?[id];

    if (schemaElement == null) {
      throw FormatException('Invalid element id at current location');
    }

    final parentPath = _currentPath;
    _currentPath = schemaElement.path;

    final (:size, length: sizeLength) = await _readElementSize();
    var realSize = size;

    dynamic data;
    if (size == 0) {
      data = schemaElement.defaultValue;

      data ??= switch (schemaElement.type) {
        // If the EBML Element is not defined to have a default value, then a Signed Integer Element
        // with a zero-octet length represents an integer value of zero.
        ElementType.integer => 0,
        // If the EBML Element is not defined to have a default value, then an Unsigned Integer
        // Element with a zero-octet length represents an integer value of zero.
        ElementType.uinteger => 0,
        // If the EBML Element is not defined to have a default value, then a Float Element with a
        // zero-octet length represents a numerical value of zero.
        ElementType.float => 0.0,
        // If the EBML Element is not defined to have a default value, then a String Element with a
        // zero-octet length represents an empty string.
        ElementType.string => '',
        // If the EBML Element is not defined to have a default value, then a UTF-8 Element with a
        // zero-octet length represents an empty string.
        ElementType.utf8 => '',
        // If the EBML Element is not defined to have a default value, then a Date Element with a
        // zero-octet length represents a timestamp of 2001-01-01T00:00:00.000000000 UTC [RFC3339].
        ElementType.date => DateTime.utc(2001, 01, 01),

        // A zero length master element contains no children.
        ElementType.master => <Element>[],

        // A zero length binary element contains no data.
        ElementType.binary => Uint8List(0),
      };
    } else {
      data = await switch (schemaElement.type) {
        ElementType.integer => _readSignedIntegerElementData(size!),
        ElementType.uinteger => _readUnsignedIntegerElementData(size!),
        ElementType.float => _readFloatElementData(size!),
        ElementType.string => _readStringElementData(size!),
        ElementType.utf8 => _readUtf8ElementData(size!),
        ElementType.date => _readDateElementData(size!),
        ElementType.binary => _readBinaryElementData(size!),
        ElementType.master => () async {
            final (:elements, size: elementsSize, :overRead, :overReadSize) =
                await _readMasterElementData(size, parentLength: parentLength);

            realSize ??= elementsSize;
            _overRead = overRead;
            _overReadSize = overReadSize;

            return elements;
          }(),
      };
    }

    final element = switch (schemaElement.type) {
      ElementType.integer => SignedIntegerElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.uinteger => UnsignedIntegerElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.float => FloatElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.string => StringElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.utf8 => Utf8Element(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.date => DateElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.master => MasterElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
      ElementType.binary => BinaryElement(
          id: id,
          size: size,
          schemaElement: schemaElement,
          data: data,
        ),
    };

    _currentPath = parentPath;

    _updateStreamProperties(element);
    output.add(element);

    return (element: element, size: realSize! + idLength + sizeLength);
  }

  void _updateStreamProperties(Element element) {
    if (element.schemaElement.name == 'EBMLMaxIDLength') {
      _maxIDLength = element.data as int;
    } else if (element.schemaElement.name == 'EBMLMaxSizeLength') {
      _maxSizeLength = element.data as int;
    }
  }

  (ResolvedSchema, Map<Path, Map<int, SchemaElement>>)? _cachedIdMapping;
  Map<Path, Map<int, SchemaElement>> _getIdMapping() {
    if (_cachedIdMapping != null && _cachedIdMapping!.$1 == _currentSchema) {
      return _cachedIdMapping!.$2;
    }

    final elements = [..._currentSchema.elements, voidElement, crc32Element];

    final result = <Path, Map<int, SchemaElement>>{};
    for (final element in elements) {
      final mapping = result[element.path] = {};

      for (final potentialChildElement in elements) {
        if (!potentialChildElement.path.canBeFoundIn(element.path)) {
          continue;
        }

        mapping[potentialChildElement.id] = potentialChildElement;
      }
    }

    result[const Path([])] = {};
    for (final element in elements) {
      if (element.path.isRoot) {
        result[const Path([])]![element.id] = element;
      }
    }

    _cachedIdMapping = (_currentSchema, result);
    return result;
  }

  Future<({int value, int length})> _readVint() async {
    final head = (await _read(1)).single;
    final length = bitsPerByte - head.bitLength + 1;

    // XOR by (1 << (head.bitLength - 1)) sets the VINT_MARKER bit to 0
    // VINT_WIDTH is already all zeroes so we leave it alone
    final leadingByte = head ^ (1 << (head.bitLength - 1));
    final otherBytes = await _read(length - 1);

    int value = leadingByte;
    for (final byte in otherBytes) {
      value <<= bitsPerByte;
      value |= byte;
    }

    return (value: value, length: length);
  }

  Future<({int id, int length})> _readElementId() async {
    final (:value, :length) = await _readVint();

    if (!isLenient) {
      if (length > _maxIDLength) {
        throw FormatException('Element ID length is larger than EBMLMaxIDLength');
      }
      if (value == 0) {
        throw FormatException('Element ID VINT_DATA may not be all zeroes');
      }
      // Calculate number of VINT_DATA bits
      final bitCount = bitsPerByte * (length - 1) + (bitsPerByte - length);
      // Calculate value with all VINT_DATA bits set to 1
      final vIntDataAllOnes = 1 << (bitCount) - 1;
      if (value == vIntDataAllOnes) {
        throw FormatException('Element ID VINT_DATA may not be all ones');
      }

      final minimalBitCount = value.bitLength;
      var minimalLength = minimalBitCount + (7 - (minimalBitCount % 7));
      // If storing value in [minimalBitCount] bits would make all VINT_DATA to one, add one byte
      // to minimal length (one byte = 7 more VINT_DATA bits).
      if (value == (1 << minimalBitCount) - 1) minimalLength += 7;

      if (length > minimalLength) {
        throw FormatException('A shorter element ID encoding is available');
      }
    }

    return (id: value, length: length);
  }

  Future<({int? size, int length})> _readElementSize() async {
    final (:value, :length) = await _readVint();

    if (!isLenient) {
      if (length > _maxSizeLength) {
        throw FormatException('Element Size length is larger than EBMLMaxSizeLength');
      }
    }

    // Calculate number of VINT_DATA bits
    final bitCount = bitsPerByte * (length - 1) + (bitsPerByte - length);
    // Calculate value with all VINT_DATA bits set to 1
    final vIntDataAllOnes = (1 << bitCount) - 1;
    if (value == vIntDataAllOnes) {
      // Unknown element size.
      return (size: null, length: length);
    }

    return (size: value, length: length);
  }

  Future<int> _readSignedIntegerElementData(int length) async {
    final data = await _read(length);
    var value = 0;
    for (final byte in data) {
      value <<= bitsPerByte;
      value |= byte;
    }
    // TODO: Is this correct?
    return value.toSigned(length);
  }

  Future<int> _readUnsignedIntegerElementData(int length) async {
    final data = await _read(length);
    var value = 0;
    for (final byte in data) {
      value <<= bitsPerByte;
      value |= byte;
    }
    return value;
  }

  Future<double> _readFloatElementData(int length) async {
    final data = await _read(length);
    return switch (length) {
      4 => data.buffer.asFloat32List()[0],
      8 => data.buffer.asFloat64List()[0],
      // 0 length is handled in calling function
      _ => throw FormatException('Float element length must be 0, 4, or 8 octets'),
    };
  }

  Future<String> _readStringElementData(int length) async {
    final data = await _read(length);
    return ascii.decode(data);
  }

  Future<String> _readUtf8ElementData(int length) async {
    final data = await _read(length);
    return utf8.decode(data);
  }

  Future<DateTime> _readDateElementData(int length) async {
    if (length != 8) {
      // 0 length is handled in calling function
      throw FormatException('Date element length must be 0 or 8 octets');
    }

    final data = await _readSignedIntegerElementData(length);

    final epoch = DateTime.utc(2001, 01, 01);

    // This is lossy.
    return epoch.add(Duration(microseconds: data ~/ nanosecondsPerMicrosecond));
  }

  Future<
      ({
        List<Element> elements,
        int size,
        Element? overRead,
        int? overReadSize,
      })> _readMasterElementData(
    int? length, {
    int? parentLength,
  }) async {
    if (length == null) {
      final result = <Element>[];
      var resultSize = 0;

      while (true) {
        final (:element, :size) = await _readAndOutputElement(parentLength: parentLength);

        if (element.schemaElement.path.isParentOf(_currentPath) &&
            !element.schemaElement.path.isGlobal) {
          // Any EBML Element that is a valid Parent Element of the Unknown-Sized Element according
          // to the EBML Schema, Global Elements excluded.
          return (elements: result, size: resultSize, overRead: element, overReadSize: size);
        }

        // Any valid EBML Element according to the EBML Schema, Global Elements excluded, that is
        // not a Descendant Element of the Unknown-Sized Element but shares a common direct parent,
        // such as a Top-Level Element.

        if (const ListEquality().equals(
          element.schemaElement.path.parentPath,
          _currentPath.parentPath,
        )) {
          return (elements: result, size: resultSize, overRead: element, overReadSize: size);
        }

        // Any EBML Element that is a valid Root Element according to the EBML Schema, Global Elements excluded.
        if (element.schemaElement.path.isRoot && !element.schemaElement.path.isGlobal) {
          return (elements: result, size: resultSize, overRead: element, overReadSize: size);
        }

        if (parentLength != null) {
          parentLength -= size;

          if (!isLenient) {
            if (parentLength < 0) {
              throw FormatException('Child of master element overran parent master element length');
            }
          }

          // The end of the Parent Element with a known size has been reached.
          if (parentLength <= 0) {
            return (elements: result, size: resultSize, overRead: null, overReadSize: null);
          }
        }

        result.add(element);
        resultSize += size;

        while (_bufferReadIndex == _bufferFillIndex) {
          // The end of the EBML Document, either when reaching the end of the file or because a
          // new EBML Header started.
          try {
            await _nextChunk;
          } on StateError {
            // StateError is thrown when end of input is encountered while awaiting _nextChunk.
            // In that case, we interpret as "no more elements" and return to our parent element.
            return (elements: result, size: resultSize, overRead: null, overReadSize: null);
          }
        }
      }
    } else {
      int remaining = length;
      final result = <Element>[];

      while (remaining > 0) {
        final (:element, :size) = await _readAndOutputElement(parentLength: remaining);
        remaining -= size;
        result.add(element);
      }

      if (!isLenient) {
        if (remaining < 0) {
          throw FormatException('Child of master element overran master element length');
        }
      }

      return (elements: result, size: length, overRead: null, overReadSize: null);
    }
  }

  Future<Uint8List> _readBinaryElementData(int length) async {
    return await _read(length);
  }
}

class EbmlEncoder extends Converter<Element, List<int>> {
  final Schema schema;

  const EbmlEncoder(this.schema);

  @override
  Uint8List convert(Element input) {
    final outputSink = _ValueSink<List<int>>();
    final inputSink = startChunkedConversion(outputSink);

    inputSink.add(input);
    return outputSink.data as Uint8List;
  }

  @override
  Sink<Element> startChunkedConversion(Sink<List<int>> sink) => throw UnimplementedError();
}

class _ValueSink<T> implements Sink<T> {
  T? data;

  @override
  void add(T data) => this.data = data;

  @override
  void close() {}
}
