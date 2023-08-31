import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:ebml/src/ebml/partial_conversion.dart';

import '../schema/predefined_schema.dart';
import '../schema/resolved_schema.dart';
import '../schema/schema.dart';
import 'element.dart';

const bitsPerByte = 8;
const vIntMax = 72057594037927934;
const nanosecondsPerMicrosecond = 1000;
final epoch = DateTime.utc(2001, 01, 01);

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
    final sink = EbmlDecoderSink._(null, schema, isLenient: isLenient);
    sink
      ..add(input)
      ..close();
    return sink._startConversion().resolve();
  }

  @override
  EbmlDecoderSink startChunkedConversion(Sink<Element> sink) {
    return EbmlDecoderSink._(
      sink,
      schema,
      isLenient: isLenient,
    ).._startConversion();
  }
}

class EbmlDecoderSink extends ByteConversionSink {
  final Sink<Element>? output;
  final ResolvedSchema schema;
  final bool isLenient;

  EbmlDecoderSink._(this.output, Schema schema, {this.isLenient = false})
      : schema = schema.resolve();

  static const _initialCapacity = 32;

  var _buffer = Uint8List(_initialCapacity);
  var _bufferFillIndex = 0;
  var _bufferReadIndex = 0;
  var _isClosed = false;

  PartialConversion<Element>? _currentConversion;
  bool _didExhaustChunk = false;

  @override
  void add(List<int> chunk) {
    if (_bufferFillIndex + chunk.length > _buffer.length) {
      final oldBuffer = _buffer;
      _buffer = Uint8List(1 << (_bufferFillIndex + chunk.length).bitLength);
      _buffer.setRange(0, _bufferFillIndex, oldBuffer);
    }

    _buffer.setRange(_bufferFillIndex, _bufferFillIndex + chunk.length, chunk);
    _bufferFillIndex += chunk.length;

    if (_currentConversion != null) {
      _didExhaustChunk = false;
      while (!_didExhaustChunk && !_currentConversion!.hasValue) {
        _currentConversion = _currentConversion!();
      }
    }
  }

  @override
  void close() {
    _isClosed = true;
  }

  PartialConversion<Uint8List> _read<R>(int length) {
    // The != check is to cause _read(0) calls to throw if empty and closed
    if (length <= _bufferFillIndex - _bufferReadIndex && _bufferFillIndex != _bufferReadIndex) {
      final data = Uint8List.sublistView(_buffer, _bufferReadIndex, _bufferReadIndex += length);
      return PartialConversion.value(data);
    } else if (_isClosed) {
      throw StateError('Cannot read more data from a closed sink');
    }

    _didExhaustChunk = true;
    return PartialConversion.continueConversion(() => _read(length));
  }

  // Stream properties
  var _maxIDLength = 4;
  var _maxSizeLength = 8;
  Path _currentPath = const Path([]);

  PartialConversion<Element> _startConversion() {
    // Read header
    return _currentConversion = _readAndOutputElement().map((_) {
      // Read body
      return _readAndOutputElement().map((e) {
        output?.close();
        return PartialConversion.value(e.element);
      });
    });
  }

  Element? _overRead;
  int? _overReadSize;

