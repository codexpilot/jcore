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
///   "jcore": "4.4.0",
///   "dataSchemaVersion": 1731542400,
///   "resultSchemaId": 12345,
///   "encoding": 3,
///   "columns": ["id", "name"],
///   "schema": {"id": 40000, "name": 70000},
///   "data": [[1, "John"], [2, "Jane"]]
/// }
/// ```
///
/// Encoding modes (encoding):
/// - 0: Formal JSON array, both BigInt and Numeric as string (web-safe input)
/// - 1: Formal JSON array, both as plain number (not web-safe)
/// - 2: JSONC, both as plain number (default, not web-safe for INT64)
/// - 3: JSONC, BigInt only as string (web-safe for large integers)
/// - 4: JSONC, Numeric as string (not web-safe for INT64)
/// - 5: JSONC, both as string (maximum safety)
/// - 8-13: Extended modes with text temporal values (RFC 3339, HH:mm:ss.SSS)
class JsonC {
  /// JCore package version (optional)
  final String? jcore;

  /// MJUX package version (optional)
  final String? mjux;

  /// Application version with build number (optional)
  final String? appx;

  /// Data schema version - epoch seconds (timestamp when schema was created)
  final int dataSchemaVersion;

  /// UX schema version - uidef format version (optional)
  final int? uxSchemaVersion;

  /// Result schema ID - unique identifier for this schema definition
  final int resultSchemaId;

  /// Encoding mode (0-5, 8-13, defaults to 2)
  /// - 0: Formal JSON array, both BigInt and Numeric as string (web-safe input)
  /// - 1: Formal JSON array, both as plain number (not web-safe)
  /// - 2: JSONC format, both as plain number (default, not web-safe)
  /// - 3: JSONC format, BigInt only as string (web-safe for large integers)
  /// - 4: JSONC format, Numeric as string (not web-safe for INT64)
  /// - 5: JSONC format, both BigInt and Numeric as string (maximum safety)
  /// - 8-13: Extended modes with text temporal values
  final int? encoding;

  /// Explicit column ordering (optional)
  /// When present, defines the order for decoding data rows
  final List<String>? columns;

  /// Column definitions: column_name -> DataType ID
  /// Example: {"id": 40000, "name": 70000, "price": 61002}
  final Map<String, int>? schema;

  /// Data rows as arrays matching schema column order
  /// Example: [[1, "Product A", 19.99], [2, "Product B", 29.99]]
  final List<List<dynamic>>? data;

  const JsonC({
    this.jcore,
    this.mjux,
    this.appx,
    required this.dataSchemaVersion,
    this.uxSchemaVersion,
    required this.resultSchemaId,
    this.encoding,
    this.columns,
    this.schema,
    this.data,
  });

  /// Get encoding mode (0-5, 8-13, defaults to 2)
  int get encodingMode => encoding ?? 2;

  /// Check if this is a valid encoding mode (0-5 or 8-13)
  bool get isValidEncoding {
    final mode = encodingMode;
    return (mode >= 0 && mode <= 5) || (mode >= 8 && mode <= 13);
  }

  /// Check if this is extended mode with text temporal values (8-13)
  bool get isExtendedMode => encodingMode >= 8 && encodingMode <= 13;

  /// Get base mode for extended modes (encoding - 8), or encoding for base modes
  int get baseMode => isExtendedMode ? encodingMode - 8 : encodingMode;

  /// Check if this is formal JSON array format (modes 0-1, 8-9)
  bool get isFormalJsonArray {
    final base = baseMode;
    return base == 0 || base == 1;
  }

  /// Check if this is JSONC format (modes 2-5, 10-13)
  bool get isJsonCFormat {
    final base = baseMode;
    return base >= 2 && base <= 5;
  }

