import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:petitparser/core.dart';
import 'package:xml/xml.dart';

import 'path_grammar.dart';
import 'schema.dart';

const bytesPerInt = 8;
const bitsPerByte = 8;

/// A global constant holding an instance of the [EbmlSchemaCodec].
const ebmlSchema = EbmlSchemaCodec();

/// A [Codec] for parsing EBML Schemas.
class EbmlSchemaCodec extends Codec<Schema, XmlDocument> {
  /// Whether this codec is lenient.
  ///
  /// {@template lenient}
  /// Lenient codecs will allow some malformed documents to be parsed without
  /// errors.
  /// {@endtemplate}
  final bool isLenient;

  /// Create a new [EbmlSchemaCodec].
  const EbmlSchemaCodec({this.isLenient = false});

  @override
  EbmlSchemaEncoder get encoder => const EbmlSchemaEncoder();

  @override
  EbmlSchemaDecoder get decoder => EbmlSchemaDecoder(isLenient: isLenient);
}

/// An encoder for EBML Schemas.
class EbmlSchemaEncoder extends Converter<Schema, XmlDocument> {
  /// Create a new [EbmlSchemaEncoder].
  const EbmlSchemaEncoder();

  @override
  XmlDocument convert(Schema input) => XmlDocument([
        XmlElement(
          XmlName('EBMLSchema'),
          [
            XmlAttribute(XmlName('xmlns'), 'urn:ietf:rfc:8794'),
            XmlAttribute(XmlName('docType'), input.docType),
            XmlAttribute(XmlName('version'), input.version.toString()),
            if (input.ebml != null)
              XmlAttribute(XmlName('ebml'), input.ebml.toString()),
          ],
          [
            for (final element in input.elements)
              XmlElement(
                XmlName('element'),
                [
                  XmlAttribute(XmlName('name'), element.name),
                  XmlAttribute(XmlName('path'), _convertPath(element.path)),
                  XmlAttribute(XmlName('id'),
                      '0x${_convertVint(element.id).toRadixString(16)}'),
                  if (element.minOccurs != null)
                    XmlAttribute(
                        XmlName('minOccurs'), element.minOccurs.toString()),
                  if (element.maxOccurs != null)
                    XmlAttribute(
                        XmlName('maxOccurs'), element.maxOccurs.toString()),
                  if (element.range != null)
                    XmlAttribute(
                        XmlName('range'), _convertRange(element.range!)),
                  if (element.length != null)
                    XmlAttribute(
                        XmlName('length'), _convertRange(element.length!)),
                  if (element.defaultValue != null)
                    XmlAttribute(XmlName('default'),
                        _convertDefault(element.type, element.defaultValue!)),
                  XmlAttribute(
                    XmlName('type'),
                    switch (element.type) {
                      ElementType.utf8 => 'utf-8',
                      _ => element.type.name,
                    },
                  ),
                  if (element.unknownSizeAllowed != null)
                    XmlAttribute(
                      XmlName('unknownsizeallowed'),
                      element.unknownSizeAllowed!.toString(),
                    ),
                  if (element.recursive != null)
                    XmlAttribute(
                        XmlName('recursive'), element.recursive!.toString()),
                  if (element.recurring != null)
                    XmlAttribute(
                        XmlName('recurring'), element.recurring!.toString()),
                  if (element.minVer != null)
                    XmlAttribute(XmlName('minver'), element.minVer!.toString()),
                  if (element.maxVer != null)
                    XmlAttribute(XmlName('maxver'), element.maxVer!.toString()),
                ],
              ),
          ],
        ),
      ]);

  String _convertPath(Path path) =>
      r'\' +
      path.parentPath
          .map(
            (e) => switch (e) {
              PathAtom(:final name, :final isRecursive) =>
                '${isRecursive ? '+' : ''}$name\\',
              GlobalPlaceholder(:final minOccurrences, :final maxOccurrences) =>
                '(${minOccurrences ?? ''}-${maxOccurrences ?? ''}\\)',
            },
          )
          .join() +
      path.ebmlElement.name;

