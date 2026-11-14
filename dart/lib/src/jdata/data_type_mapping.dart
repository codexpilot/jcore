import 'j_data_type.dart';
import 'data_type_registry.dart';
import 'data_type_decoding.dart';
import 'data_type_validation.dart';

/// AIX to PostgreSQL type mapping functions

/// Get PostgreSQL type declaration for a catalog ID
///
/// Returns PostgreSQL DDL type string:
/// - Base types: direct mapping (300002 → 'integer')
/// - NUMERIC with precision: 'numeric(p,s)'
/// - TEXT with length: 'text(len)' (non-standard, for documentation)
/// - Invalid types: null
///
/// Examples:
/// ```dart
/// getPostgresType(300002) // 'integer'
/// getPostgresType(300000) // 'numeric'
/// getPostgresType(310020) // 'numeric(10,2)'
/// getPostgresType(301008) // 'text(100)'
/// getPostgresType(999999) // null - invalid
/// ```
String? getPostgresType(int typeId) {
  final dataType = DataTypeRegistry.postgresType(typeId);
  if (dataType != null) return dataType;

  // Try base type lookup
  final baseType = JDataType.fromId(typeId);
  if (baseType != null) {
    return baseType.postgresType;
  }

  // Try parameterized NUMERIC
  final numericParams = decodeNumericType(typeId);
  if (numericParams != null) {
    final p = numericParams.precision;
    final s = numericParams.scale;
    if (p != null) {
      return 'numeric($p,$s)';
    }
    return 'numeric'; // unlimited
  }

  // Try parameterized TEXT
  final textLength = decodeTextType(typeId);
  if (textLength != null) {
    return 'text($textLength)';
  }

  // Check if unlimited TEXT (returns null from decodeTextType but valid)
  if (typeId == 300008) {
    return 'text';
  }

  return null;
}

/// Parse PostgreSQL type name to catalog ID
///
/// Supports base type names only (no parameterized types):
/// - 'integer' → 300002
/// - 'bigint' → 300003
/// - 'boolean' → 300001
/// - 'numeric' → 300000 (unlimited)
/// - 'text' → 300008 (unlimited)
/// - 'uuid' → 300006
/// - 'jsonb' → 300009
///
/// Returns null for:
/// - Parameterized types ('numeric(10,2)', 'text(100)')
/// - Unknown type names
///
/// Note: Use [encodeNumericType] or [encodeTextType] for sized types
int? parseDataTypeId(String typeName) {
  final normalized = typeName.toLowerCase().trim();

  // Preserve the existing parser for shared names. Call
  // parseRegisteredDataTypeId to select the current catalog explicitly.
  if (normalized == 'smallint') return DataType.smallint.id;

  // Try direct PostgreSQL type lookup
  final dataType = JDataType.fromPostgresType(normalized);
  return dataType?.id;
}

/// Parses a current catalog base type name into its catalog ID.
int? parseRegisteredDataTypeId(String typeName) {
  final normalized = typeName.trim();
  final byName = DataType.fromName(normalized);
  return byName?.id ?? DataType.fromPostgresType(normalized)?.id;
}

/// Check if column type requires specific data type
///
/// System column constraints from db/seed.sql:
/// - Status column (200008) requires INT32 (300002)
/// - Version column (200010) requires INT32 (300002)
///
/// Returns null if no constraint, otherwise required type ID
int? getRequiredDataType(int columnType) {
  // Status (s) and Version (v) columns require INT32
  if (columnType == 200008 || columnType == 200010) {
    return 300002; // INT32
  }
  return null;
}

/// Validate column type and data type combination
///
/// Checks:
/// - Data type is valid
/// - Column type constraints satisfied (status/version → INT32)
bool isValidColumnDataType(int columnType, int dataType) {
  if (!isValidDataType(dataType)) {
    return false;
  }

  final required = getRequiredDataType(columnType);
  if (required != null && dataType != required) {
    return false;
  }

  return true;
}
