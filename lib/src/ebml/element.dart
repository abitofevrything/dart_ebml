import 'dart:typed_data';

import '../schema/schema.dart';

sealed class Element {
  final int id;

  final int? size;

  dynamic get data;

  final SchemaElement schemaElement;

  String get name => schemaElement.name;

  ElementType get type => schemaElement.type;

  const Element(
      {required this.id, required this.size, required this.schemaElement});
}

class SignedIntegerElement extends Element {
  @override
  final int data;

  SignedIntegerElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class UnsignedIntegerElement extends Element {
  @override
  final int data;

  UnsignedIntegerElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class FloatElement extends Element {
  @override
  final double data;

  FloatElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class StringElement extends Element {
  @override
  final String data;

  StringElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class Utf8Element extends Element {
  @override
  final String data;

  Utf8Element({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class DateElement extends Element {
  @override
  final DateTime data;

  DateElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class MasterElement extends Element {
  @override
  final List<Element> data;

  MasterElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}

class BinaryElement extends Element {
  @override
  final Uint8List data;

  BinaryElement({
    required super.id,
    required super.size,
    required super.schemaElement,
    required this.data,
  });
}
