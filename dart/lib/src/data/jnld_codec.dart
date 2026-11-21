/// JNLD JSONC body codec for JCore query results.
///
/// Implements the four-digit JNLD encoding scheme (J*1000 + N*100 + L*10 + D)
/// for transport-independent query response bodies.
library;

import 'dart:convert' as json;
import 'numeric.dart';
import 'data_type_registry.dart';

/// INT64 range constants
const _minInt64 = -9223372036854775808;
const _maxInt64 = 9223372036854775807;

final _jsonNumber = RegExp(
  r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
);

/// Wrapper for NUMERIC values that should be encoded as raw JSON numbers.
/// Used for N=1 mode to preserve exact decimal representation.
class _RawJsonNumber {
  final String value;
  const _RawJsonNumber(this.value);

  factory _RawJsonNumber.fromString(String value) {
    if (_jsonNumber.matchAsPrefix(value)?.end != value.length) {
      throw FormatException('Invalid JSON number', value);
    }
    return _RawJsonNumber(value);
  }
}

/// JNLD encoding configuration parsed from a four-digit code.
///
/// Default encoding is 8000:
/// - J=8: Full JSON objects keyed by field code
/// - N=0: NUMERIC as decimal strings
/// - L=0: INT64 as integer strings
/// - D=0: DATETIME in ISO UTC format with Z
class JnldEncoding {
  /// JSON structure mode
  final int j;

  /// NUMERIC encoding mode
  final int n;

  /// INT64 encoding mode
  final int l;

  /// Date/time encoding mode
  final int d;

  const JnldEncoding({
    required this.j,
    required this.n,
    required this.l,
    required this.d,
  });

  /// Parse a four-digit JNLD encoding value
  factory JnldEncoding.parse(int encoding) {
    if (encoding < 0 || encoding > 9999) {
      throw FormatException('Encoding must be 0-9999, got: $encoding');
    }

    final j = encoding ~/ 1000;
    final n = (encoding % 1000) ~/ 100;
    final l = (encoding % 100) ~/ 10;
    final d = encoding % 10;

    // Validate J
    if (j != 1 && j != 2 && j != 3 && j != 4 && j != 8 && j != 9) {
      throw FormatException('Invalid J=$j (valid: 1, 2, 3, 4, 8, 9)');
    }

    // Validate N
    if (n != 0 && n != 1) {
      throw FormatException('Invalid N=$n (valid: 0, 1)');
    }

    // Validate L
    if (l != 0 && l != 1) {
      throw FormatException('Invalid L=$l (valid: 0, 1)');
    }

    // Validate D
    if (d != 0 && d != 1 && d != 2 && d != 8) {
      throw FormatException('Invalid D=$d (valid: 0, 1, 2, 8)');
    }

    return JnldEncoding(j: j, n: n, l: l, d: d);
  }

  /// Convert back to four-digit encoding value
  int toInt() => j * 1000 + n * 100 + l * 10 + d;

  /// Whether this uses compact positional rows (J=1, 2, 3, 4)
  bool get isCompact => j >= 1 && j <= 4;

  /// Whether this uses full JSON objects (J=8, 9)
  bool get isFullObjects => j == 8 || j == 9;

  /// Whether metadata is included (J=2, 3, 4)
  bool get hasMetadata => j == 2 || j == 3 || j == 4;

  /// Whether NUMERIC values are encoded as strings
  bool get numericAsString => n == 0;

  /// Whether INT64 values are encoded as strings
  bool get int64AsString => l == 0;

  @override
  String toString() => 'JnldEncoding(${toInt()}: J=$j, N=$n, L=$l, D=$d)';
}

/// Field metadata for JNLD encoding/decoding.
///
/// Represents a single field/column with its identifier, code, name, and type.
class JnldField {
  /// Field identifier (FieldX.i or ColumnX.i)
  final int i;

  /// Field code (FieldX.c or ColumnX.c)
  final String c;

  /// Field name (FieldX.n or ColumnX.n)
  final String n;

  /// Data type identifier (TypeX.i)
  final int typeId;

  /// Data type code (TypeX.c) - optional
  final String? typeCode;

  /// Data type name (TypeX.n)
  final String typeName;

