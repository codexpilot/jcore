/// Dart implementation of the JCore jdata layer.
library;

export 'src/jcore_base.dart';

// Existing AIX Group 3 catalog.
export 'src/jdata/j_data_type.dart';
export 'src/jdata/data_type_validation.dart';
export 'src/jdata/data_type_encoding.dart';
export 'src/jdata/data_type_decoding.dart';
export 'src/jdata/data_type_mapping.dart';

// Data type registry and exact decimal values.
export 'src/jdata/data_type_registry.dart';
export 'src/jdata/numeric.dart';

// JSONC data interchange and schema registry.
export 'src/jdata/jsonc.dart';
export 'src/jdata/jconverter.dart';
export 'src/jdata/jbase.dart';
