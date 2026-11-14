/// AIX Data Type catalog (Group 3: 300000-399999)
///
/// Base types from mx.typex WHERE g = 3
/// Encoding: i = group * 100000 + key = 3 * 100000 + k = 300000 + k
enum JDataType {
  /// NUMERIC - Unlimited precision decimal (PostgreSQL: numeric)
  numeric(300000, 'NUMERIC', 'numeric'),

  /// BOOLEAN - True/false (PostgreSQL: boolean)
  boolean(300001, 'BOOLEAN', 'boolean'),

  /// INT32 - 4-byte integer (PostgreSQL: integer)
  /// Required for Status (s) and Version (v) system columns
  int32(300002, 'INT32', 'integer'),

  /// INT64 - 8-byte integer (PostgreSQL: bigint)
  int64(300003, 'INT64', 'bigint'),

  /// DATETIME - Epoch milliseconds UTC (PostgreSQL: bigint)
  datetime(300004, 'DATETIME', 'bigint'),

  /// TIME - Time storage (PostgreSQL: bigint)
  time(300005, 'TIME', 'bigint'),

  /// UUID - Universal unique identifier (PostgreSQL: uuid)
  uuid(300006, 'UUID', 'uuid'),

  /// TEXT0Z - Base-36 CUID for offline ID generation (PostgreSQL: text)
  /// Format: 32 characters [version:1][app:6][server:4][terminal:5][epoch_ms:10][serial:6]
  text0z(300007, 'TEXT0Z', 'text'),

  /// TEXT - Unlimited text (PostgreSQL: text)
  text(300008, 'TEXT', 'text'),

  /// JSONB - Binary JSON (PostgreSQL: jsonb)
  jsonb(300009, 'JSONB', 'jsonb');

  const JDataType(this.id, this.name, this.postgresType);

  /// TypeX catalog ID (300000-300009 for base types)
  final int id;

  /// AIX internal name
  final String name;

  /// PostgreSQL type name
  final String postgresType;

  /// Lookup data type by catalog ID
  static JDataType? fromId(int id) {
    for (final type in values) {
      if (type.id == id) return type;
    }
    return null;
  }

  /// Lookup data type by AIX name
  static JDataType? fromName(String name) {
    final upperName = name.toUpperCase();
    for (final type in values) {
      if (type.name == upperName) return type;
    }
    return null;
  }

  /// Lookup data type by PostgreSQL type name
  static JDataType? fromPostgresType(String pgType) {
    final lowerType = pgType.toLowerCase();
    for (final type in values) {
      if (type.postgresType == lowerType) return type;
    }
    return null;
  }
}