  String _convertRange(Range range) => switch (range) {
        Range(:final exactly?, :final negated!) =>
          '${negated ? 'not ' : ''}$exactly',
        Range(
          bounds: (final lower?, null),
          inclusiveBounds: (final inclusive, _)!
        ) =>
          '>${inclusive ? '=' : ''}$lower',
        Range(
          bounds: (null, final upper!),
          inclusiveBounds: (_, final inclusive)!
        ) =>
          '<${inclusive ? '=' : ''}$upper',
        Range(
          bounds: (final lower!, final upper!),
          inclusiveBounds: ((false, false) || (true, false) || (false, true)) &&
              (final lowerInclusive, final upperInclusive)
        ) =>
          '>${lowerInclusive ? '=' : ':'}$lower,<${upperInclusive ? '=' : ''}$upper',
        Range(
          bounds: (final lower!, final upper!),
          inclusiveBounds: (true, true)
        ) =>
          '$lower-$upper',
        _ => throw StateError('Invalid range'),
      };

  int _convertVint(int value) {
    final neededBits = value.bitLength;
    var length = (neededBits / 7).ceil();

    if (value == (1 << neededBits) - 1) {
      // Encoded value would be all 1s.
      length++;
    }

    int result = 0;
    // Set VINT_MARKER
    result |= 1 << (bitsPerByte - length);
    result |= value >> ((length - 1) * bitsPerByte);

    for (int byteIndex = length - 2; byteIndex >= 0; byteIndex--) {
      result <<= bitsPerByte;
      result |= (value >> byteIndex * bitsPerByte) & 0xff;
    }

    return result;
  }

  String _convertDefault(ElementType type, dynamic default_) => switch (type) {
        ElementType.integer => default_.toString(),
        ElementType.uinteger => default_.toString(),
        ElementType.float => default_.toString(),
        ElementType.string => default_,
        ElementType.utf8 => default_,
        _ => throw FormatException('Unsupported default type $type'),
      };
}

/// A decoder for EBML Schemas.
class EbmlSchemaDecoder extends Converter<XmlDocument, Schema> {
  /// Whether this decoder is lenient.
  ///
  /// {@macro lenient}
  final bool isLenient;

  /// Create a new [EbmlSchemaDecoder].
  const EbmlSchemaDecoder({this.isLenient = false});