  const JnldField({
    required this.i,
    required this.c,
    required this.n,
    required this.typeId,
    this.typeCode,
    required this.typeName,
  });

  /// Create from FieldX and TypeX metadata
  factory JnldField.fromMeta({
    required int fieldId,
    required String fieldCode,
    required String fieldName,
    required int typeId,
    String? typeCode,
    required String typeName,
  }) {
    return JnldField(
      i: fieldId,
      c: fieldCode,
      n: fieldName,
      typeId: typeId,
      typeCode: typeCode,
      typeName: typeName,
    );
  }
}

/// Schema context for JNLD encoding/decoding.
///
/// Provides ordered field metadata required for compact encodings (J=1, 2, 3, 4).
class JnldSchema {
  /// Ordered list of fields matching row cell positions
  final List<JnldField> fields;

  const JnldSchema(this.fields);

  /// Number of fields in the schema
  int get fieldCount => fields.length;

  /// Validate that field names are unique (required for J=4, J=9)
  void validateUniqueNames() {
    final names = <String>{};
    for (final field in fields) {
      if (!names.add(field.n)) {
        throw FormatException('Duplicate field name: ${field.n}');
      }
    }
  }

  /// Validate that field codes are unique (required for J=3, J=8, J=9)
  void validateUniqueCodes() {
    final codes = <String>{};
    for (final field in fields) {
      if (!codes.add(field.c)) {
        throw FormatException('Duplicate field code: ${field.c}');
      }
    }
  }
}

/// JNLD response body structure.
///
/// Contains data rows and optional metadata for compact encodings.
class JnldBody {
  /// Ordered metadata entries (J=2, 3, 4 only)
  /// Each entry is [key, type] where key and type formats depend on J.
  final List<List<dynamic>>? meta;

  /// Data rows - either positional arrays or full objects
  final List<dynamic> data;

  const JnldBody({this.meta, required this.data});

  /// Parse from JSON map
  factory JnldBody.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] != null
        ? (json['meta'] as List).map((e) => List<dynamic>.from(e as List)).toList()
        : null;

    final data = List<dynamic>.from(json['data'] as List);

    return JnldBody(meta: meta, data: data);
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'data': data};
    if (meta != null) {
      result['meta'] = meta;
    }
    return result;
  }

  /// Parse from JSON string
  static JnldBody parse(String jsonString) {
    final decoded = json.jsonDecode(jsonString) as Map<String, dynamic>;
    return JnldBody.fromJson(decoded);
  }

  /// Encode to JSON string
  String encode({bool pretty = false}) {
    final jsonMap = toJson();

    // Check if data contains _RawJsonNumber instances (N=1 NUMERIC)
    if (_hasRawJsonNumbers(jsonMap['data'])) {
      return _encodeWithRawNumbers(jsonMap, pretty);
    }

    if (pretty) {
      return json.JsonEncoder.withIndent('  ').convert(jsonMap);
    }
    return json.jsonEncode(jsonMap);
  }

  // Check if data structure contains _RawJsonNumber instances
  static bool _hasRawJsonNumbers(dynamic data) {
    if (data is List) {
      for (final item in data) {
        if (item is _RawJsonNumber) return true;
        if (_hasRawJsonNumbers(item)) return true;
      }
    } else if (data is Map) {
      for (final value in data.values) {
        if (value is _RawJsonNumber) return true;
        if (_hasRawJsonNumbers(value)) return true;
      }
    }
    return false;
  }

  // Custom JSON encoding that writes _RawJsonNumber as unquoted numbers
  static String _encodeWithRawNumbers(Map<String, dynamic> jsonMap, bool pretty) {
    final buffer = StringBuffer();
    final indent = pretty ? '  ' : '';
    final newline = pretty ? '\n' : '';
    final space = pretty ? ' ' : '';

    buffer.write('{');

    bool first = true;
    for (final entry in jsonMap.entries) {
      if (!first) buffer.write(',');
      first = false;

      if (pretty) {
        buffer.write(newline);
        buffer.write(indent);
      }

      buffer.write('"${entry.key}":$space');
      _encodeValue(buffer, entry.value, indent, newline, space, pretty ? 1 : 0);
    }

    if (pretty) {
      buffer.write(newline);
    }
    buffer.write('}');

    return buffer.toString();
  }

  static void _encodeValue(
    StringBuffer buffer,
    dynamic value,
    String indent,
    String newline,
    String space,
    int level,
  ) {
    if (value == null) {
      buffer.write('null');
    } else if (value is _RawJsonNumber) {
      buffer.write(value.value);
    } else if (value is String) {
      buffer.write(json.jsonEncode(value));
    } else if (value is num) {
      if (!value.isFinite) throw json.JsonUnsupportedObjectError(value);
      buffer.write(value);
    } else if (value is bool) {
      buffer.write(value);
    } else if (value is List) {
      buffer.write('[');
      for (int i = 0; i < value.length; i++) {
        if (i > 0) buffer.write(',');
        _encodeValue(buffer, value[i], indent, newline, space, level + 1);
      }
      buffer.write(']');
    } else if (value is Map) {
      buffer.write('{');
      bool first = true;
      for (final entry in value.entries) {
        if (!first) buffer.write(',');
        first = false;
        if (newline.isNotEmpty) {
          buffer.write(newline);
          buffer.write(indent * (level + 1));
        }
        final key = entry.key;
        if (key is! String) throw json.JsonUnsupportedObjectError(value);
        buffer.write('${json.jsonEncode(key)}:$space');
        _encodeValue(buffer, entry.value, indent, newline, space, level + 1);
      }
      if (newline.isNotEmpty && !first) {
        buffer.write(newline);
        buffer.write(indent * level);
      }
      buffer.write('}');
    } else {
      buffer.write(json.jsonEncode(value));
    }
  }
}

