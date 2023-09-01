import 'package:ebml/ebml.dart';
import 'package:test/test.dart';

void main() {
  test('EbmlSchemaEncoder', () {
    final encoder = EbmlSchemaEncoder();

    expect(() => encoder.convert(headerSchema), returnsNormally);
  });
}