  @override
  Schema convert(XmlDocument input) {
    final XmlElement root;
    try {
      root = input.rootElement;
    } on StateError {
      throw FormatException('XML document is empty');
    }

    // When used as an XML Document, the EBML Schema MUST use "<EBMLSchema>"
    // as the top-level element.  The "<EBMLSchema>" element can contain
    // "<element>" subelements.

    if (!isLenient) {
      if (root.name.local != 'EBMLSchema') {
        throw FormatException('Root element is not <EBMLSchema>');
      }
      if (root.childElements
          .any((element) => element.name.local != 'element')) {
        throw FormatException('Child of root is not <element>');
      }
    }

    // The "docType" attribute is REQUIRED within the "<EBMLSchema>"
    // Element.

    final docType = root.getAttribute('docType');
    if (docType == null) {
      throw FormatException(
          'Missing docType attribute on <EBMLSchema> element');
    }

    // The version lists a nonnegative integer that specifies the version of
    // the docType documented by the EBML Schema. [ ... ]

    // The "version" attribute is REQUIRED within the "<EBMLSchema>"
    // Element.

    final version = root.getAttribute('version');
    if (version == null) {
      throw FormatException(
          'Missing version attribute on <EBMLSchema> element');
    }
    final parsedVersion = int.tryParse(version);
    if (parsedVersion == null) {
      throw FormatException('version attribute is not a valid integer');
    }
    if (!isLenient && parsedVersion < 0) {
      throw FormatException('version attribute is a negative integer');
    }

    // The "ebml" attribute is a positive integer that specifies the version
    // of the EBML Header (see Section 11.2.2) used by the EBML Schema.  [ ... ]

    final ebml = root.getAttribute('ebml');
    int? parsedEbml;
    if (ebml != null) {
      parsedEbml = int.tryParse(ebml);

      if (!isLenient) {
        if (parsedEbml == null) {
          throw FormatException('ebml attribute is not a valid integer');
        }
        if (parsedEbml <= 0) {
          throw FormatException('ebml attribute is not a positive integer');
        }
      }
    }

    final schema = Schema(
      docType: docType,
      version: parsedVersion,
      ebml: parsedEbml,
      elements: UnmodifiableListView(
        root.childElements
            .where((element) => element.name.local == 'element')
            .map(_convertElement)
            .toList(growable: false),
      ),
    );

    if (!isLenient) {
      // An EBML Schema MUST declare exactly one EBML Element at Root Level
      // (referred to as the Root Element) that occurs exactly once within an
      // EBML Document.  [ ... ]

      if (schema.elements.where((e) => e.path.elements.length == 1).length !=
          1) {
        throw FormatException('Schema must define exactly one root element');
      }

      // The EBML Schema MUST NOT use the Element ID "0x1A45DFA3", which is
      // reserved for the EBML Header for the purpose of resynchronization.

      if (schema.elements
          .any((element) => element.id == _convertVint(0x1A45DFA3))) {
        throw FormatException('Schema may not use the element ID 0x1A45DFA3');
      }

      // The Element ID of any Element found within an EBML Document MUST only
      // match a single "@path" value of its corresponding EBML Schema, but a
      // separate instance of that Element ID value defined by the EBML Schema
      // MAY occur within a different "@path".  If more than one Element is
      // defined to use the same "@id" value, then the "@path" values of those
      // Elements MUST NOT share the same EBMLParentPath.  Elements MUST NOT
      // be defined to use the same "@id" value if one of their common Parent
      // Elements could be an Unknown-Sized Element.

      // The "@path" value MUST be unique within the EBML Schema.  The "@id"
      // value corresponding to this "@path" MUST NOT be defined for use
      // within another EBML Element with the same EBMLParentPath as this
      // "@path".

      if (schema.elements.map((e) => e.path).toSet().length !=
          schema.elements.length) {
        throw FormatException(
            'path attributes must be unique within the schema');
      }

      final groupedByElementId =
          schema.elements.groupListsBy((element) => element.id);
      for (final elementsSharingId in groupedByElementId.values) {
        if (elementsSharingId.length == 1) continue;

        if (EqualitySet.from(
              const ListEquality(),
              elementsSharingId.map((e) => e.path.parentPath),
            ).length !=
            elementsSharingId.length) {
          throw FormatException(
              'Elements with the same id may not share the same EBMLParentPath');
        }
      }

      for (final element in schema.elements) {
        for (final otherElement in schema.elements.where((e) => e != element)) {
          if (element.id == otherElement.id) {
            final commonParents = schema.elements.where((e) =>
                e != element &&
                e != otherElement &&
                e.path.isParentOf(element.path) &&
                e.path.isParentOf(otherElement.path));

            for (final parent in commonParents) {
              if (parent.unknownSizeAllowed == true) {
                throw FormatException(
                  'Elements cannot shard ids if one of their common parents allows unknown sizes',
                );
              }
            }
          }
        }
      }

      // An EBML Element
      // that is defined with an "unknownsizeallowed" attribute set to 1 MUST
      // also have the "unknownsizeallowed" attribute of its Parent Element
      // set to 1.

      for (final element in schema.elements) {
        if (element.unknownSizeAllowed == true) {
          final parents =
              schema.elements.where((e) => e.path.isParentOf(element.path));

          for (final parent in parents) {
            if (parent.unknownSizeAllowed != true) {
              throw FormatException(
                'Elements with unknownsizeallowed set to true must have parents with'
                ' unknownsizeallowed set to true',
              );
            }
          }
        }
      }
    }

    return schema;
  }

