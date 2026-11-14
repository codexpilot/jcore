/// JSONC (JSON Custom) - AIX data interchange format
///
/// Supports three formats:
/// 1. Full: schema + data (complete dataset)
/// 2. Schema only: schema definition without data
/// 3. Data only: data with reference to existing schema (jid)
library;

import 'dart:convert' as json;

import 'numeric.dart';

const _int64TypeIds = {40000};
final _maxSafeInteger = BigInt.from(9007199254740991);
const _isWeb = bool.fromEnvironment('dart.library.js_interop');

bool _isInt64StringMode(int? jnf) => jnf == 0 || jnf == 3 || jnf == 5;

bool _isNumericStringMode(int? jnf) => jnf == 0 || jnf == 4 || jnf == 5;

BigInt _bigIntFromSafeInt(int value) {
  final result = BigInt.from(value);
  if (result.abs() > _maxSafeInteger) {
    throw FormatException(
      'INT64 values outside the JavaScript safe integer range must be '
      'provided as decimal strings or BigInt in string modes',
    );
  }
  return result;
}

int _exactInt(BigInt value) {
  if (_isWeb && value.abs() > _maxSafeInteger) {
    throw FormatException('INT64 cannot be represented safely as a web int');
  }
  final result = value.toInt();
  if (BigInt.from(result) != value) {
    throw FormatException('INT64 cannot be represented exactly as an int');
  }
  return result;
}

dynamic _normalizeInt64Cell(dynamic value, bool stringMode) {
  if (stringMode) {
    if (value is BigInt) return value;
    if (value is int) return _bigIntFromSafeInt(value);
    if (value is String && RegExp(r'^[+-]?[0-9]+$').hasMatch(value)) {
      return BigInt.tryParse(value) ?? value;
    }
  } else {
    if (value is BigInt) return _exactInt(value);
    if (value is String && RegExp(r'^[+-]?[0-9]+$').hasMatch(value)) {
      final integer = BigInt.tryParse(value);
      if (integer != null) return _exactInt(integer);
    }
  }
  return value;
}

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
///   "jnf": 3,
///   "schema": {"id": 40000, "name": 70000},
///   "data": [[1, "John"], [2, "Jane"]]
/// }
/// ```
///
/// Encoding modes (jnf):
/// - 0: Formal JSON array, both BigInt and Numeric as string (web-safe input)
/// - 1: Formal JSON array, both as plain number (not web-safe)
/// - 2: JSONC, both as plain number (default, not web-safe for INT64)
/// - 3: JSONC, BigInt only as string (web-safe for large integers)
/// - 4: JSONC, Numeric as string (not web-safe for INT64)
/// - 5: JSONC, both as string (maximum safety)
class JsonC {
  /// Schema version - epoch seconds (timestamp when schema was created)
  final int jv;

  /// Schema ID - unique identifier for this schema definition
  final int jid;

  /// JSONC number format (optional, defaults to 2)
  /// - 0: Formal JSON array, both BigInt and Numeric as string (web-safe input)
  /// - 1: Formal JSON array, both as plain number (not web-safe)
  /// - 2: JSONC format, both as plain number (default, not web-safe)
  /// - 3: JSONC format, BigInt only as string (web-safe for large integers)
  /// - 4: JSONC format, Numeric as string (not web-safe for INT64)
  /// - 5: JSONC format, both BigInt and Numeric as string (maximum safety)
  final int? jnf;

  /// Column definitions: column_name -> DataType ID
  /// Example: {"id": 40000, "name": 70000, "price": 61002}
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

  /// Get encoding mode (0-5, defaults to 2)
  int get encoding => jnf ?? 2;

  /// Check if this is formal JSON array format (modes 0-1)
  bool get isFormalJsonArray => encoding == 0 || encoding == 1;

  /// Check if this is JSONC format (modes 2-5)
  bool get isJsonCFormat => encoding >= 2 && encoding <= 5;

  /// Check if BigInt should be encoded as string
  bool get useBigIntStrings {
    switch (encoding) {
      case 0: // Formal JSON: both string
      case 3: // JSONC: BigInt string
      case 5: // JSONC: both string
        return true;
      default:
        return false;
    }
  }

  /// Check if Numeric should be encoded as string
  bool get useNumericStrings {
    switch (encoding) {
      case 0: // Formal JSON: both string
      case 4: // JSONC: Numeric string
      case 5: // JSONC: both string
        return true;
      default:
        return false;
    }
  }

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
  List<String> get columnNames => schema?.keys.toList() ?? [];

  /// Get data type IDs in column order
  List<int> get dataTypeIds => schema?.values.toList() ?? [];

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

  /// Return a copy with schema-identified INT64 cells in their Dart form.
  ///
  /// Modes 0, 3 and 5 use [BigInt]; other modes use [int]. An optional schema
  /// can be supplied for data-only payloads. Values that are not valid INT64
  /// inputs remain unchanged so callers can report validation errors.
  JsonC normalizeInt64({Map<String, int>? schema}) {
    final effectiveSchema = schema ?? this.schema;
    if (effectiveSchema == null || data == null) return this;
    final types = effectiveSchema.values.toList();
    final rows = data!.map((row) {
      return List<dynamic>.generate(row.length, (i) {
        if (i >= types.length || !_int64TypeIds.contains(types[i])) {
          return row[i];
        }
        return _normalizeInt64Cell(row[i], _isInt64StringMode(jnf));
      });
    }).toList();
    return JsonC(
      jv: jv,
      jid: jid,
      jnf: jnf,
      schema: effectiveSchema,
      data: rows,
    );
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
    ).normalizeInt64();
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'jv': jv, 'jid': jid};

    if (jnf != null) {
      result['jnf'] = jnf;
    }

    if (schema != null) {
      result['schema'] = schema;
    }

    if (data != null) {
      final types = schema?.values.toList();
      final stringMode = _isInt64StringMode(jnf);
      result['data'] = data!.map((row) {
        return List<dynamic>.generate(row.length, (i) {
          final value = row[i];
          final hasType = types != null && i < types.length;
          final typeId = hasType ? types[i] : null;
          final isInt64 = typeId != null && _int64TypeIds.contains(typeId);
          if (stringMode && (isInt64 || types == null && value is BigInt)) {
            if (value is BigInt) return value.toString();
            if (value is int) return _bigIntFromSafeInt(value).toString();
          } else if (!stringMode && isInt64) {
            return _normalizeInt64Cell(value, false);
          }
          if (value is Numeric) {
            return _isNumericStringMode(jnf) ? value.toString() : value.toNum();
          }
          return value;
        });
      }).toList();
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
      jv.hashCode ^
      jid.hashCode ^
      jnf.hashCode ^
      schema.hashCode ^
      data.hashCode;

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