  PartialConversion<({Element element, int size})> _readAndOutputElement({int? parentLength}) {
    if (_overRead != null) {
      final result = (element: _overRead!, size: _overReadSize!);
      _overRead = null;
      _overReadSize = null;
      return PartialConversion.value(result);
    }

    return _readElementId().map((value) {
      final (:id, length: idLength) = value;
      final schemaElement = _idMapping[_currentPath]?[id];

      if (schemaElement == null) {
        throw FormatException('Invalid element id at current location');
      }

      final parentPath = _currentPath;
      _currentPath = schemaElement.path;

      return _readElementSize().map((value) {
        final (:size, length: sizeLength) = value;
        var realSize = size;

        PartialConversion<dynamic> data;
        if (size == 0) {
          if (schemaElement.defaultValue != null) {
            data = PartialConversion.value(schemaElement.defaultValue);
          } else {
            data = PartialConversion.value(switch (schemaElement.type) {
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
            });
          }
        } else {
          data = switch (schemaElement.type) {
            ElementType.integer => _readSignedIntegerElementData(size!),
            ElementType.uinteger => _readUnsignedIntegerElementData(size!),
            ElementType.float => _readFloatElementData(size!),
            ElementType.string => _readStringElementData(size!),
            ElementType.utf8 => _readUtf8ElementData(size!),
            ElementType.date => _readDateElementData(size!),
            ElementType.binary => _readBinaryElementData(size!),
            ElementType.master =>
              _readMasterElementData(size, parentLength: parentLength).map((value) {
                realSize ??= value.size;
                _overRead = value.overRead;
                _overReadSize = value.overReadSize;

                return PartialConversion.value(value.elements);
              })
          };
        }

        return data.map((data) {
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
          output?.add(element);

          return PartialConversion.value(
            (element: element, size: realSize! + idLength + sizeLength),
          );
        });
      });
    });
  }

  void _updateStreamProperties(Element element) {
    if (element.schemaElement.name == 'EBMLMaxIDLength') {
      _maxIDLength = element.data as int;
    } else if (element.schemaElement.name == 'EBMLMaxSizeLength') {
      _maxSizeLength = element.data as int;
    }
  }

  late final Map<Path, Map<int, SchemaElement>> _idMapping = _getIdMapping();

  Map<Path, Map<int, SchemaElement>> _getIdMapping() {
    final elements = [...headerSchema.elements, ...schema.elements, voidElement, crc32Element];

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

    return result;
  }

  PartialConversion<({int value, int length})> _readVint() {
    return _read(1).map((bytes) {
      final head = bytes.single;
      final length = bitsPerByte - head.bitLength + 1;

      // XOR by (1 << (head.bitLength - 1)) sets the VINT_MARKER bit to 0
      // VINT_WIDTH is already all zeroes so we leave it alone
      final leadingByte = head ^ (1 << (head.bitLength - 1));

      return _read(length - 1).map((otherBytes) {
        int value = leadingByte;
        for (final byte in otherBytes) {
          value <<= bitsPerByte;
          value |= byte;
        }

        return PartialConversion.value((value: value, length: length));
      });
    });
  }

  PartialConversion<({int id, int length})> _readElementId() {
    return _readVint().map((vint) {
      final (:value, :length) = vint;

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

      return PartialConversion.value((id: value, length: length));
    });
  }