/// JNLD codec for encoding/decoding query result bodies.
///
/// Provides transport-independent conversion between typed rows and JNLD bodies.
class JnldCodec {
  /// Encode rows to a JNLD body.
  ///
  /// Parameters:
  /// - [encoding]: Four-digit JNLD encoding (default 8000)
  /// - [rows]: Data rows as positional arrays
  /// - [schema]: Field metadata (required)
  /// - [timezone]: Timezone for D=1, D=2 (e.g., "America/New_York")
  ///
  /// Returns a [JnldBody] with data and optional metadata.
  static JnldBody encode({
    int encoding = 8000,
    required List<List<dynamic>> rows,
    required JnldSchema schema,
    String? timezone,
  }) {
    final enc = JnldEncoding.parse(encoding);

    // Validate schema for modes that need unique keys
    if (enc.j == 4 || enc.j == 9) {
      schema.validateUniqueNames();
    }
    if (enc.j == 3 || enc.j == 8 || enc.j == 9) {
      schema.validateUniqueCodes();
    }

    // Validate timezone requirement
    if ((enc.d == 1 || enc.d == 2) && timezone == null) {
      throw ArgumentError('Timezone required for D=${enc.d}');
    }

    // Encode based on J mode
    if (enc.isCompact) {
      return _encodeCompact(enc, rows, schema, timezone);
    } else {
      return _encodeFullObjects(enc, rows, schema, timezone);
    }
  }

  /// Decode a JNLD body to rows.
  ///
  /// Parameters:
  /// - [encoding]: Four-digit JNLD encoding
  /// - [body]: JNLD body to decode
  /// - [schema]: Field metadata (required for J=1, optional for others)
  /// - [timezone]: Timezone for D=1, D=2
  ///
  /// Returns decoded rows as positional arrays.
  static List<List<dynamic>> decode({
    required int encoding,
    required JnldBody body,
    JnldSchema? schema,
    String? timezone,
  }) {
    final enc = JnldEncoding.parse(encoding);

    // J=1 requires schema
    if (enc.j == 1 && schema == null) {
      throw ArgumentError('Schema required for J=1 (data-only compact)');
    }

    // Decode based on J mode
    if (enc.isCompact) {
      return _decodeCompact(enc, body, schema, timezone);
    } else {
      return _decodeFullObjects(enc, body, schema, timezone);
    }
  }

