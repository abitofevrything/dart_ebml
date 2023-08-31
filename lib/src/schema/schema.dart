import 'package:collection/collection.dart';

import 'resolved_schema.dart';

/// An EBML schema.
///
/// A schema contains information about the identifiers used in EBML documents
/// using this schema as well as any information needed to parse the elements
/// in the EBML document.
class Schema {
  /// The official name of the EBML Document Type that is defined by this EBML
  /// Schema.
  final String docType;

  /// The version of the docType documented by this EBML Schema.
  ///
  /// Unlike XML Schemas, an EBML [Schema] documents all versions of a
  /// [docType]'s definition rather than using separate EBML [Schema]s for each
  /// version of a [docType]. EBML [Element]s may be introduced and deprecated
  /// by using the [SchemaElement.minVer] and [SchemaElement.maxVer] attributes.
  final int version;

  /// The version of the EBML Header used by this EBML Schema.
  final int? ebml;

  /// A listing of all the elements contained in this schema.
  final List<SchemaElement> elements;

  /// Create a new [Schema].
  const Schema({
    required this.docType,
    required this.version,
    this.ebml,
    required this.elements,
  });

  /// Resolve this schema into a [ResolvedSchema] by giving attributes their
  /// default values if needed.
  ResolvedSchema resolve() {
    return ResolvedSchema(
      docType: docType,
      version: version,
      // If the attribute is omitted, the EBML Header version is 1.
      ebml: ebml ?? 1,
      elements: UnmodifiableListView([
        for (final element in elements)
          ResolvedSchemaElement(
            name: element.name,
            path: element.path,
            id: element.id,
            // If the "minOccurs" attribute is not present, then that EBML Element
            // has a "minOccurs" value of 0.
            minOccurs: element.minOccurs ?? 0,
            maxOccurs: element.maxOccurs,
            range: element.range,
            length: element.length,
            defaultValue: element.defaultValue,
            type: element.type,
            // If the "unknownsizeallowed" attribute is not used, then that EBML Element is not
            // allowed to use an unknown Element Data Size.
            unknownSizeAllowed: element.unknownSizeAllowed ?? false,
            // If the "recursive" attribute is not present, then the EBML Element MUST NOT be
            // used recursively.
            recursive: element.recursive ?? false,
            // If the "recurring" attribute is not present, then the EBML Element is not an
            // Identically Recurring Element.
            recurring: element.recurring ?? false,
            // If the "minver" attribute is not present, then the EBML Element has a minimum version
            // of "1".
            minVer: element.minVer ?? 1,
            // If the "maxver" attribute is not present, then the EBML Element has a maximum version
            //equal to the value stored in the "version" attribute of "<EBMLSchema>".
            maxVer: element.maxVer ?? version,
          ),
      ]),
    );
  }

  @override
  int get hashCode =>
      Object.hash(docType, version, ebml, const ListEquality().hash(elements));

  @override
  bool operator ==(Object other) =>
      other is Schema &&
      other.docType == docType &&
      other.version == version &&
      other.ebml == ebml &&
      const ListEquality().equals(other.elements, elements);
}

/// The description of an [Element] in a [Schema].
class SchemaElement {
  /// The human-readable name of this EBML Element.
  ///
  /// The value of [name] MUST be in the form of characters "A" to "Z", "a" to
  /// "z", "0" to "9", "-", and ".". The first character of [name] MUST be in
  /// the form of an "A" to "Z", "a" to "z", or "0" to "9" character.
  final String name;

  /// The allowed storage locations of this EBML Element within an EBML
  /// Document.
  final Path path;

  /// The ID of this element in an EBML Document.
  final int id;

  /// The minimum permitted number of occurrences of this EBML Element within
  /// its Parent Element.
  final int? minOccurs;

  /// The maximum permitted number of occurrences of this EBML Element within
  /// its Parent Element.
  final int? maxOccurs;

  /// A restriction on the value of this element.
  final Range? range;

  /// A restriction on the length of this element's data.
  final Range? length;

