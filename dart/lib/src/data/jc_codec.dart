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
}