  PartialConversion<({int? size, int length})> _readElementSize() {
    return _readVint().map((vint) {
      final (:value, :length) = vint;

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
        return PartialConversion.value((size: null, length: length));
      }

      return PartialConversion.value((size: value, length: length));
    });
  }

  PartialConversion<int> _readSignedIntegerElementData(int length) {
    return _read(length).map((data) {
      var value = 0;
      for (final byte in data) {
        value <<= bitsPerByte;
        value |= byte;
      }
      // TODO: Is this correct?
      return PartialConversion.value(value.toSigned(length));
    });
  }

  PartialConversion<int> _readUnsignedIntegerElementData(int length) {
    return _read(length).map((data) {
      var value = 0;
      for (final byte in data) {
        value <<= bitsPerByte;
        value |= byte;
      }
      return PartialConversion.value(value);
    });
  }

  PartialConversion<double> _readFloatElementData(int length) {
    return _read(length).map((data) {
      return PartialConversion.value(switch (length) {
        4 => data.buffer.asFloat32List()[0],
        8 => data.buffer.asFloat64List()[0],
        // 0 length is handled in calling function
        _ => throw FormatException('Float element length must be 0, 4, or 8 octets'),
      });
    });
  }

  PartialConversion<String> _readStringElementData(int length) {
    return _read(length).map((data) => PartialConversion.value(ascii.decode(data)));
  }

  PartialConversion<String> _readUtf8ElementData(int length) {
    return _read(length).map((data) => PartialConversion.value(utf8.decode(data)));
  }

  PartialConversion<DateTime> _readDateElementData(int length) {
    if (length != 8) {
      // 0 length is handled in calling function
      throw FormatException('Date element length must be 0 or 8 octets');
    }

    return _readSignedIntegerElementData(length).map((data) {
      // This is lossy.
      return PartialConversion.value(
        epoch.add(Duration(microseconds: data ~/ nanosecondsPerMicrosecond)),
      );
    });
  }

  PartialConversion<
      ({
        List<Element> elements,
        int size,
        Element? overRead,
        int? overReadSize,
      })> _readMasterElementData(
    int? length, {
    int? parentLength,
  }) {
    if (length == null) {
      return PartialConversion.many<({Element element, int size, bool isDone, bool isOverRead})>(
          doWhile: (value) => !value.isDone, (values) {
        var remainingParentLength = parentLength == null
            ? null
            : parentLength - values.fold<int>(0, (previous, element) => previous + element.size);

        return _readAndOutputElement(parentLength: remainingParentLength).map(
          (value) {
            final (:element, :size) = value;

            if (element.schemaElement.path.isParentOf(_currentPath) &&
                !element.schemaElement.path.isGlobal) {
              // Any EBML Element that is a valid Parent Element of the Unknown-Sized Element according
              // to the EBML Schema, Global Elements excluded.
              // return (elements: result, size: resultSize, overRead: element, overReadSize: size);
              return PartialConversion.value(
                (element: element, size: size, isDone: true, isOverRead: true),
              );
            }

            // Any valid EBML Element according to the EBML Schema, Global Elements excluded, that is
            // not a Descendant Element of the Unknown-Sized Element but shares a common direct parent,
            // such as a Top-Level Element.

            if (const ListEquality().equals(
              element.schemaElement.path.parentPath,
              _currentPath.parentPath,
            )) {
              return PartialConversion.value(
                (element: element, size: size, isDone: true, isOverRead: true),
              );
            }

            // Any EBML Element that is a valid Root Element according to the EBML Schema, Global Elements excluded.
            if (element.schemaElement.path.isRoot && !element.schemaElement.path.isGlobal) {
              return PartialConversion.value(
                (element: element, size: size, isDone: true, isOverRead: true),
              );
            }

            if (remainingParentLength != null) {
              remainingParentLength = remainingParentLength! - size;

              if (!isLenient) {
                if (remainingParentLength! < 0) {
                  throw FormatException(
                      'Child of master element overran parent master element length');
                }
              }

              // The end of the Parent Element with a known size has been reached.
              if (remainingParentLength! <= 0) {
                return PartialConversion.value(
                  (element: element, size: size, isDone: true, isOverRead: false),
                );
              }
            }

            if (_bufferReadIndex == _bufferFillIndex) {
              return _read(0).ifThrows(
                (element: element, size: size, isDone: true, isOverRead: false),
                orElse: (element: element, size: size, isDone: false, isOverRead: false),
              );
            }

            return PartialConversion.value(
              (element: element, size: size, isDone: false, isOverRead: false),
            );
          },
        );
      }).map((results) {
        final elements = <Element>[];
        var size = 0;

        for (final result in results) {
          if (result.isOverRead) {
            return PartialConversion.value(
              (elements: elements, size: size, overRead: result.element, overReadSize: result.size),
            );
          }
        }

        return PartialConversion.value(
          (elements: elements, size: size, overRead: null, overReadSize: null),
        );
      });
    } else {
      return PartialConversion.many<({Element? element, int size})>(
              doWhile: (value) => value.element != null, (values) {
        final remaining =
            length - values.fold<int>(0, (previousValue, element) => previousValue + element.size);

        if (remaining <= 0) {
          if (!isLenient) {
            if (remaining < 0) {
              throw FormatException('Child of master element overran master element length');
            }
          }

          return PartialConversion.value((element: null, size: 0));
        }

        return _readAndOutputElement(parentLength: remaining);
      })
          .map((value) => PartialConversion.value(value.whereType<({Element element, int size})>()))
          .map(
        (values) {
          final elements = <Element>[];
          var size = 0;

          for (final result in values) {
            elements.add(result.element);
            size += result.size;
          }

          return PartialConversion.value(
              (elements: elements, size: size, overRead: null, overReadSize: null));
        },
      );
    }
  }

  PartialConversion<Uint8List> _readBinaryElementData(int length) {
    return _read(length);
  }
}

