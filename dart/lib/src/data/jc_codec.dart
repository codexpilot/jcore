/// Compact format codec (J=1, 2, 3, 4).
library;

import 'jx_body.dart';
import 'jx_encoding.dart';
import 'jx_schema.dart';
import 'numeric_codec.dart';

/// Compact format codec for positional array rows.
///
/// Handles J=1 (data-only), J=2 (with ID metadata), J=3 (with code metadata),
/// and J=4 (with name metadata).
class JcCodec {
  /// Encode rows to compact format
  static JxBody encode({
    required JxEncoding enc,
    required List<List<dynamic>> rows,
    required JxSchema schema,
    String? timezone,
  }) {
    // Validate row lengths match schema
    for (int i = 0; i < rows.length; i++) {
      if (rows[i].length != schema.fieldCount) {
        throw FormatException(
          'Row $i has ${rows[i].length} cells, expected ${schema.fieldCount}',
        );
      }
    }

    List<List<dynamic>>? meta;
    if (enc.hasMetadata) {
      meta = [];
      for (final field in schema.fields) {
        final (key, type) = _metadataEntry(enc.j, field);
        meta.add([key, type]);
      }
    }

    // Encode data rows
    final data = rows.map((row) {
      return List<dynamic>.generate(row.length, (i) {
        return NumericCodec.encodeCell(row[i], schema.fields[i].typeId, enc, timezone);
      });
    }).toList();

    return JxBody(meta: meta, data: data);
  }

  /// Decode compact format to rows
  static List<List<dynamic>> decode({
    required JxEncoding enc,
    required JxBody body,
    required JxSchema schema,
    String? timezone,
  }) {
    final meta = body.meta;
    if (enc.hasMetadata && meta != null) {
      _validateMetadata(enc.j, meta, schema);
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
        return NumericCodec.decodeCell(rowData[i], schema.fields[i].typeId, enc, timezone);
      });
      rows.add(row);
    }

    return rows;
  }

  static (Object, Object) _metadataEntry(int mode, JxField field) =>
      switch (mode) {
        2 => (field.i, field.typeId),
        3 => (field.c, field.typeName),
        4 => (field.n, field.typeName),
        _ => throw StateError('Unexpected JX metadata mode $mode'),
      };

  static void _validateMetadata(
    int mode,
    List<List<dynamic>> meta,
    JxSchema schema,
  ) {
    if (meta.length != schema.fieldCount) {
      throw FormatException(
        'JX meta has ${meta.length} entries, expected ${schema.fieldCount}',
      );
    }
    for (final (index, entry) in meta.indexed) {
      final (key, type) = _metadataEntry(mode, schema.fields[index]);
      if (entry.length != 2) {
        throw FormatException('Expected a key and type at meta[$index]');
      }
      final actualKey = entry[0];
      final actualType = entry[1];
      final hasExpectedTypes = mode == 2
          ? actualKey is int && actualType is int
          : actualKey is String && actualType is String;
      if (!hasExpectedTypes || actualKey != key || actualType != type) {
        throw FormatException('Expected [$key, $type] at meta[$index]');
      }
    }
  }
}