  /// The default value of this element.
  final dynamic defaultValue;

  /// The type of this element.
  final ElementType type;

  /// Whether this element is allowed to have an unknown size.
  final bool? unknownSizeAllowed;

  /// Whether this element can be found within itself.
  final bool? recursive;

  /// Whether this element can be found multiple times within its parent.
  final bool? recurring;

  /// The version of the EBML Schema this EBML Element was added.
  final int? minVer;

  /// The version of the EBML Schema this EBML Element was removed.
  final int? maxVer;

  /// Whether this is a global element.
  bool get isGlobal => path.isGlobal;

  /// Whether this is a root element.
  bool get isRoot => path.isRoot;

  /// Whether this is a top level element.
  bool get isTopLevel => path.isTopLevel;

  /// Create a new [SchemaElement].
  const SchemaElement({
    required this.name,
    required this.path,
    required this.id,
    this.minOccurs,
    this.maxOccurs,
    this.range,
    this.length,
    this.defaultValue,
    required this.type,
    this.unknownSizeAllowed,
    this.recursive,
    this.recurring,
    this.minVer,
    this.maxVer,
  });

  @override
  int get hashCode => Object.hash(
      name,
      path,
      id,
      minOccurs,
      maxOccurs,
      range,
      length,
      defaultValue,
      type,
      unknownSizeAllowed,
      recursive,
      recurring,
      minVer,
      maxVer);

  @override
  bool operator ==(Object other) =>
      other is SchemaElement &&
      other.name == name &&
      other.path == path &&
      other.id == id &&
      other.minOccurs == minOccurs &&
      other.maxOccurs == maxOccurs &&
      other.range == range &&
      other.length == length &&
      const DeepCollectionEquality().equals(other.defaultValue, defaultValue) &&
      other.type == type &&
      other.unknownSizeAllowed == unknownSizeAllowed &&
      other.recursive == recursive &&
      other.recurring == recurring &&
      other.minVer == minVer &&
      other.maxVer == maxVer;
}

/// The location of a [Element] in an EBML Document.
class Path {
  /// The elements of this path.
  final List<PathElement> elements;

  /// Create a new [Path].
  const Path(this.elements);

  /// The last element of this path.
  PathAtom get ebmlElement => elements.last as PathAtom;

  /// This path's parent path.
  List<PathElement> get parentPath =>
      UnmodifiableListView(elements.sublist(0, elements.length - 1));

  /// Whether this path is a global element's path.
  bool get isGlobal =>
      parentPath.isNotEmpty && parentPath.last is GlobalPlaceholder;

  /// Whether this path is a root element's path.
  bool get isRoot => parentPath.isEmpty;

  /// Whether this path is a top level element's path.
  bool get isTopLevel =>
      parentPath.length == 1 && parentPath.single is PathAtom;

  /// Whether this path is the parent of [other].
  bool isParentOf(Path other) =>
      other.elements.length > elements.length &&
      const ListEquality()
          .equals(other.elements.sublist(0, elements.length), elements);