  /// Check if BigInt should be encoded as string
  bool get useBigIntStrings {
    switch (baseMode) {
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
    switch (baseMode) {
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
  /// Uses explicit columns field if present, otherwise schema keys
  List<String> get columnNames => columns ?? schema?.keys.toList() ?? [];

  /// Get data type IDs in column order
  /// Uses explicit columns ordering if present
  List<int> get dataTypeIds {
    if (schema == null) return [];
    final cols = columnNames;
    return cols.map((name) => schema![name]).whereType<int>().toList();
  }

  /// Get number of columns
  int get columnCount => schema?.length ?? 0;

  /// Get number of data rows
  int get rowCount => data?.length ?? 0;

  /// Check if JSONC is valid
  bool get isValid {
    // Must have dataSchemaVersion and resultSchemaId
    if (dataSchemaVersion < 0 || resultSchemaId < 0) return false;

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
  /// Modes 0, 3, 5, 8, 11, 13 use [BigInt]; other modes use [int]. An optional
  /// schema can be supplied for data-only payloads. Values that are not valid
  /// INT64 inputs remain unchanged so callers can report validation errors.
  JsonC normalizeInt64({Map<String, int>? schema}) {
    final effectiveSchema = schema ?? this.schema;
    if (effectiveSchema == null || data == null) return this;

    // Use explicit column ordering if available
    final cols = columns ?? effectiveSchema.keys.toList();
    final types = cols.map((name) => effectiveSchema[name]).whereType<int>().toList();

    final rows = data!.map((row) {
      return List<dynamic>.generate(row.length, (i) {
        if (i >= types.length || !_int64TypeIds.contains(types[i])) {
          return row[i];
        }
        return _normalizeInt64Cell(row[i], _isInt64StringMode(encoding));
      });
    }).toList();

    return JsonC(
      jcore: jcore,
      mjux: mjux,
      appx: appx,
      dataSchemaVersion: dataSchemaVersion,
      uxSchemaVersion: uxSchemaVersion,
      resultSchemaId: resultSchemaId,
      encoding: encoding,
      columns: columns,
      schema: effectiveSchema,
      data: rows,
    );
  }

  /// Create from JSON map
  /// Only accepts canonical field names (not legacy jv/jid/jnf)
  factory JsonC.fromJson(Map<String, dynamic> json) {
    // Require canonical field names
    final dataSchemaVersion = json['dataSchemaVersion'] as int?;
    if (dataSchemaVersion == null) {
      throw FormatException('Missing required field: dataSchemaVersion');
    }

    final resultSchemaId = json['resultSchemaId'] as int?;
    if (resultSchemaId == null) {
      throw FormatException('Missing required field: resultSchemaId');
    }

    final encoding = json['encoding'] as int?;

    // Validate encoding mode if present
    if (encoding != null) {
      final isValid = (encoding >= 0 && encoding <= 5) || (encoding >= 8 && encoding <= 13);
      if (!isValid) {
        throw FormatException(
          'Invalid encoding mode: $encoding (valid: 0-5, 8-13)',
        );
      }
    }

    // Parse columns if present
    final columns = json['columns'] != null
        ? List<String>.from(json['columns'] as List)
        : null;

    return JsonC(
      jcore: json['jcore'] as String?,
      mjux: json['mjux'] as String?,
      appx: json['appx'] as String?,
      dataSchemaVersion: dataSchemaVersion,
      uxSchemaVersion: json['uxSchemaVersion'] as int?,
      resultSchemaId: resultSchemaId,
      encoding: encoding,
      columns: columns,
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
  /// Emits only canonical field names (not legacy jv/jid/jnf)
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'dataSchemaVersion': dataSchemaVersion,
      'resultSchemaId': resultSchemaId,
    };

    // Include optional version fields
    if (jcore != null) {
      result['jcore'] = jcore;
    }

    if (mjux != null) {
      result['mjux'] = mjux;
    }

    if (appx != null) {
      result['appx'] = appx;
    }

    if (uxSchemaVersion != null) {
      result['uxSchemaVersion'] = uxSchemaVersion;
    }

    if (encoding != null) {
      result['encoding'] = encoding;
    }

    if (columns != null) {
      result['columns'] = columns;
    }

    if (schema != null) {
      result['schema'] = schema;
    }

    if (data != null) {
      // Use explicit column ordering to get types
      final types = dataTypeIds;
      final stringMode = _isInt64StringMode(encoding);

      result['data'] = data!.map((row) {
        return List<dynamic>.generate(row.length, (i) {
          final value = row[i];
          final hasType = i < types.length;
          final typeId = hasType ? types[i] : null;
          final isInt64 = typeId != null && _int64TypeIds.contains(typeId);

          if (stringMode && (isInt64 || types.isEmpty && value is BigInt)) {
            if (value is BigInt) return value.toString();
            if (value is int) return _bigIntFromSafeInt(value).toString();
          } else if (!stringMode && isInt64) {
            return _normalizeInt64Cell(value, false);
          }

          if (value is Numeric) {
            return _isNumericStringMode(encoding)
                ? value.toString()
                : value.toNum();
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
          jcore == other.jcore &&
          mjux == other.mjux &&
          appx == other.appx &&
          dataSchemaVersion == other.dataSchemaVersion &&
          uxSchemaVersion == other.uxSchemaVersion &&
          resultSchemaId == other.resultSchemaId &&
          encoding == other.encoding &&
          _listEquals(columns, other.columns) &&
          _mapEquals(schema, other.schema) &&
          _listEquals(data, other.data);

  @override
  int get hashCode =>
      jcore.hashCode ^
      mjux.hashCode ^
      appx.hashCode ^
      dataSchemaVersion.hashCode ^
      uxSchemaVersion.hashCode ^
      resultSchemaId.hashCode ^
      encoding.hashCode ^
      columns.hashCode ^
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
