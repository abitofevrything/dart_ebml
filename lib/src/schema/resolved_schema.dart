import 'package:collection/collection.dart';

import 'schema.dart';

interface class ResolvedSchema implements Schema {
  @override
  final String docType;

  @override
  final int version;

  @override
  final int ebml;

  @override
  final List<ResolvedSchemaElement> elements;

  const ResolvedSchema({
    required this.docType,
    required this.version,
    required this.ebml,
    required this.elements,
  });

  @override
  ResolvedSchema resolve() => this;

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

interface class ResolvedSchemaElement implements SchemaElement {
  @override
  final String name;

  @override
  final Path path;

  @override
  final int id;

  @override
  final int minOccurs;

  @override
  final int? maxOccurs;

  @override
  final Range? range;

  @override
  final Range? length;

  @override
  final dynamic defaultValue;

  @override
  final ElementType type;

  @override
  final bool unknownSizeAllowed;

  @override
  final bool recursive;

  @override
  final bool recurring;

  @override
  final int minVer;

  @override
  final int maxVer;

  const ResolvedSchemaElement({
    required this.name,
    required this.path,
    required this.id,
    required this.minOccurs,
    required this.maxOccurs,
    required this.range,
    required this.length,
    required this.defaultValue,
    required this.type,
    required this.unknownSizeAllowed,
    required this.recursive,
    required this.recurring,
    required this.minVer,
    required this.maxVer,
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
