import 'package:collection/collection.dart';

import 'resolved_schema.dart';

class Schema {
  final String docType;

  final int version;

  final int? ebml;

  final List<SchemaElement> elements;

  const Schema({
    required this.docType,
    required this.version,
    this.ebml,
    required this.elements,
  });

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
  int get hashCode => Object.hash(docType, version, ebml, const ListEquality().hash(elements));

  @override
  bool operator ==(Object other) =>
      other is Schema &&
      other.docType == docType &&
      other.version == version &&
      other.ebml == ebml &&
      const ListEquality().equals(other.elements, elements);
}

class SchemaElement {
  final String name;

  final Path path;

  final int id;

  final int? minOccurs;

  final int? maxOccurs;

  final Range? range;

  final Range? length;

  final dynamic defaultValue;

  final ElementType type;

  final bool? unknownSizeAllowed;

  final bool? recursive;

  final bool? recurring;

  final int? minVer;

  final int? maxVer;

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
  int get hashCode => Object.hash(name, path, id, minOccurs, maxOccurs, range, length, defaultValue,
      type, unknownSizeAllowed, recursive, recurring, minVer, maxVer);

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

class Path {
  final List<PathElement> elements;

  const Path(this.elements);

  PathAtom get ebmlElement => elements.last as PathAtom;

  List<PathElement> get parentPath =>
      UnmodifiableListView(elements.sublist(0, elements.length - 1));

  bool get isGlobal => parentPath.isNotEmpty && parentPath.last is GlobalPlaceholder;

  bool get isRoot => parentPath.isEmpty;

  bool get isTopLevel => parentPath.length == 1 && parentPath.single is PathAtom;

  @override
  int get hashCode => const ListEquality().hash(elements);

  // bool test(List<String> parts) {
  //   bool tryTest(List<PathElement> elements, List<String> parts, {bool hasRecursed = false}) {
  //     if (parts.isEmpty || elements.isEmpty) {
  //       return false;
  //     }

  //     final currentElement = elements.first;
  //     final currentPart = parts.first;

  //     return switch (currentElement) {
  //       PathAtom(:final name, isRecursive: true) =>
  //         // Either we continue to match the current element
  //         (name == currentPart && tryTest(elements, parts.sublist(1), hasRecursed: true)) ||
  //             // Or we have matched it once (hasRecursed) and we match the rest of the path
  //             (hasRecursed && tryTest(elements.sublist(1), parts.sublist(1))),
  //       PathAtom(:final name, isRecursive: false) =>
  //         name == currentPart && tryTest(elements.sublist(1), parts.sublist(1)),
  //       GlobalPlaceholder(:final minOccurrences, :final maxOccurrences) => () {
  //           for (int repeats = minOccurrences ?? 0;
  //               repeats <= (maxOccurrences ?? (parts.length - 1));
  //               repeats++) {
  //             if (tryTest(elements.sublist(1), parts.sublist(repeats))) {
  //               return true;
  //             }
  //           }

  //           return false;
  //         }(),
  //     };
  //   }

  //   return tryTest(elements, parts);
  // }

  bool isParentOf(Path other) =>
      other.elements.length > elements.length &&
      const ListEquality().equals(other.elements.sublist(0, elements.length), elements);

  bool canBeFoundIn(Path other) {
    if (other.isParentOf(this)) {
      return true;
    }

    if (!isGlobal) {
      return false;
    }

    // Strip GlobalPlaceholder
    final globalPrefix = elements.sublist(0, parentPath.length - 1);
    final globalPlaceholder = parentPath.last as GlobalPlaceholder;

    if (globalPrefix.isNotEmpty) {
      if (!const ListEquality()
          .equals(globalPrefix, other.elements.sublist(0, globalPrefix.length))) {
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
  bool operator ==(Object other) =>
      other is Path && const ListEquality().equals(other.elements, elements);
}

sealed class PathElement {
  const PathElement();
}

class PathAtom extends PathElement {
  final bool isRecursive;

  final String name;

  const PathAtom({required this.name, required this.isRecursive});

  @override
  int get hashCode => Object.hash(isRecursive, name);

  @override
  bool operator ==(Object other) =>
      other is PathAtom && other.isRecursive == isRecursive && other.name == name;
}

class GlobalPlaceholder extends PathElement {
  final int? minOccurrences;

  final int? maxOccurrences;

  const GlobalPlaceholder({required this.minOccurrences, required this.maxOccurrences});

  @override
  int get hashCode => Object.hash(minOccurrences, maxOccurrences);

  @override
  bool operator ==(Object other) =>
      other is GlobalPlaceholder &&
      other.minOccurrences == minOccurrences &&
      other.maxOccurrences == maxOccurrences;
}

enum ElementType { integer, uinteger, float, string, date, utf8, master, binary }

class Range {
  final num? exactly;

  final bool? negated;

  final (num?, num?)? bounds;

  final (bool, bool)? inclusiveBounds;

  const Range.exactly(num this.exactly)
      : negated = false,
        bounds = null,
        inclusiveBounds = null;

  const Range.not(num this.exactly)
      : negated = true,
        bounds = null,
        inclusiveBounds = null;

  const Range.between(
    num? lower,
    num? upper, {
    bool isLowerInclusive = false,
    bool isUpperInclusive = false,
  })  : assert(lower != null || upper != null, 'At least one of lower and upper must be provided'),
        assert(lower == null || upper == null || lower <= upper, 'Lower must be less than upper'),
        exactly = null,
        negated = null,
        bounds = (lower, upper),
        inclusiveBounds = (isLowerInclusive, isUpperInclusive);

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