  // Compact encoding implementation (J=1, 2, 3, 4)
  static JnldBody _encodeCompact(
    JnldEncoding enc,
    List<List<dynamic>> rows,
    JnldSchema schema,
    String? timezone,
  ) {
    // Validate row lengths match schema
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].length != schema.fieldCount) {
        throw FormatException(
          'Row $i has ${rows[i].length} cells, expected ${schema.fieldCount}',
        );
      }
    }

    // Build metadata for J=2, 3, 4
    List<List<dynamic>>? meta;
    if (enc.hasMetadata) {
      meta = [];
      for (final field in schema.fields) {
        if (enc.j == 2) {
          // J=2: [FieldX.i, TypeX.i]
          meta.add([field.i, field.typeId]);
        } else if (enc.j == 3) {
          // J=3: [FieldX.c, TypeX.n]
          meta.add([field.c, field.typeName]);
        } else if (enc.j == 4) {
          // J=4: [FieldX.n, TypeX.n]
          meta.add([field.n, field.typeName]);
        }
      }
    }

    // Encode data rows
    final data = rows.map((row) {
      return List<dynamic>.generate(row.length, (i) {
        return _encodeCell(row[i], schema.fields[i].typeId, enc, timezone);
      });
    }).toList();

    return JnldBody(meta: meta, data: data);
  }

  // Full objects encoding implementation (J=8, 9)
  static JnldBody _encodeFullObjects(
    JnldEncoding enc,
    List<List<dynamic>> rows,
    JnldSchema schema,
    String? timezone,
  ) {
    final data = rows.map((row) {
      final obj = <String, dynamic>{};
      for (int i = 0; i < row.length && i < schema.fieldCount; i++) {
        final key = enc.j == 8 ? schema.fields[i].c : schema.fields[i].n;
        obj[key] = _encodeCell(row[i], schema.fields[i].typeId, enc, timezone);
      }
      return obj;
    }).toList();

    return JnldBody(data: data);
  }

  // Compact decoding implementation (J=1, 2, 3, 4)
  static List<List<dynamic>> _decodeCompact(
    JnldEncoding enc,
    JnldBody body,
    JnldSchema? schema,
    String? timezone,
  ) {
    // For J=1, use provided schema
    // For J=2, 3, 4, we could reconstruct schema from metadata
    // but for now we require schema to be provided for proper type decoding

    if (schema == null) {
      throw ArgumentError('Schema required for decoding compact rows');
    }

    final rows = <List<dynamic>>[];
    for (int rowIndex = 0; rowIndex < body.data.length; rowIndex++) {
      final rowData = body.data[rowIndex];
      if (rowData is! List) {
        throw FormatException('Expected array for compact row, got: ${rowData.runtimeType}');
      }

      // Validate row width matches schema
      if (rowData.length != schema.fieldCount) {
        throw FormatException(
          'Row $rowIndex has ${rowData.length} cells, expected ${schema.fieldCount}',
        );
      }

      final row = List<dynamic>.generate(rowData.length, (i) {
        return _decodeCell(rowData[i], schema.fields[i].typeId, enc, timezone);
      });
      rows.add(row);
    }

    return rows;
  }

  // Full objects decoding implementation (J=8, 9)
  static List<List<dynamic>> _decodeFullObjects(
    JnldEncoding enc,
    JnldBody body,
    JnldSchema? schema,
    String? timezone,
  ) {
    if (schema == null) {
      throw ArgumentError('Schema required for decoding full objects');
    }

    final rows = <List<dynamic>>[];
    for (final rowData in body.data) {
      if (rowData is! Map) {
        throw FormatException('Expected object for full row, got: ${rowData.runtimeType}');
      }

      final obj = rowData as Map<String, dynamic>;
      final row = List<dynamic>.generate(schema.fieldCount, (i) {
        final key = enc.j == 8 ? schema.fields[i].c : schema.fields[i].n;
        final value = obj[key];
        return _decodeCell(value, schema.fields[i].typeId, enc, timezone);
      });
      rows.add(row);
    }

    return rows;
  }

  // Encode a single cell value based on type and encoding
  static dynamic _encodeCell(
    dynamic value,
    int typeId,
    JnldEncoding enc,
    String? timezone,
  ) {
    if (value == null) return null;

    // INT64 (40000)
    if (typeId == DataType.int64.id) {
      if (enc.int64AsString) {
        if (value is BigInt) return value.toString();
        if (value is int) return value.toString();
        if (value is String) return value; // Already a string
      } else {
        // L=1: Validate range before converting to int
        BigInt bigIntValue;
        if (value is BigInt) {
          bigIntValue = value;
        } else if (value is int) {
          bigIntValue = BigInt.from(value);
        } else if (value is String) {
          bigIntValue = BigInt.parse(value);
        } else {
          return value;
        }

        // Validate INT64 range
        if (bigIntValue < BigInt.from(_minInt64) || bigIntValue > BigInt.from(_maxInt64)) {
          throw RangeError(
            'INT64 value out of range: $bigIntValue (valid: $_minInt64 to $_maxInt64)',
          );
        }

        return bigIntValue.toInt();
      }
    }

    // NUMERIC (base 60000 and parameterized 60100-69999)
    if (DataTypeRegistry.isValidNumeric(typeId)) {
      if (enc.numericAsString) {
        if (value is Numeric) return value.toString();
        if (value is num) return value.toString();
        if (value is String) return value; // Already a string
      } else {
        if (value is Numeric) {
          final token = value.scale == 0
              ? value.scaledValue.toString()
              : value.toString();
          return _RawJsonNumber(token);
        }
        if (value is num) return value;
        if (value is String) return _RawJsonNumber.fromString(value);
      }
    }

    // DATETIME (40001)
    if (typeId == DataType.datetime.id) {
      return _encodeDatetime(value, enc.d, timezone);
    }

    // TIME (40002)
    if (typeId == DataType.time.id) {
      return _encodeTime(value, enc.d);
    }

    // Default: pass through
    return value;
  }

  // Decode a single cell value based on type and encoding
  static dynamic _decodeCell(
    dynamic value,
    int typeId,
    JnldEncoding enc,
    String? timezone,
  ) {
    if (value == null) return null;

    // INT64 (40000)
    if (typeId == DataType.int64.id) {
      if (enc.int64AsString) {
        if (value is String) return BigInt.parse(value);
        if (value is int) return BigInt.from(value);
      } else {
        if (value is int) return value;
        if (value is String) return int.parse(value);
      }
    }

    // NUMERIC (base 60000 and parameterized 60100-69999)
    if (DataTypeRegistry.isValidNumeric(typeId)) {
      if (enc.numericAsString) {
        if (value is String) return Numeric.parse(value);
      } else {
        // N=1: For precision preservation, value should be a string
        // If it's already a num (from jsonDecode), precision may be lost
        if (value is String) return Numeric.parse(value);
        if (value is num) return Numeric.from(value);
      }
    }

    // DATETIME (40001)
    if (typeId == DataType.datetime.id) {
      return _decodeDatetime(value, enc.d, timezone);
    }

    // TIME (40002)
    if (typeId == DataType.time.id) {
      return _decodeTime(value, enc.d);
    }

    // Default: pass through
    return value;
  }

  // Encode DATETIME based on D mode
  static dynamic _encodeDatetime(dynamic value, int d, String? timezone) {
    // Value is UTC milliseconds
    if (value is! int) {
      throw FormatException('DATETIME value must be UTC milliseconds (int)');
    }

    final utcTime = DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

    if (d == 0) {
      // D=0: ISO UTC with Z
      return utcTime.toIso8601String();
    } else if (d == 1) {
      // D=1: ISO server-local with offset
      // Simplified: use UTC offset as placeholder
      // Real implementation would use timezone database
      return _formatIsoWithOffset(utcTime, '+00:00');
    } else if (d == 2) {
      // D=2: ISO client-local with offset
      // Simplified: use UTC offset as placeholder
      // Real implementation would use timezone database
      return _formatIsoWithOffset(utcTime, '+00:00');
    } else if (d == 8) {
      // D=8: epoch milliseconds
      return value;
    }

    throw FormatException('Unsupported D mode: $d');
  }

  // Decode DATETIME based on D mode
  static int _decodeDatetime(dynamic value, int d, String? timezone) {
    if (d == 8) {
      // D=8: epoch milliseconds
      if (value is! int) {
        throw FormatException('Expected int for DATETIME in D=8 mode');
      }
      return value;
    } else {
      // D=0, 1, 2: ISO string
      if (value is! String) {
        throw FormatException('Expected string for DATETIME in D=$d mode');
      }

      // Parse ISO 8601 and normalize to UTC milliseconds
      final dt = DateTime.parse(value);
      return dt.toUtc().millisecondsSinceEpoch;
    }
  }

  // Encode TIME based on D mode
  static dynamic _encodeTime(dynamic value, int d) {
    // Value is milliseconds since midnight (0-86399999)
    if (value is! int) {
      throw FormatException('TIME value must be milliseconds since midnight (int)');
    }

    if (value < 0 || value >= 86400000) {
      throw FormatException('TIME value out of range: $value (valid: 0-86399999)');
    }

    if (d == 8) {
      // D=8: milliseconds since midnight
      return value;
    } else {
      // D=0, 1, 2: HH:mm:ss.SSS
      final hours = value ~/ 3600000;
      final minutes = (value % 3600000) ~/ 60000;
      final seconds = (value % 60000) ~/ 1000;
      final millis = value % 1000;

      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';
    }
  }

  // Decode TIME based on D mode
  static int _decodeTime(dynamic value, int d) {
    if (d == 8) {
      // D=8: milliseconds since midnight
      if (value is! int) {
        throw FormatException('Expected int for TIME in D=8 mode');
      }
      if (value < 0 || value >= 86400000) {
        throw FormatException('TIME value out of range: $value');
      }
      return value;
    } else {
      // D=0, 1, 2: HH:mm:ss.SSS
      if (value is! String) {
        throw FormatException('Expected string for TIME in D=$d mode');
      }

      final match = RegExp(r'^(\d{2}):(\d{2}):(\d{2})\.(\d{3})$').firstMatch(value);
      if (match == null) {
        throw FormatException('Invalid TIME format: $value (expected HH:mm:ss.SSS)');
      }

      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final millis = int.parse(match.group(4)!);

      if (hours >= 24 || minutes >= 60 || seconds >= 60) {
        throw FormatException('TIME components out of range: $value');
      }

      return hours * 3600000 + minutes * 60000 + seconds * 1000 + millis;
    }
  }

  /// Decode rows without rounding raw NUMERIC tokens before applying the schema.
  static List<List<dynamic>> decodeFromJsonString({
    required int encoding,
    required String jsonString,
    required JnldSchema schema,
    String? timezone,
  }) {
    final enc = JnldEncoding.parse(encoding);
    if (!enc.numericAsString) {
      final numericColumns = [
        for (final field in schema.fields)
          DataTypeRegistry.isValidNumeric(field.typeId),
      ];
      if (numericColumns.contains(true)) {
        final numericKeys = enc.isCompact
            ? null
            : {
                for (var i = 0; i < schema.fieldCount; i++)
                  if (numericColumns[i])
                    enc.j == 8 ? schema.fields[i].c : schema.fields[i].n,
              };
        jsonString = _JsonNumericTokens(jsonString).preserve(
          numericColumns,
          numericKeys,
        );
      }
    }
    return decode(
      encoding: encoding,
      body: JnldBody.parse(jsonString),
      schema: schema,
      timezone: timezone,
    );
  }

  // Format ISO 8601 with explicit offset
  static String _formatIsoWithOffset(DateTime dt, String offset) {
    final base = dt.toIso8601String();
    // Remove Z and add offset
    if (base.endsWith('Z')) {
      return base.substring(0, base.length - 1) + offset;
    }
    return base;
  }
}