class EbmlEncoder extends Converter<Element, List<int>> {
  final Schema schema;

  const EbmlEncoder(this.schema);

  @override
  Uint8List convert(Element input) {
    final writer = _EbmlDecoderWriter();

    final headerData = Uint8List(0);
    final bodyData = writer.convertElement(input);

    return Uint8List(headerData.length + bodyData.length)
      ..setRange(0, headerData.length, headerData)
      ..setRange(headerData.length, headerData.length + bodyData.length, bodyData);
  }
}

class _EbmlDecoderWriter {
  Uint8List convertElement(Element element) {
    final elementId = convertVint(element.id, disallowAllOnes: false);
    final elementData = switch (element) {
      SignedIntegerElement(:final data) => convertIntegerData(data),
      UnsignedIntegerElement(:final data) => convertUnsignedIntegerData(data),
      FloatElement(:final data) => convertFloatData(data),
      StringElement(:final data) => convertAsciiData(data),
      Utf8Element(:final data) => convertUtf8Data(data),
      DateElement(:final data) => convertDateData(data),
      BinaryElement(:final data) => data,
      MasterElement(:final data) => () {
          final convertedChildren = data.map(convertElement).toList();
          final length =
              convertedChildren.fold(0, (previousValue, element) => previousValue + element.length);
          final buffer = Uint8List(length);
          var index = 0;
          for (final child in convertedChildren) {
            buffer.setRange(index, index += child.length, child);
          }
          return buffer;
        }(),
    };
    final elementSize = convertVint(elementData.length, disallowAllOnes: true);

    return Uint8List(elementId.length + elementSize.length + elementData.length)
      ..setRange(0, elementId.length, elementId)
      ..setRange(elementId.length, elementId.length + elementSize.length, elementSize)
      ..setRange(
        elementId.length + elementSize.length,
        elementId.length + elementSize.length + elementData.length,
        elementData,
      );
  }

  Uint8List convertIntegerData(int data) {
    final buffer = Uint8List(8)..buffer.asByteData().setInt64(0, data);
    final zeroBytes = buffer.takeWhile((b) => b == 0).length;
    return buffer.sublist(zeroBytes);
  }

  Uint8List convertUnsignedIntegerData(int data) {
    final buffer = Uint8List(8)..buffer.asByteData().setUint64(0, data);
    final zeroBytes = buffer.takeWhile((b) => b == 0).length;
    return buffer.sublist(zeroBytes);
  }

  Uint8List convertFloatData(double data) {
    return Uint8List(8)..buffer.asByteData().setFloat64(0, data);
  }

  Uint8List convertAsciiData(String data) {
    return ascii.encode(data);
  }

  Uint8List convertUtf8Data(String data) {
    return utf8.encode(data);
  }

  Uint8List convertDateData(DateTime data) {
    final timestamp = data.difference(epoch);

    return convertIntegerData(timestamp.inMicroseconds * nanosecondsPerMicrosecond);
  }

  Uint8List convertVint(int value, {required bool disallowAllOnes}) {
    final neededBits = value.bitLength;
    var length = (neededBits / 7).ceil();

    if (disallowAllOnes && value == (1 << neededBits) - 1) {
      // Encoded value would be all 1s.
      length++;
    }

    final result = Uint8List(length)..buffer.asByteData().setInt64(0, value);

    // // Set VINT_MARKER
    result[result.length - 1 - length] |= 1 << (bitsPerByte - length);

    final zeroBytes = result.takeWhile((b) => b == 0).length;
    return result.sublist(zeroBytes);
  }
}
