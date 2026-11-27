/// JX response body structure with custom JSON encoding.
library;

import 'dart:convert' as json;

/// Wrapper for NUMERIC values that should be encoded as raw JSON numbers.
/// Used for N=1 mode to preserve exact decimal representation.
class RawJsonNumber {
  final String value;
  const RawJsonNumber(this.value);

  factory RawJsonNumber.fromString(String value) {
    final jsonNumber = RegExp(
      r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
    );
    if (jsonNumber.matchAsPrefix(value)?.end != value.length) {
      throw FormatException('Invalid JSON number', value);
    }
    return RawJsonNumber(value);
  }
}

/// JX response body structure.
///
/// Contains data rows and optional metadata for compact encodings.
class JxBody {
  /// Ordered metadata entries (J=2, 3, 4 only)
  /// Each entry is [key, type] where key and type formats depend on J.
  final List<List<dynamic>>? meta;

  /// Data rows - either positional arrays or full objects
  final List<dynamic> data;

  const JxBody({this.meta, required this.data});

  /// Parse and validate a decoded JSON body.
  ///
  /// An explicit null [meta] is treated like omitted metadata.
  factory JxBody.fromJson(Object? value) => _fromJson(value, copyLists: true);

  static JxBody _fromJson(Object? value, {required bool copyLists}) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JX response object');
    }

    final data = value['data'];
    if (data is! List) {
      throw const FormatException('Expected a data array in the JX response');
    }

    List<List<dynamic>>? meta;
    final rawMeta = value['meta'];
    if (rawMeta != null) {
      if (rawMeta is! List) {
        throw const FormatException('Expected a meta array in the JX response');
      }
      meta = [
        for (final (index, entry) in rawMeta.indexed)
          if (entry is List)
            copyLists ? List<dynamic>.of(entry) : entry
          else
            throw FormatException('Expected an array at meta[$index]'),
      ];
    }

    return JxBody(
      meta: meta,
      data: copyLists ? List<dynamic>.of(data) : data,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'data': data};
    if (meta != null) {
      result['meta'] = meta;
    }
    return result;
  }

  /// Parse a JSON body from its wire representation.
  static JxBody parse(String jsonString) =>
      _fromJson(json.jsonDecode(jsonString), copyLists: false);

  /// Encode to JSON string
  String encode({bool pretty = false}) {
    final jsonMap = toJson();

    // Check if data contains RawJsonNumber instances (N=1 NUMERIC)
    if (_hasRawJsonNumbers(jsonMap['data'])) {
      return _encodeWithRawNumbers(jsonMap, pretty);
    }

    if (pretty) {
      return json.JsonEncoder.withIndent('  ').convert(jsonMap);
    }
    return json.jsonEncode(jsonMap);
  }

  // Check if data structure contains RawJsonNumber instances
  static bool _hasRawJsonNumbers(dynamic data) {
    if (data is List) {
      for (final item in data) {
        if (item is RawJsonNumber) return true;
        if (_hasRawJsonNumbers(item)) return true;
      }
    } else if (data is Map) {
      for (final value in data.values) {
        if (value is RawJsonNumber) return true;
        if (_hasRawJsonNumbers(value)) return true;
      }
    }
    return false;
  }

  // Custom JSON encoding that writes RawJsonNumber as unquoted numbers
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
    } else if (value is RawJsonNumber) {
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
