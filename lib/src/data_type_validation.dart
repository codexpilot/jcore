/// AIX data type validation functions
///
/// Implements the exact logic from db/validation.sql:
/// - valid_data_type(v_dt integer) - lines 217-223
/// - valid_numeric_type(v_dt integer) - lines 183-203
/// - valid_text_type(v_dt integer) - lines 205-215
library;

/// Check if type ID is a base data type (300000-300009)
bool isBaseDataType(int typeId) {
  return typeId >= 300000 && typeId <= 300009;
}

/// Validate NUMERIC(precision, scale) type ID
///
/// PostgreSQL implementation: db/validation.sql lines 183-203
///
/// Rules:
/// - 300000 = unlimited NUMERIC (valid)
/// - Must end in 0 (typeId % 10 == 0)
/// - Range: 300000-399999
/// - Precision: (typeId - 300000) / 1000, must be 1-99
/// - Scale: ((typeId - 300000) % 1000) / 10, must be 0-precision
bool isValidNumericType(int typeId) {
  // Unlimited NUMERIC
  if (typeId == 300000) return true;

  // Must end in 0
  if (typeId % 10 != 0) return false;

  // Range check
  if (typeId < 300000 || typeId >= 400000) return false;

  // Extract precision and scale
  final precision = (typeId - 300000) ~/ 1000;
  final scale = ((typeId - 300000) % 1000) ~/ 10;

  // Validate constraints
  if (precision < 1 || precision > 99) return false;
  if (scale < 0 || scale > precision) return false;

  return true;
}

/// Validate TEXT(length) type ID
///
/// PostgreSQL implementation: db/validation.sql lines 205-215
///
/// Rules:
/// - 300008 = unlimited TEXT (valid)
/// - Must end in 8 (typeId % 10 == 8)
/// - Range: 300008-399998
/// - Length: (typeId - 300008) / 10, must be 1-9999
bool isValidTextType(int typeId) {
  // Unlimited TEXT
  if (typeId == 300008) return true;

  // Must end in 8
  if (typeId % 10 != 8) return false;

  // Range check
  if (typeId < 300018 || typeId > 399998) return false;

  // Extract and validate length
  final length = (typeId - 300008) ~/ 10;
  if (length < 1 || length > 9999) return false;

  return true;
}

/// Validate any data type ID
///
/// PostgreSQL implementation: db/validation.sql lines 217-223
///
/// Valid types:
/// - Base types: 300000-300009
/// - Parameterized NUMERIC: valid_numeric_type()
/// - Parameterized TEXT: valid_text_type()
bool isValidDataType(int typeId) {
  // Base types
  if (isBaseDataType(typeId)) return true;

  // Parameterized types
  return isValidNumericType(typeId) || isValidTextType(typeId);
}