  /// Whether an element with this path can be found in an element with the path
  /// [other].
  bool canBeFoundIn(Path other) {
    if (other.isParentOf(this)) {
      return true;
    }

    if (!isGlobal) {
      return false;
    }

    if (this == other && ebmlElement.isRecursive) {
      return true;
    }

    // Strip GlobalPlaceholder
    final globalPrefix = elements.sublist(0, parentPath.length - 1);
    final globalPlaceholder = parentPath.last as GlobalPlaceholder;

    if (globalPrefix.isNotEmpty) {
      if (!const ListEquality().equals(
          globalPrefix, other.elements.sublist(0, globalPrefix.length))) {
        return false;
      }
    }

    final otherAfterGlobalPrefix = other.elements.sublist(globalPrefix.length);

    if (globalPlaceholder.minOccurrences case final minOccurrences?) {
      if (otherAfterGlobalPrefix.length < minOccurrences) {
        return false;
      }
    }

    if (globalPlaceholder.maxOccurrences case final maxOccurrences?) {
      if (otherAfterGlobalPrefix.length > maxOccurrences) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => const ListEquality().hash(elements);

  @override
  bool operator ==(Object other) =>
      other is Path && const ListEquality().equals(other.elements, elements);
}

/// An element in a [Path].
sealed class PathElement {
  /// Create a new [PathElement].
  const PathElement();
}

/// An atom in a [Path].
class PathAtom extends PathElement {
  /// Whether this atom is recursive.
  final bool isRecursive;

  /// The name of this atom.
  final String name;

  /// Create a new [PathAtom].
  const PathAtom({required this.name, required this.isRecursive});

  @override
  int get hashCode => Object.hash(isRecursive, name);

  @override
  bool operator ==(Object other) =>
      other is PathAtom &&
      other.isRecursive == isRecursive &&
      other.name == name;
}

/// A GlobalPlaceholder in a [Path].
class GlobalPlaceholder extends PathElement {
  /// The minimum number of atoms that can replace this GlobalPlaceholder.
  final int? minOccurrences;

  /// The maximum number of atoms that can replace this GlobalPlaceholder.
  final int? maxOccurrences;

  /// Create a new [GlobalPlaceholder].
  const GlobalPlaceholder(
      {required this.minOccurrences, required this.maxOccurrences});

  @override
  int get hashCode => Object.hash(minOccurrences, maxOccurrences);

  @override
  bool operator ==(Object other) =>
      other is GlobalPlaceholder &&
      other.minOccurrences == minOccurrences &&
      other.maxOccurrences == maxOccurrences;
}

/// The type of an element in an EBML Schema or Document.
enum ElementType {
  integer,
  uinteger,
  float,
  string,
  date,
  utf8,
  master,
  binary
}

/// A numerical range.
interface class Range {
  /// A number values must match exactly if [negated] is false, or that values
  /// must not be if [negated] is true.
  final num? exactly;

  /// Whether to invert the meaning of [exactly].
  final bool? negated;

  /// A pair of (lower, upper) bounds values must fall between.
  final (num?, num?)? bounds;

  /// Whether the upper and lower bound are inclusive.
  final (bool, bool)? inclusiveBounds;

  /// Create a range where values must match [exactly].
  const Range.exactly(num this.exactly)
      : negated = false,
        bounds = null,
        inclusiveBounds = null;

  /// Create a range where values must not be [exactly].
  const Range.not(num this.exactly)
      : negated = true,
        bounds = null,
        inclusiveBounds = null;

  /// Create a range where values must fall between an upper and a lower bound.
  const Range.between(
    num? lower,
    num? upper, {
    bool isLowerInclusive = false,
    bool isUpperInclusive = false,
  })  : assert(lower != null || upper != null,
            'At least one of lower and upper must be provided'),
        assert(lower == null || upper == null || lower <= upper,
            'Lower must be less than upper'),
        exactly = null,
        negated = null,
        bounds = (lower, upper),
        inclusiveBounds = (isLowerInclusive, isUpperInclusive);

  /// Test a number against this [Range].
  bool test(num value) {
    if (exactly != null) {
      return negated! ^ (exactly == value);
    } else {
      final (lower, upper) = bounds!;
      final (isLowerInclusive, isUpperInclusive) = inclusiveBounds!;

      if (lower != null) {
        if (value < lower) {
          return false;
        } else if (value == lower) {
          return isLowerInclusive;
        }
      }

      if (upper != null) {
        if (value > upper) {
          return false;
        } else if (value == upper) {
          return isUpperInclusive;
        }
      }

      return true;
    }
  }

  @override
  int get hashCode => Object.hash(exactly, negated, bounds, inclusiveBounds);

  @override
  bool operator ==(Object other) =>
      other is Range &&
      other.exactly == exactly &&
      other.negated == negated &&
      other.bounds == bounds &&
      other.inclusiveBounds == inclusiveBounds;
}