/// Quotes raw NUMERIC tokens in the top-level data rows. The standard JSON
/// decoder still validates the payload and decodes every other value.
class _JsonNumericTokens {
  _JsonNumericTokens(this._source);

  final String _source;
  final _output = StringBuffer();
  int _offset = 0;
  int _copiedThrough = 0;

  static const _quote = 0x22;
  static const _comma = 0x2c;
  static const _colon = 0x3a;
  static const _arrayStart = 0x5b;
  static const _arrayEnd = 0x5d;
  static const _objectStart = 0x7b;
  static const _objectEnd = 0x7d;

  String preserve(List<bool> numericColumns, Set<String>? numericKeys) {
    _expect(_objectStart);
    if (!_consume(_objectEnd)) {
      do {
        final key = _readKey();
        _expect(_colon);
        if (key == 'data') {
          _readRows(numericColumns, numericKeys);
        } else {
          _skipValue();
        }
      } while (_consume(_comma));
      _expect(_objectEnd);
    }

    if (_copiedThrough == 0) return _source;
    _output.write(_source.substring(_copiedThrough));
    return _output.toString();
  }

  void _readRows(List<bool> numericColumns, Set<String>? numericKeys) {
    _expect(_arrayStart);
    if (_consume(_arrayEnd)) return;

    do {
      if (numericKeys == null) {
        _readCompactRow(numericColumns);
      } else {
        _readObjectRow(numericKeys);
      }
    } while (_consume(_comma));
    _expect(_arrayEnd);
  }

