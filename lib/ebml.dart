/// Support for parsing [RFC 8794](https://datatracker.ietf.org/doc/html/rfc8794)
/// EBML documents.
library ebml;

export 'src/schema/schema_codec.dart';
export 'src/schema/path_grammar.dart';
export 'src/schema/predefined_schema.dart';
export 'src/schema/resolved_schema.dart';
export 'src/schema/schema.dart';

export 'src/ebml/codec.dart'
    hide bitsPerByte, nanosecondsPerMicrosecond, vIntMax, epoch;
export 'src/ebml/element.dart';
