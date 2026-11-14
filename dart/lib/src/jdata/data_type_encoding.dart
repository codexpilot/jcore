/// AIX data type encoding functions
///
/// Converts type specifications to catalog IDs matching PostgreSQL logic
library;

/// Encode NUMERIC type with optional precision and scale
///
/// Returns catalog ID for NUMERIC type:
/// - No args: 300000 (unlimited NUMERIC)
/// - With precision/scale: 300000 + (precision × 1000) + (scale × 10)
///
/// Examples:
/// ```dart
/// encodeNumericType() // 300000 - unlimited
/// encodeNumericType(precision: 10, scale: 2) // 310020 - NUMERIC(10,2)
/// encodeNumericType(precision: 5) // 305000 - NUMERIC(5,0)
/// ```
///
/// Constraints:
/// - Precision: 1-99
/// - Scale: 0-precision
/// - Result always ends in 0
///
/// Throws [ArgumentError] if constraints violated
int encodeNumericType({int? precision, int? scale}) {
  // Unlimited NUMERIC
  if (precision == null && scale == null) {
    return 300000;
  }

  // Validate precision
  if (precision == null) {
    throw ArgumentError('Precision required when scale is specified');
  }
  if (precision < 1 || precision > 99) {
    throw ArgumentError('NUMERIC precision must be 1-99, got: $precision');
  }

  // Validate scale
  final s = scale ?? 0;
  if (s < 0 || s > precision) {
    throw ArgumentError(
      'NUMERIC scale must be 0-precision (0-$precision), got: $s',
    );
  }

  return 300000 + (precision * 1000) + (s * 10);
}

/// Encode TEXT type with optional length
///
/// Returns catalog ID for TEXT type:
/// - No args: 300008 (unlimited TEXT)
/// - With length: 300008 + (length × 10)
///
/// Examples:
/// ```dart
/// encodeTextType() // 300008 - unlimited
/// encodeTextType(length: 100) // 301008 - TEXT(100)
/// encodeTextType(length: 1) // 300018 - TEXT(1)
/// ```
///
/// Constraints:
/// - Length: 1-9999
/// - Result always ends in 8
///
/// Throws [ArgumentError] if constraints violated
int encodeTextType({int? length}) {
  // Unlimited TEXT
  if (length == null) {
    return 300008;
  }

  // Validate length
  if (length < 1 || length > 9999) {
    throw ArgumentError('TEXT length must be 1-9999, got: $length');
  }

  return 300008 + (length * 10);
}