  void _readCompactRow(List<bool> numericColumns) {
    _expect(_arrayStart);
    if (_consume(_arrayEnd)) return;

    var column = 0;
    do {
      _skipValue(
        preserveNumber:
            column < numericColumns.length && numericColumns[column],
      );
      column++;
    } while (_consume(_comma));
    _expect(_arrayEnd);
  }

  void _readObjectRow(Set<String> numericKeys) {
    _expect(_objectStart);
    if (_consume(_objectEnd)) return;

    do {
      final key = _readKey();
      _expect(_colon);
      _skipValue(preserveNumber: numericKeys.contains(key));
    } while (_consume(_comma));
    _expect(_objectEnd);
  }

  String _readKey() {
    _expect(_quote);
    final start = _offset - 1;
    _skipString();
    return json.jsonDecode(_source.substring(start, _offset)) as String;
  }

  void _skipValue({bool preserveNumber = false}) {
    _skipWhitespace();
    final start = _offset;
    final first = _peek;
    if (first == _quote) {
      _offset++;
      _skipString();
      return;
    }
    if (first == _arrayStart || first == _objectStart) {
      _offset++;
      _skipContainer();
      return;
    }

    var char = first;
    while (char != -1 &&
        char != _comma &&
        char != _arrayEnd &&
        char != _objectEnd &&
        !_isWhitespace(char)) {
      _offset++;
      char = _peek;
    }
    if (_offset == start) {
      throw FormatException('Expected JSON value', _source, start);
    }

    if (preserveNumber &&
        _jsonNumber.matchAsPrefix(_source, start)?.end == _offset) {
      _output
        ..write(_source.substring(_copiedThrough, start))
        ..write('"')
        ..write(_source.substring(start, _offset))
        ..write('"');
      _copiedThrough = _offset;
    }
  }

