/// JX codec - Main API for query result encoding/decoding.
library;

import 'jx_body.dart';
import 'jx_encoding.dart';
import 'jx_schema.dart';
import 'jc_codec.dart';
import 'jf_codec.dart';
import 'numeric_codec.dart';

/// JX codec for encoding/decoding query result bodies.
///
/// Provides transport-independent conversion between typed rows and JX bodies.
class JxCodec {
  /// Encode rows to a JX body.
  ///
  /// Parameters:
  /// - [encoding]: Four-digit JX encoding (default 8000)
  /// - [rows]: Data rows as positional arrays
  /// - [schema]: Field metadata (required)
  /// - [timezone]: Timezone for D=1, D=2 (e.g., "America/New_York")
  ///
  /// Returns a [JxBody] with data and optional metadata.
  static JxBody encode({
    int encoding = 8000,
    required List<List<dynamic>> rows,
    required JxSchema schema,
    String? timezone,
  }) {
    final enc = JxEncoding.parse(encoding);

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

    // Route to appropriate codec
    if (enc.isCompact) {
      return JcCodec.encode(enc: enc, rows: rows, schema: schema, timezone: timezone);
    } else {
      return JfCodec.encode(enc: enc, rows: rows, schema: schema, timezone: timezone);
    }
  }

  /// Decode a JX body to rows.
  ///
  /// Parameters:
  /// - [encoding]: Four-digit JX encoding
  /// - [body]: JX body to decode
  /// - [schema]: Field metadata (required for J=1, optional for others)
  /// - [timezone]: Timezone for D=1, D=2
  ///
  /// Returns decoded rows as positional arrays.
  static List<List<dynamic>> decode({
    required int encoding,
    required JxBody body,
    JxSchema? schema,
    String? timezone,
  }) {
    final enc = JxEncoding.parse(encoding);

    // J=1 requires schema
    if (enc.j == 1 && schema == null) {
      throw ArgumentError('Schema required for J=1 (data-only compact)');
    }

    // Schema required for all decoding
    if (schema == null) {
      throw ArgumentError('Schema required for decoding');
    }

    // Route to appropriate codec
    if (enc.isCompact) {
      return JcCodec.decode(enc: enc, body: body, schema: schema, timezone: timezone);
    } else {
      return JfCodec.decode(enc: enc, body: body, schema: schema, timezone: timezone);
    }
  }

  /// Decode rows without rounding raw NUMERIC tokens before applying the schema.
  ///
  /// This method preserves exact NUMERIC precision by extracting raw number tokens
  /// from the JSON string before Dart's jsonDecode converts them to doubles.
  ///
  /// Use this instead of `decode(body: JxBody.parse(jsonString))` when you need
  /// to preserve trailing zeros and exact decimal values in NUMERIC columns.
  static List<List<dynamic>> decodeFromJsonString({
    required int encoding,
    required String jsonString,
    required JxSchema schema,
    String? timezone,
  }) {
    return NumericCodec.decodeFromJsonString(
      encoding: encoding,
      jsonString: jsonString,
      schema: schema,
      timezone: timezone,
      decoder: decode,
    );
  }
}
