/// Data type catalog and registry (DataTypeX).
///
/// DataTypeX uses direct IDs for base types (0-7) and range-based encoding
/// for parameterized types:
///
/// - Base types: 0-7 (8 types)
///   - 0: BOOLEAN, 1: SMALLINT, 2: INT32, 3: INT64
///   - 4: DATETIME, 5: TIME, 6: UUID, 7: JSONB
///
/// - TEXT range: 10000-19999
///   - 10000: unlimited TEXT
///   - 10001-19999: TEXT(1) through TEXT(9999)
///   - Formula: 10000 + length
///
/// - NUMERIC range: 20000-29999
///   - 20000: unlimited NUMERIC
///   - 20100-29999: NUMERIC(precision, scale)
///   - Formula: 20000 + precision * 100 + scale
///   - Constraints: 1 <= precision <= 99, 0 <= scale <= precision
///
/// These IDs and formulas are shared across language ports (Dart, Go, etc.)
/// and align with the AIX database catalog (cox.datatypex).
library;

/// Canonical data types in the current registry (DataTypeX).
///
/// Base types: 0-7
/// TEXT range: 10000-19999 (10000 = unlimited)
/// NUMERIC range: 20000-29999 (20000 = unlimited)
enum DataType {
  /// Boolean.
  boolean(0, 'BOOLEAN', 'boolean'),

  /// Signed 16-bit integer; also known as INT16.
  smallint(1, 'SMALLINT', 'smallint'),

  /// Signed 32-bit integer.
  int32(2, 'INT32', 'integer'),

  /// Signed 64-bit integer.
  int64(3, 'INT64', 'bigint'),

  /// UTC datetime stored in the 64-bit class.
  datetime(4, 'DATETIME', 'bigint'),

  /// Time value stored in the 64-bit class.
  time(5, 'TIME', 'bigint'),

  /// UUID.
  uuid(6, 'UUID', 'uuid'),

  /// JSONB document (binary JSON).
  jsonb(7, 'JSONB', 'jsonb'),

  /// Unlimited precision decimal (base type for NUMERIC range).
  numeric(20000, 'NUMERIC', 'numeric'),

  /// Unlimited text (base type for TEXT range).
  text(10000, 'TEXT', 'text');

  /// Creates a data type catalog entry.
  const DataType(this.id, this.name, this.postgresType);

  /// ID in the current catalog.
  final int id;

  /// Canonical name in the catalog.
  final String name;

  /// PostgreSQL storage type.
  final String postgresType;

  /// INT16 is an alias for SMALLINT.
  static const DataType int16 = DataType.smallint;

  /// Looks up a base type by its ID.
  static DataType? fromId(int id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// Looks up a base type by its catalog name, including the INT16 alias.
  static DataType? fromName(String name) {
    final normalized = name.trim().toUpperCase();
    if (normalized == 'INT16') return smallint;
    for (final type in values) {
      if (type.name == normalized) return type;
    }
    return null;
  }

  /// Looks up a base type by its PostgreSQL type name.
  static DataType? fromPostgresType(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized == 'int2') return smallint;
    if (normalized == 'int4' || normalized == 'int') return int32;
    if (normalized == 'int8') return int64;
    for (final type in values) {
      if (type.postgresType == normalized) return type;
    }
    return null;
  }
}

/// Lookup, encoding, decoding, and validation for the current catalog.
abstract final class DataTypeRegistry {
  /// First assigned registry ID (base types start at 0).
  static const int firstId = 0;

  /// Last assigned base type ID (0-7, then TEXT/NUMERIC ranges).
  static const int lastId = 7;

  /// All base types in catalog order.
  static List<DataType> get types => List.unmodifiable(DataType.values);

  /// Looks up a base type. Parameterized IDs are not base types.
  static DataType? fromId(int id) => DataType.fromId(id);

  /// Looks up a base type by canonical name or alias.
  static DataType? fromName(String name) => DataType.fromName(name);

  /// Looks up a base type by PostgreSQL type name.
  static DataType? fromPostgresType(String name) =>
      DataType.fromPostgresType(name);

  /// Checks whether an ID belongs to this catalog.
  static bool contains(int id) => isValid(id);

  /// Checks whether an ID identifies a base or parameterized type.
  static bool isValid(int id) =>
      DataType.fromId(id) != null || isValidNumeric(id) || isValidText(id);

  /// Checks whether an ID identifies unlimited or parameterized NUMERIC.
  static bool isValidNumeric(int typeId) {
    if (typeId == DataType.numeric.id) return true;
    if (typeId < 20100 || typeId > 29999) return false;

    final offset = typeId - DataType.numeric.id;
    final precision = offset ~/ 100;
    final scale = offset % 100;
    return precision >= 1 && precision <= 99 && scale <= precision;
  }

  /// Encodes NUMERIC as 20000 + precision * 100 + scale.
  static int encodeNumeric({int? precision, int? scale}) {
    if (precision == null && scale == null) return DataType.numeric.id;
    if (precision == null) {
      throw ArgumentError('Precision is required when scale is specified');
    }
    if (precision < 1 || precision > 99) {
      throw ArgumentError('NUMERIC precision must be 1-99, got: $precision');
    }
    final actualScale = scale ?? 0;
    if (actualScale < 0 || actualScale > precision) {
      throw ArgumentError(
        'NUMERIC scale must be 0-$precision, got: $actualScale',
      );
    }
    return DataType.numeric.id + precision * 100 + actualScale;
  }

  /// Decodes precision and scale from a NUMERIC ID.
  static ({int? precision, int? scale})? decodeNumeric(int typeId) {
    if (!isValidNumeric(typeId)) return null;
    if (typeId == DataType.numeric.id) return (precision: null, scale: null);

    final offset = typeId - DataType.numeric.id;
    return (precision: offset ~/ 100, scale: offset % 100);
  }

  /// Checks whether an ID identifies unlimited or length-parameterized TEXT.
  static bool isValidText(int typeId) =>
      typeId == DataType.text.id || (typeId >= 10001 && typeId <= 19999);

  /// Encodes TEXT as 10000 + length.
  static int encodeText({int? length}) {
    if (length == null) return DataType.text.id;
    if (length < 1 || length > 9999) {
      throw ArgumentError('TEXT length must be 1-9999, got: $length');
    }
    return DataType.text.id + length;
  }

  /// Decodes a TEXT length. Null means unlimited TEXT or an invalid ID.
  static int? decodeText(int typeId) {
    if (!isValidText(typeId) || typeId == DataType.text.id) return null;
    return typeId - DataType.text.id;
  }

  /// Returns a PostgreSQL type declaration for a catalog ID.
  static String? postgresType(int typeId) {
    final base = DataType.fromId(typeId);
    if (base != null) return base.postgresType;

    final numeric = decodeNumeric(typeId);
    if (numeric != null) {
      final precision = numeric.precision;
      return precision == null
          ? 'numeric'
          : 'numeric($precision,${numeric.scale})';
    }

    final textLength = decodeText(typeId);
    return textLength == null ? null : 'varchar($textLength)';
  }
}
