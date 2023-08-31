import 'dart:typed_data';

import '../schema/resolved_schema.dart';
import '../schema/schema.dart';

/// An element in an EBML Document.
sealed class Element {
  /// The ID of this element.
  final int id;

  /// The size of this element in bytes, if it was specified.
  final int? size;

  /// The data this element carries.
  dynamic get data;

  /// The element from the EBML Document's [Schema].
  final ResolvedSchemaElement schemaElement;

  /// The name of this element.
  String get name => schemaElement.name;

  /// The type of this element.
  ElementType get type => schemaElement.type;

  /// Create a new [Element].
  const Element({
    required this.id,
    required this.size,
    required this.schemaElement,
  });
}

/// An [Element] that carries a signed integer.
class SignedIntegerElement extends Element {
  @override
  final int data;

  /// Create a new [SignedIntegerElement].
  const SignedIntegerElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries an unsigned integer.
class UnsignedIntegerElement extends Element {
  @override
  final int data;

  /// Create a new [UnsignedIntegerElement].
  const UnsignedIntegerElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries a float.
class FloatElement extends Element {
  @override
  final double data;

  /// Create a new [FloatElement].
  const FloatElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries an ascii-encoded string.
class StringElement extends Element {
  @override
  final String data;

  /// Create a new [StringElement].
  const StringElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries a utf8-encoded string.
class Utf8Element extends Element {
  @override
  final String data;

  /// Create a new [Utf8Element].
  const Utf8Element({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries a date.
class DateElement extends Element {
  @override
  final DateTime data;

  /// Create a new [DateElement].
  const DateElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries a multiple child elements.
class MasterElement extends Element {
  @override
  final List<Element> data;

  /// Create a new [MasterElement].
  const MasterElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

/// An [Element] that carries binary data.
class BinaryElement extends Element {
  @override
  final Uint8List data;

  /// Create a new [BinaryElement].
  const BinaryElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}
