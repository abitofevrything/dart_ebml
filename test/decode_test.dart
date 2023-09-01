import 'package:test/test.dart';
import 'package:http/http.dart';
import 'package:xml/xml.dart';

import 'package:ebml/ebml.dart';

void main() async {
// Matroska (.mkv files) is a format defined as an EBML schema
  final matroskaSchemaUrl = Uri.parse(
      'https://raw.githubusercontent.com/ietf-wg-cellar/matroska-specification/master/ebml_matroska.xml');
  final sampleMatroskaFileUrl = Uri.parse(
      'https://github.com/ietf-wg-cellar/matroska-test-files/raw/master/test_files/test1.mkv');

  final http = Client();

  final matroskaSchemaContent = (await http.get(matroskaSchemaUrl)).body;
  final matroskaSchema = ebmlSchema.decode(
    XmlDocument.parse(matroskaSchemaContent),
  );

  final matroska = EbmlCodec(matroskaSchema);

  final data = (await http.get(sampleMatroskaFileUrl)).bodyBytes;
  final streamed = Stream.fromIterable(data);

  test('EbmlDecoder.convert', () async {
    expect(() => matroska.decode(data), returnsNormally);
  });

  test('EbmlDecoder.startChunkedConversion', () async {
    expect(streamed.map((byte) => [byte]).transform(matroska.decoder).last,
        completes);
  });
}
