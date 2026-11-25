/// Numeric codec for precision-preserving type conversion.
library;

import 'dart:convert' as json;
import 'jx_body.dart';
import 'jx_encoding.dart';
import 'jx_schema.dart';
import 'numeric.dart';
import 'data_type_registry.dart';

/// INT64 exact BigInt bounds for validation
/// These are parsed to avoid JavaScript number precision loss.
/// INT64 range: -9223372036854775808 to 9223372036854775807
final _int64MinBigInt = BigInt.parse('-9223372036854775808');
final _int64MaxBigInt = BigInt.parse('9223372036854775807');

final _jsonNumber = RegExp(
  r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
);

/// Numeric codec for type-specific encoding/decoding with precision preservation.
class NumericCodec {
  /// Encode a single cell value based on type and encoding
  static dynamic encodeCell(
    dynamic value,
    int typeId,
    JxEncoding enc,
    String? timezone,
  ) {
    if (value == null) return null;

    // INT64 (3)
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

        // Validate INT64 range using exact BigInt bounds
        if (bigIntValue < _int64MinBigInt || bigIntValue > _int64MaxBigInt) {
          throw RangeError(
            'INT64 value out of range: $bigIntValue '
            '(valid: ${_int64MinBigInt} to ${_int64MaxBigInt})',
          );
        }

        return bigIntValue.toInt();
      }
    }

    // NUMERIC (DataTypeX range: 20000-29999)
    if (DataTypeRegistry.isValidNumeric(typeId)) {
      if (enc.numericAsString) {
        if (value is Numeric) {
          // For scale=0, use scaledValue to avoid trailing dot
          return value.scale == 0
              ? value.scaledValue.toString()
              : value.toString();
        }
        if (value is num) return value.toString();
        if (value is String) {
          // Validate string format: must be valid decimal number
          // No leading zeros (except '0'), no trailing dot, no plus sign
          final validDecimal = RegExp(r'^-?(0|[1-9][0-9]*)(\.[0-9]+)?$');
          if (!validDecimal.hasMatch(value)) {
            throw FormatException('Invalid NUMERIC format: $value');
          }
          // Parse and normalize
          final numeric = Numeric.parse(value);
          return numeric.scale == 0
              ? numeric.scaledValue.toString()
              : numeric.toString();
        }
      } else {
        if (value is Numeric) {
          final token = value.scale == 0
              ? value.scaledValue.toString()
              : value.toString();
          return RawJsonNumber(token);
        }
        if (value is num) return value;
        if (value is String) return RawJsonNumber.fromString(value);
      }
    }

    // DATETIME (4)
    if (typeId == DataType.datetime.id) {
      return encodeDatetime(value, enc.d, timezone);
    }

    // TIME (5)
    if (typeId == DataType.time.id) {
      return encodeTime(value, enc.d);
    }

    // Default: pass through
    return value;
  }

  /// Decode a single cell value based on type and encoding
  static dynamic decodeCell(
    dynamic value,
    int typeId,
    JxEncoding enc,
    String? timezone,
  ) {
    if (value == null) return null;

    // INT64 (3)
    if (typeId == DataType.int64.id) {
      if (enc.int64AsString) {
        if (value is String) return BigInt.parse(value);
        if (value is int) return BigInt.from(value);
      } else {
        // L=1: INT64 as unquoted integers
        // On platforms like Flutter Web, the token extraction quotes large
        // integers as strings to prevent JavaScript rounding. Parse to BigInt,
        // then convert to int if it fits safely in the platform's int range.
        if (value is String) {
          final bigInt = BigInt.parse(value);
          return bigInt.isValidInt ? bigInt.toInt() : bigInt;
        }
        if (value is int) return value;
      }
    }

    // NUMERIC (base 20000 and parameterized 20100-29999)
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

    // DATETIME (4)
    if (typeId == DataType.datetime.id) {
      return decodeDatetime(value, enc.d, timezone);
    }

    // TIME (5)
    if (typeId == DataType.time.id) {
      return decodeTime(value, enc.d);
    }

    // Default: pass through
    return value;
  }

  /// Encode DATETIME based on D mode
  static dynamic encodeDatetime(dynamic value, int d, String? timezone) {
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
      return formatIsoWithOffset(utcTime, '+00:00');
    } else if (d == 2) {
      // D=2: ISO client-local with offset
      // Simplified: use UTC offset as placeholder
      // Real implementation would use timezone database
      return formatIsoWithOffset(utcTime, '+00:00');
    } else if (d == 8) {
      // D=8: epoch milliseconds
      return value;
    }

    throw FormatException('Unsupported D mode: $d');
  }

  /// Decode DATETIME based on D mode
  static int decodeDatetime(dynamic value, int d, String? timezone) {
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

  /// Encode TIME based on D mode
  static dynamic encodeTime(dynamic value, int d) {
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

  /// Decode TIME based on D mode
  static int decodeTime(dynamic value, int d) {
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

  /// Format ISO 8601 with explicit offset
  static String formatIsoWithOffset(DateTime dt, String offset) {
    final base = dt.toIso8601String();
    // Remove Z and add offset
    if (base.endsWith('Z')) {
      return base.substring(0, base.length - 1) + offset;
    }
    return base;
  }

  /// Decode rows without rounding raw NUMERIC tokens before applying the schema.
  ///
  /// This method preserves exact NUMERIC precision by extracting raw number tokens
  /// from the JSON string before Dart's jsonDecode converts them to doubles.
  /// On Flutter Web, it also preserves INT64 values to prevent JavaScript rounding.
  static List<List<dynamic>> decodeFromJsonString({
    required int encoding,
    required String jsonString,
    required JxSchema schema,
    String? timezone,
    required List<List<dynamic>> Function({
      required int encoding,
      required JxBody body,
      required JxSchema schema,
      String? timezone,
    }) decoder,
  }) {
    final enc = JxEncoding.parse(encoding);

    // For N=1 (NUMERIC as unquoted numbers), preserve NUMERIC tokens
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
        jsonString = JsonNumericTokens(jsonString).preserve(
          numericColumns,
          numericKeys,
        );
      }
    }

    // For L=1 (INT64 as unquoted integers), preserve INT64 tokens on platforms
    // where JSON.parse() might round large integers (e.g., Flutter Web)
    if (!enc.int64AsString) {
      final int64Columns = [
        for (final field in schema.fields)
          field.typeId == DataType.int64.id,
      ];
      if (int64Columns.contains(true)) {
        final int64Keys = enc.isCompact
            ? null
            : {
                for (var i = 0; i < schema.fieldCount; i++)
                  if (int64Columns[i])
                    enc.j == 8 ? schema.fields[i].c : schema.fields[i].n,
              };
        jsonString = JsonNumericTokens(jsonString).preserve(
          int64Columns,
          int64Keys,
        );
      }
    }

    return decoder(
      encoding: encoding,
      body: JxBody.parse(jsonString),
      schema: schema,
      timezone: timezone,
    );
  }
}

/// Quotes raw NUMERIC tokens in the top-level data rows. The standard JSON
/// decoder still validates the payload and decodes every other value.
class JsonNumericTokens {
  JsonNumericTokens(this._source);

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
