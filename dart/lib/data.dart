/// data - Data types, exact numeric values, and JX interchange format.
library;

// Data type registry and exact decimal values.
export 'src/data/data_type_registry.dart';
export 'src/data/data_type_mapping.dart';
export 'src/data/numeric.dart';

// Numeric value validation.
export 'src/data/numeric_value_validation.dart';

// JX data interchange codec.
export 'src/data/jx_codec.dart';
export 'src/data/jx_encoding.dart';
export 'src/data/jx_schema.dart';
export 'src/data/jx_body.dart';

// Data operations service interface.
export 'src/data/query_service.dart';

// Database context and row structures.
export 'src/data/db_context.dart';
export 'src/data/jx_row.dart';
export 'src/data/record_x.dart';