  static final RegExp _namePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.-]*$');

  SchemaElement _convertElement(XmlElement input) {
    // The name provides the human-readable name of the EBML Element.  The
    // value of the name MUST be in the form of characters "A" to "Z", "a"
    // to "z", "0" to "9", "-", and ".".  The first character of the name
    // MUST be in the form of an "A" to "Z", "a" to "z", or "0" to "9"
    // character.

    // The "name" attribute is REQUIRED.

    final name = input.getAttribute('name');
    if (name == null) {
      throw FormatException('Missing name attribute on <element> element');
    }
    if (!isLenient && !_namePattern.hasMatch(name)) {
      throw FormatException('Invalid name attribute');
    }

    // The "path" attribute is REQUIRED.

    // [ ... ]

    // The EBMLAtomName of the EBMLElement part MUST be equal to the "@name"
    // attribute of the EBML Schema.  [ ... ]

    // [ ... ]

    // PathMaxOccurrence MUST NOT have the value 0, as it would mean no
    // EBMLPathAtom can replace the GlobalPlaceholder, and the EBMLFullPath
    // would be the same without that GlobalPlaceholder part.
    // PathMaxOccurrence MUST be bigger than, or equal to,
    // PathMinOccurrence.

    // [ ... ]

    final path = input.getAttribute('path');
    if (path == null) {
      throw FormatException('Missing path attribute on <element> element');
    }
    final pathParseResult = const PathGrammar().build<Path>().parse(path);
    if (pathParseResult is! Success) {
      throw FormatException(
          'Invalid path attribute: ${pathParseResult.message}');
    }
    final parsedPath = pathParseResult.value;
    if (!isLenient) {
      if (parsedPath.ebmlElement.name != name) {
        throw FormatException(
          'The EBMLAtomName of the EBMLElement part must be equal to the name attribute',
        );
      }
      for (final globalPlaceholder
          in parsedPath.elements.whereType<GlobalPlaceholder>()) {
        if (globalPlaceholder.maxOccurrences == 0) {
          throw FormatException(
              'GlobalPlaceholder PathMaxOccurrence must not be 0');
        }
        if (globalPlaceholder
            case GlobalPlaceholder(
              :final minOccurrences?,
              :final maxOccurrences?
            ) when maxOccurrences < minOccurrences) {
          throw FormatException(
            'GlobalPlaceholder PathMaxOccurrence must not be less than PathMinOccurrence',
          );
        }
      }
    }

    // The Element ID is encoded as a Variable-Size Integer.  It is read and
    // stored in big-endian order.  In the EBML Schema, it is expressed in
    // hexadecimal notation prefixed by a 0x.  [ ... ]

    // The "id" attribute is REQUIRED.

    final id = input.getAttribute('id');
    if (id == null) {
      throw FormatException('Missing id attribute on <element> element');
    }
    if (!id.startsWith('0x')) {
      throw FormatException('id attribute is not a valid hexadecimal literal');
    }
    final rawId = int.tryParse(id.substring(2), radix: 16);
    if (rawId == null) {
      throw FormatException('id attribute is not a valid hexadecimal literal');
    }
    final parsedId = _convertVint(rawId);

    // "minOccurs" is a nonnegative integer expressing the minimum permitted
    // number of occurrences of this EBML Element within its Parent Element.

    // [ ... ]

    // The "minOccurs" attribute is OPTIONAL.  [ ... ]

    final minOccurs = input.getAttribute('minOccurs');
    int? parsedMinOccurs;
    if (minOccurs != null) {
      parsedMinOccurs = int.tryParse(minOccurs);
      if (!isLenient) {
        if (parsedMinOccurs == null) {
          throw FormatException('minOccurs attribute is not a valid integer');
        }
        if (parsedMinOccurs < 0) {
          throw FormatException('minOccurs attribute is a negative integer');
        }
      }
    }

    //  "maxOccurs" is a nonnegative integer expressing the maximum permitted
    // number of occurrences of this EBML Element within its Parent Element.

    // [ ... ]

    // The "maxOccurs" attribute is OPTIONAL.  [ ... ]

    final maxOccurs = input.getAttribute('maxOccurs');
    int? parsedMaxOccurs;
    if (maxOccurs != null) {
      parsedMaxOccurs = int.tryParse(maxOccurs);
      if (!isLenient) {
        if (parsedMaxOccurs == null) {
          throw FormatException('maxOccurs attribute is not a valid integer');
        }
        if (parsedMaxOccurs < 0) {
          throw FormatException('maxOccurs attribute is a negative integer');
        }
      }
    }

    // The type MUST be set to one of the following values: "integer"
    // (signed integer), "uinteger" (unsigned integer), "float", "string",
    // "date", "utf-8", "master", or "binary".  [ ... ]

    // The "type" attribute is REQUIRED.

    final type = input.getAttribute('type');
    if (type == null) {
      throw FormatException('Missing type attribute on <element> element');
    }
    final parsedType = switch (type) {
      'integer' => ElementType.integer,
      'uinteger' => ElementType.uinteger,
      'float' => ElementType.float,
      'string' => ElementType.string,
      'date' => ElementType.date,
      'utf-8' => ElementType.utf8,
      'master' => ElementType.master,
      'binary' => ElementType.binary,
      _ => throw FormatException('Unknown element type $type'),
    };

    // A numerical range for EBML Elements that are of numerical types
    // (Unsigned Integer, Signed Integer, Float, and Date).  If specified,
    // the value of the EBML Element MUST be within the defined range.  [ ... ]

    // The "range" attribute is OPTIONAL.  If the "range" attribute is not
    // present, then any value legal for the "type" attribute is valid.

    final range = input.getAttribute('range');
    Range? parsedRange;
    if (range != null) {
      parsedRange = _convertRange(range);
      if (!isLenient &&
          parsedType != ElementType.uinteger &&
          parsedType != ElementType.integer &&
          parsedType != ElementType.float &&
          parsedType != ElementType.date) {
        throw FormatException('range may not be set on non numerical elements');
      }
    }

    // The "length" attribute is a value to express the valid length of the
    // Element Data as written, measured in octets.  [ ... ]
    // This length MUST be expressed as
    // either a nonnegative integer or a range (see Section 11.1.6.6.1) that
    // consists of only nonnegative integers and valid operators.

    // The "length" attribute is OPTIONAL.  If the "length" attribute is not
    // present for that EBML Element, then that EBML Element is only limited
    // in length by the definition of the associated EBML Element Type.

    final length = input.getAttribute('length');
    Range? parsedLength;
    if (length != null) {
      parsedLength = _convertRange(length);
      if (!isLenient) {
        if (parsedLength.exactly case num exactly) {
          if (exactly is! int) {
            throw FormatException('length must be integer');
          }
          if (exactly < 0) {
            throw FormatException('length is a negative integer');
          }
        } else if (parsedLength.bounds case (num? lower, num? upper)) {
          if (lower != null && lower is! int) {
            throw FormatException('length lower bound must be an integer');
          }
          if (lower != null && lower < 0) {
            throw FormatException('length lower bound is a negative integer');
          }
          if (upper != null && upper is! int) {
            throw FormatException('length upper bound must be an integer');
          }
          // upper must be > lower, and we already checked lower >= 0
        }
      }
    }

    // [ ... ] EBML
    // Elements that are Master Elements MUST NOT declare a default value.
    // EBML Elements with a "minOccurs" value greater than 1 MUST NOT
    // declare a default value.

    // The default attribute is OPTIONAL.

    final default_ = input.getAttribute('default');
    dynamic parsedDefault;
    if (default_ != null) {
      parsedDefault = switch (parsedType) {
        ElementType.integer => int.tryParse(default_),
        ElementType.uinteger => int.tryParse(default_),
        ElementType.string => default_,
        ElementType.utf8 => default_,
        ElementType.float => _convertFloatLiteral(default_),
        _ => null, // Unsupported type
      };

      if (!isLenient) {
        if (parsedType == ElementType.master) {
          throw FormatException(
              'master elements cannot declare a default value');
        }
        if (parsedMinOccurs != null && parsedMinOccurs > 1) {
          throw FormatException(
            'elements that declare minOccurs to be greater than 1 cannot declare a default value',
          );
        }
        if (parsedDefault == null) {
          throw FormatException('Unable to parse default value');
        }
      }
    }

    // This attribute is a boolean to express whether an EBML Element is
    // permitted to be an Unknown-Sized Element (having all VINT_DATA bits
    // of Element Data Size set to 1).  EBML Elements that are not Master
    // Elements MUST NOT set "unknownsizeallowed" to true.  [ ... ]

    // An EBML Element with the "unknownsizeallowed" attribute set to 1 MUST
    // NOT have its "recursive" attribute set to 1.
    // (checked below)

    // The "unknownsizeallowed" attribute is OPTIONAL.  [ ... ]

    final unknownSizeAllowed = input.getAttribute('unknownsizeallowed');
    bool? parsedUnknownSizeAllowed;
    if (unknownSizeAllowed != null) {
      if (!const ['true', 'false', '1', '0'].contains(unknownSizeAllowed)) {
        if (!isLenient) {
          throw FormatException(
              'unknownsizeallowed attribute is not a valid boolean');
        }
      } else {
        parsedUnknownSizeAllowed =
            const ['true', '1'].contains(unknownSizeAllowed);
        if (!isLenient && parsedType != ElementType.master) {
          throw FormatException(
            'elements that are not master elements may not set unknownsizeallowed to true',
          );
        }
      }
    }

    // [ ... ]  EBML Elements that are not Master
    // Elements MUST NOT set recursive to true.

    // An EBML Element with the "recursive" attribute set to 1 MUST NOT have
    // its "unknownsizeallowed" attribute set to 1.

    // The "recursive" attribute is OPTIONAL.  [ ... ]

    // If the EBMLElement part of the "@path" contains an IsRecursive part,
    // then the "recursive" value MUST be true; otherwise, it MUST be false.

    final recursive = input.getAttribute('recursive');
    bool? parsedRecursive;
    if (recursive != null) {
      if (!const ['true', 'false', '1', '0'].contains(recursive)) {
        if (!isLenient) {
          throw FormatException('recursive attribute is not a valid boolean');
        }
      } else {
        parsedRecursive = const ['true', '1'].contains(recursive);
        if (!isLenient) {
          if (parsedType != ElementType.master) {
            throw FormatException(
              'elements that are not master elements may not set recursive to true',
            );
          }
          if (parsedUnknownSizeAllowed == true && parsedRecursive == true) {
            throw FormatException(
                'unknownsizeallowed and recursive may not be both set to true');
          }
        }
      }
    }

    if (!isLenient) {
      if (parsedPath.ebmlElement.isRecursive && parsedRecursive != true) {
        throw FormatException(
          'recursive must be set to true if the EBMLElement part of the path contains an IsRecursive'
          ' part',
        );
      }
      if (!parsedPath.ebmlElement.isRecursive && parsedRecursive == true) {
        throw FormatException(
          'recursive may not be set to true if the EBMLElement part of the path does not contain an'
          ' IsRecursive part',
        );
      }
    }

    // The "recurring" attribute is OPTIONAL.  [ ... ]

    final recurring = input.getAttribute('recurring');
    bool? parsedRecurring;
    if (recurring != null) {
      if (!const ['true', 'false', '1', '0'].contains(recurring)) {
        if (!isLenient) {
          throw FormatException('recurring attribute is not a valid boolean');
        }
      } else {
        parsedRecurring = const ['true', '1'].contains(recurring);
      }
    }

    // The "minver" (minimum version) attribute stores a nonnegative integer
    // that represents the first version of the docType to support the EBML
    // Element.

    // The "minver" attribute is OPTIONAL.  [ ... ]

    final minver = input.getAttribute('minver');
    int? parsedMinver;
    if (minver != null) {
      parsedMinver = int.tryParse(minver);
      if (!isLenient) {
        if (parsedMinver == null) {
          throw FormatException('minver attribute is not a valid integer');
        }
        if (parsedMinver < 0) {
          throw FormatException('minver attribute is a negative integer');
        }
      }
    }

    // The "maxver" (maximum version) attribute stores a nonnegative integer
    // that represents the last or most recent version of the docType to
    // support the element. "maxver" MUST be greater than or equal to
    // "minver".

    // The "maxver" attribute is OPTIONAL.  [ ... ]

    final maxver = input.getAttribute('maxver');
    int? parsedMaxver;
    if (maxver != null) {
      parsedMaxver = int.tryParse(maxver);
      if (!isLenient) {
        if (parsedMaxver == null) {
          throw FormatException('maxver attribute is not a valid integer');
        }
        if (parsedMaxver < 0) {
          throw FormatException('maxver attribute is a negative integer');
        }
        if (parsedMinver != null && parsedMaxver < parsedMinver) {
          throw FormatException('maxver may not be less than minver');
        }
      }
    }

    return SchemaElement(
      name: name,
      path: parsedPath,
      id: parsedId,
      minOccurs: parsedMinOccurs,
      maxOccurs: parsedMaxOccurs,
      range: parsedRange,
      length: parsedLength,
      defaultValue: parsedDefault,
      type: parsedType,
      unknownSizeAllowed: parsedUnknownSizeAllowed,
      recursive: parsedRecursive,
      recurring: parsedRecurring,
      minVer: parsedMinver,
      maxVer: parsedMaxver,
    );
  }

  // All the characters that can occur in an integer or float literal
  static final _likeNumber =
      r'[+-]?(?:0[xX])?(?:[\da-fA-F]+)(?:\.?[\da-fA-F]*(?:[eEpP][+-]?[\da-fA-F]+)?[fFlL]?)?';

  static final _exactlyPattern = RegExp('^($_likeNumber)\$');
  static final _notPattern = RegExp('^not +($_likeNumber)\$');
  static final _oneRestrictionPattern =
      RegExp('^(<|<=|>=|>) *($_likeNumber)\$');
  static final _twoRestrictionPattern =
      RegExp('^(>|>=) *($_likeNumber) *, *(<|<=) *($_likeNumber)\$');
  static final _rangePattern = RegExp('^($_likeNumber)-($_likeNumber)\$');

  Range _convertRange(String input) {
    final exactlyMatch = _exactlyPattern.firstMatch(input);
    if (exactlyMatch != null) {
      final literal = exactlyMatch.group(1)!;

      return Range.exactly(
        int.tryParse(literal) ?? _convertFloatLiteral(literal),
      );
    }

    final notMatch = _notPattern.firstMatch(input);
    if (notMatch != null) {
      final literal = notMatch.group(1)!;

      return Range.not(int.tryParse(literal) ?? _convertFloatLiteral(literal));
    }

    final oneRestrictionMatch = _oneRestrictionPattern.firstMatch(input);
    if (oneRestrictionMatch != null) {
      final literal = oneRestrictionMatch.group(2)!;
      final limit = int.tryParse(literal) ?? _convertFloatLiteral(literal);
      final restriction = oneRestrictionMatch.group(1)!;

      return switch (restriction) {
        '>' ||
        '>=' =>
          Range.between(limit, null, isLowerInclusive: restriction == '>='),
        '<' ||
        '<=' =>
          Range.between(null, limit, isUpperInclusive: restriction == '<='),
        _ => throw StateError('Unreachable state'),
      };
    }

    final twoRestrictionMatch = _twoRestrictionPattern.firstMatch(input);
    if (twoRestrictionMatch != null) {
      final lowerLiteral = twoRestrictionMatch.group(2)!;
      final lower =
          int.tryParse(lowerLiteral) ?? _convertFloatLiteral(lowerLiteral);
      final upperLiteral = twoRestrictionMatch.group(4)!;
      final upper =
          int.tryParse(upperLiteral) ?? _convertFloatLiteral(upperLiteral);

      if (upper < lower) {
        throw FormatException(
            'Range lower bound must be less than range upper bound');
      }

      return Range.between(
        lower,
        upper,
        isLowerInclusive: twoRestrictionMatch.group(1) == '<=',
        isUpperInclusive: twoRestrictionMatch.group(3) == '>=',
      );
    }

    final rangeMatch = _rangePattern.firstMatch(input);
    if (rangeMatch != null) {
      final lowerLiteral = rangeMatch.group(1)!;
      final lower =
          int.tryParse(lowerLiteral) ?? _convertFloatLiteral(lowerLiteral);
      final upperLiteral = rangeMatch.group(2)!;
      final upper =
          int.tryParse(upperLiteral) ?? _convertFloatLiteral(upperLiteral);

      if (upper < lower) {
        throw FormatException(
            'Range lower bound must be less than range upper bound');
      }

      return Range.between(
        lower,
        upper,
        isLowerInclusive: true,
        isUpperInclusive: true,
      );
    }

    throw FormatException('Invalid range syntax');
  }

  int _convertVint(int input) {
    final bytes = Uint8List(bytesPerInt)
      ..buffer.asByteData().setUint64(0, input);
    final zeroByteCount = bytes.takeWhile((value) => value == 0).length;

    final head = bytes[zeroByteCount];
    final length = bitsPerByte - head.bitLength + 1;

    final leadingByte = head ^ (1 << (head.bitLength - 1));

    int value = leadingByte;
    for (final byte in bytes.skip(zeroByteCount + 1).take(length - 1)) {
      value <<= bitsPerByte;
      value |= byte;
    }

    return value;
  }

  static final _decimalNoFraction =
      RegExp(r'^([+-]?)(\d+)[Ee]([\+\-]?\d+)[fFlL]?$');
  static final _decimalWithFraction =
      RegExp(r'^([+-]?)(\d*)\.(\d+)(?:[Ee]([\+\-]?\d+))?[fFlL]?$');
  static final _decimalWithPoint =
      RegExp(r'^([+-]?)(\d+).(?:[Ee]([\+\-]?\d+))?[fFlL]?$');
  static final _hexNoFraction =
      RegExp(r'^([+-]?)0[xX]([0-9a-fA-F]+)\.?[Pp]([\+\-]?[0-9]+)[fFlL]?$');
  static final _hexWithFraction = RegExp(
      r'^([+-]?)0[xX]([0-9a-fA-F]*)\.([a-fA-F0-9]+)[Pp]([\+\-]?[0-9]+)[fFlL]?$');

  double _convertFloatLiteral(String input) {
    // Adapted from code provided by https://github.com/pingbird
    var isHex = false;
    var num = '0';
    var fraction = '0';
    var exponent = '0';
    String? sign;

    Match? match;
    if ((match = _decimalNoFraction.firstMatch(input)) != null) {
      sign = match!.group(1);
      num = match.group(2)!;
      exponent = match.group(3)!;
    } else if ((match = _decimalWithFraction.firstMatch(input)) != null) {
      sign = match!.group(1);
      final maybeNum = match.group(2);
      if (maybeNum?.isNotEmpty == true) num = maybeNum!;
      fraction = match.group(3)!;
      final maybeExponent = match.group(4);
      if (maybeExponent?.isNotEmpty == true) exponent = maybeExponent!;
    } else if ((match = _decimalWithPoint.firstMatch(input)) != null) {
      sign = match!.group(1);
      num = match.group(2)!;
      final maybeExponent = match.group(3);
      if (maybeExponent?.isNotEmpty == true) exponent = maybeExponent!;
    } else if ((match = _hexNoFraction.firstMatch(input)) != null) {
      isHex = true;
      sign = match!.group(1);
      num = match.group(2)!;
      exponent = match.group(3)!;
    } else if ((match = _hexWithFraction.firstMatch(input)) != null) {
      isHex = true;
      sign = match!.group(1);
      final maybeNum = match.group(2);
      if (maybeNum?.isNotEmpty == true) num = maybeNum!;
      fraction = match.group(3)!;
      exponent = match.group(4)!;
    } else {
      throw FormatException('Invalid float literal $input');
    }

    final base = isHex ? 16 : 10;

    final parsedNum = int.parse(num, radix: base);
    final parsedFraction =
        int.parse(fraction, radix: base) / math.pow(base, fraction.length);
    final parsedExponent = int.parse(exponent);

    final result =
        (parsedNum + parsedFraction) * math.pow(isHex ? 2 : 10, parsedExponent);

    if (sign == '-') {
      return -result;
    }

    return result;
  }
}