  void _skipContainer() {
    var depth = 1;
    while (_offset < _source.length) {
      switch (_source.codeUnitAt(_offset++)) {
        case _quote:
          _skipString();
        case _arrayStart:
        case _objectStart:
          depth++;
        case _arrayEnd:
        case _objectEnd:
          depth--;
          if (depth == 0) return;
      }
    }
    throw FormatException('Unterminated JSON container', _source, _offset);
  }

  void _skipString() {
    while (_offset < _source.length) {
      final char = _source.codeUnitAt(_offset++);
      if (char == _quote) return;
      if (char == 0x5c) _offset++;
    }
    throw FormatException('Unterminated JSON string', _source);
  }

  bool _consume(int token) {
    _skipWhitespace();
    if (_peek != token) return false;
    _offset++;
    return true;
  }

  void _expect(int token) {
    if (!_consume(token)) {
      throw FormatException(
        "Expected '${String.fromCharCode(token)}'",
        _source,
        _offset,
      );
    }
  }

  int get _peek => _offset < _source.length ? _source.codeUnitAt(_offset) : -1;

  void _skipWhitespace() {
    while (_isWhitespace(_peek)) {
      _offset++;
    }
  }

  static bool _isWhitespace(int char) =>
      char == 0x20 || char == 0x09 || char == 0x0a || char == 0x0d;
}
