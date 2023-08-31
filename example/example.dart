import 'package:http/http.dart';
import 'package:xml/xml.dart';

import 'package:ebml/ebml.dart';

// Matroska (.mkv files) is a format defined as an EBML schema
final matroskaSchemaUrl = Uri.parse(
    'https://raw.githubusercontent.com/ietf-wg-cellar/matroska-specification/master/ebml_matroska.xml');
final sampleMatroskaFileUrl = Uri.parse(
    'https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test1.mkv');

void main() async {
  final http = Client();

  final matroskaSchemaContent = (await http.get(matroskaSchemaUrl)).body;
  final matroskaSchema = ebmlSchema.decode(
    XmlDocument.parse(matroskaSchemaContent),
  );

  print('Matroska doctype: ${matroskaSchema.docType}');
  print('Matroska schema element count: ${matroskaSchema.elements.length}');

  // Create an instance of the EBML codec using the schema to decode EBML
  // documents of that schema type.
  final matroska = EbmlCodec(matroskaSchema);

  final streamedSampleContent =
      (await http.send(Request('GET', sampleMatroskaFileUrl))).stream;
  final streamedSample = streamedSampleContent.transform(matroska.decoder);

  await for (final element in streamedSample) {
    // Use switch (element) and an object pattern for better typing on
    // element.data
    switch (element) {
      case BinaryElement(:final name, :final data):
        print('Found binary element $name with ${data.length} bytes of data');
      case MasterElement(:final name, :final data):
        print('Found master element $name with ${data.length} children');
      case _:
        print(
          'Found binary element ${element.name} with data: ${element.data}',
        );
    }
  }
}
