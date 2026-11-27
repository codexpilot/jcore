/// Full objects format codec (J=8, 9).
library;

import 'jx_body.dart';
import 'jx_encoding.dart';
import 'jx_schema.dart';
import 'numeric_codec.dart';

/// Full objects format codec for object rows.
///
/// Handles J=8 (objects keyed by field code) and J=9 (objects keyed by field name).
class JfCodec {
  /// Encode rows to full objects format
  static JxBody encode({
    required JxEncoding enc,
    required List<List<dynamic>> rows,
    required JxSchema schema,
    String? timezone,
  }) {
    final data = rows.map((row) {
      final obj = <String, dynamic>{};
      for (int i = 0; i < row.length && i < schema.fieldCount; i++) {
        final key = enc.j == 8 ? schema.fields[i].c : schema.fields[i].n;
        obj[key] = NumericCodec.encodeCell(row[i], schema.fields[i].typeId, enc, timezone);
      }
      return obj;
    }).toList();

    return JxBody(data: data);
  }

  /// Decode full objects format to rows
  static List<List<dynamic>> decode({
    required JxEncoding enc,
    required JxBody body,
    required JxSchema schema,
    String? timezone,
  }) {
    final rows = <List<dynamic>>[];
    for (final rowData in body.data) {
      if (rowData is! Map<String, Object?>) {
        throw FormatException(
          'Expected object for full row, got: ${rowData.runtimeType}',
        );
      }
      final row = List<dynamic>.generate(schema.fieldCount, (i) {
        final key = enc.j == 8 ? schema.fields[i].c : schema.fields[i].n;
        final value = rowData[key];
        return NumericCodec.decodeCell(value, schema.fields[i].typeId, enc, timezone);
      });
      rows.add(row);
    }

    return rows;
  }
}
