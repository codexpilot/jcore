import 'data_type_validation.dart';

/// AIX data type decoding functions
///
/// Extracts type specifications from catalog IDs

/// NUMERIC type parameters decoded from catalog ID
typedef NumericTypeParams = ({int? precision, int? scale});

/// Decode NUMERIC type ID to precision and scale
///
/// Returns:
/// - `null` if not a valid NUMERIC type
/// - `(precision: null, scale: null)` for unlimited NUMERIC (300000)
/// - `(precision: p, scale: s)` for NUMERIC(p,s)
///
/// Examples:
/// ```dart
/// decodeNumericType(300000) // (precision: null, scale: null) - unlimited
/// decodeNumericType(310020) // (precision: 10, scale: 2) - NUMERIC(10,2)
/// decodeNumericType(305000) // (precision: 5, scale: 0) - NUMERIC(5,0)
/// decodeNumericType(300002) // null - not a NUMERIC type (INT32)
/// ```
NumericTypeParams? decodeNumericType(int typeId) {
  if (!isValidNumericType(typeId)) {
    return null;
  }

  // Unlimited NUMERIC
  if (typeId == 300000) {
    return (precision: null, scale: null);
  }

  // Extract precision and scale
  final precision = (typeId - 300000) ~/ 1000;
  final scale = ((typeId - 300000) % 1000) ~/ 10;

  return (precision: precision, scale: scale);
}

/// Decode TEXT type ID to length
///
/// Returns:
/// - `null` for unlimited TEXT (300008) or invalid TEXT type
/// - Length (1-9999) for TEXT(length)
///
/// Examples:
/// ```dart
/// decodeTextType(300008) // null - unlimited TEXT
/// decodeTextType(301008) // 100 - TEXT(100)
/// decodeTextType(300018) // 1 - TEXT(1)
/// decodeTextType(300002) // null - not a TEXT type (INT32)
/// ```
int? decodeTextType(int typeId) {
  if (!isValidTextType(typeId)) {
    return null;
  }

  // Unlimited TEXT
  if (typeId == 300008) {
    return null;
  }

  // Extract length
  return (typeId - 300008) ~/ 10;
}
