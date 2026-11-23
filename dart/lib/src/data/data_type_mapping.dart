import 'data_type_registry.dart';

/// Data type to PostgreSQL type mapping functions

/// Get PostgreSQL type declaration for a catalog ID
///
/// Returns PostgreSQL DDL type string:
/// - Base types: direct mapping (2 → 'integer')
/// - NUMERIC with precision: 'numeric(p,s)'
/// - TEXT with length: 'varchar(len)'
/// - Invalid types: null
///
/// Examples:
/// ```dart
/// getPostgresType(2) // 'integer'
/// getPostgresType(20000) // 'numeric'
/// getPostgresType(21002) // 'numeric(10,2)'
/// getPostgresType(10100) // 'varchar(100)'
/// getPostgresType(999999) // null - invalid
/// ```
String? getPostgresType(int typeId) {
  return DataTypeRegistry.postgresType(typeId);
}

/// Parse PostgreSQL type name to catalog ID
///
/// Supports base type names only (no parameterized types):
/// - 'integer' → 2
/// - 'bigint' → 3
/// - 'boolean' → 0
/// - 'numeric' → 20000 (unlimited)
/// - 'text' → 10000 (unlimited)
/// - 'jsonb' → 7
///
/// Returns null for:
/// - Parameterized types ('numeric(10,2)', 'varchar(100)')
/// - Unknown type names
///
/// Note: Use DataTypeRegistry.encodeNumeric or encodeText for sized types
int? parseDataTypeId(String typeName) {
  final normalized = typeName.toLowerCase().trim();
  return DataType.fromPostgresType(normalized)?.id;
}

/// Parses a current catalog base type name into its catalog ID.
int? parseRegisteredDataTypeId(String typeName) {
  final normalized = typeName.trim();
  final byName = DataType.fromName(normalized);
  return byName?.id ?? DataType.fromPostgresType(normalized)?.id;
}

/// Check if column type requires specific data type
///
/// System column constraints from AIX db/aix/seed/seed.sql:
/// - Version column (200302) requires INT32 (2)
/// - Status column (200402) requires INT32 (2)
///
/// Returns null if no constraint, otherwise required type ID
int? getRequiredDataType(int columnType) {
  // Version (v) and Status (s) columns require INT32
  if (columnType == 200302 || columnType == 200402) {
    return DataType.int32.id; // INT32 (2)
  }
  return null;
}

/// Validate column type and data type combination
///
/// Checks:
/// - Data type is valid
/// - Column type constraints satisfied (status/version → INT32)
bool isValidColumnDataType(int columnType, int dataType) {
  if (!DataTypeRegistry.isValid(dataType)) {
    return false;
  }

  final required = getRequiredDataType(columnType);
  if (required != null && dataType != required) {
    return false;
  }

  return true;
}
