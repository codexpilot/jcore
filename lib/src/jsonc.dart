/// JSONC (JSON Custom) - AIX data interchange format
///
/// Supports three formats:
/// 1. Full: schema + data (complete dataset)
/// 2. Schema only: schema definition without data
/// 3. Data only: data with reference to existing schema (jid)
library;

import 'dart:convert' as json;

/// JSONC format types
enum JsonCType {
  /// Contains jv, jid, schema, and data
  full,

  /// Contains jv, jid, and schema only
  schemaOnly,

  /// Contains jv, jid, and data only
  dataOnly,
}

/// JSONC container for AIX data interchange
///
/// Example full format:
/// ```json
/// {
///   "jv": 1731542400,
///   "jid": 12345,
///   "jnf": 1,
///   "schema": {"id": 300003, "name": 300008},
///   "data": [[1, "John"], [2, "Jane"]]
/// }
/// ```
class JsonC {
  /// Schema version - epoch seconds (timestamp when schema was created)
  final int jv;

  /// Schema ID - unique identifier for this schema definition
  final int jid;

  /// JSONC number format (optional, defaults to 0)
  /// - 0: All numbers (default, best performance)
  /// - 1: BigInt as string, numeric as number (JavaScript-safe)
  /// - 2: All strings (maximum precision)
  final int? jnf;

  /// Column definitions: column_name -> JDataType ID
  /// Example: {"id": 300003, "name": 300008, "price": 310020}
  final Map<String, int>? schema;

  /// Data rows as arrays matching schema column order
  /// Example: [[1, "Product A", 19.99], [2, "Product B", 29.99]]
  final List<List<dynamic>>? data;

  const JsonC({
    required this.jv,
    required this.jid,
    this.jnf,
    this.schema,
    this.data,
  });

  /// Get encoding mode (0=all numbers, 1=BigInt string, 2=all strings)
  int get encoding => jnf ?? 0;

  /// Check if BigInt should be encoded as string
  bool get useBigIntStrings => encoding == 1 || encoding == 2;

  /// Check if numeric should be encoded as string
  bool get useNumericStrings => encoding == 2;

  /// Determine JSONC type based on present fields
  JsonCType get type {
    if (schema != null && data != null) return JsonCType.full;
    if (schema != null) return JsonCType.schemaOnly;
    return JsonCType.dataOnly;
  }

  /// Check if schema is present
  bool get hasSchema => schema != null;

  /// Check if data is present
  bool get hasData => data != null;

  /// Get column names in order
  List<String> get columnNames =>
      schema?.keys.toList() ?? [];

  /// Get data type IDs in column order
  List<int> get dataTypeIds =>
      schema?.values.toList() ?? [];

  /// Get number of columns
  int get columnCount => schema?.length ?? 0;

  /// Get number of data rows
  int get rowCount => data?.length ?? 0;

  /// Check if JSONC is valid
  bool get isValid {
    // Must have jv and jid
    if (jv < 0 || jid < 0) return false;

    // Must have either schema or data
    if (schema == null && data == null) return false;

    // If has data, validate row lengths match schema
    if (data != null && schema != null) {
      final expectedLength = schema!.length;
      for (final row in data!) {
        if (row.length != expectedLength) return false;
      }
    }

    return true;
  }

  /// Create from JSON map
  factory JsonC.fromJson(Map<String, dynamic> json) {
    return JsonC(
      jv: json['jv'] as int,
      jid: json['jid'] as int,
      jnf: json['jnf'] as int?,
      schema: json['schema'] != null
          ? Map<String, int>.from(json['schema'] as Map)
          : null,
      data: json['data'] != null
          ? (json['data'] as List)
              .map((row) => List<dynamic>.from(row as List))
              .toList()
          : null,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'jv': jv,
      'jid': jid,
    };

    if (jnf != null) {
      result['jnf'] = jnf;
    }

    if (schema != null) {
      result['schema'] = schema;
    }

    if (data != null) {
      result['data'] = data;
    }

    return result;
  }

  /// Parse JSONC from JSON string
  static JsonC parse(String jsonString) {
    final decoded = json.jsonDecode(jsonString) as Map<String, dynamic>;
    return JsonC.fromJson(decoded);
  }

  /// Encode JSONC to JSON string
  String encode({bool pretty = false}) {
    if (pretty) {
      return json.JsonEncoder.withIndent('  ').convert(toJson());
    }
    return json.jsonEncode(toJson());
  }

  @override
  String toString() => encode(pretty: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JsonC &&
          runtimeType == other.runtimeType &&
          jv == other.jv &&
          jid == other.jid &&
          jnf == other.jnf &&
          _mapEquals(schema, other.schema) &&
          _listEquals(data, other.data);

  @override
  int get hashCode =>
      jv.hashCode ^ jid.hashCode ^ jnf.hashCode ^ schema.hashCode ^ data.hashCode;

  static bool _mapEquals(Map? a, Map? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  static bool _listEquals(List? a, List? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] is List && b[i] is List) {
        if (!_listEquals(a[i], b[i])) return false;
      } else if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
