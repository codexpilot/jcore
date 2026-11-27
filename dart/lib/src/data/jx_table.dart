import 'dart:collection';

import 'jx_codec.dart';
import 'jx_schema.dart';

/// A JX result stored as positional rows sharing one ordered schema.
class JxTable {
  /// The metadata that determines each column's position.
  final JxSchema schema;

  final List<List<dynamic>> _rows;

  JxTable._(this.schema, this._rows);

  /// Decodes a JX JSON body using the exact result schema.
  ///
  /// Throws [FormatException] when the body or a row has an invalid shape.
  factory JxTable.fromJson({
    required String body,
    required int encoding,
    required JxSchema schema,
    String? timezone,
  }) {
    final rows = JxCodec.decodeFromJsonString(
      encoding: encoding,
      jsonString: body,
      schema: schema,
      timezone: timezone,
    );
    return JxTable._(schema, rows);
  }

  /// Read-only positional rows. The view wraps each row on access.
  late final List<List<Object?>> rows = UnmodifiableListView(
    _rows.map((row) => UnmodifiableListView<Object?>(row)),
  );

  /// The number of decoded rows.
  int get rowCount => _rows.length;

  /// Read a cell by zero-based row and column offsets.
  Object? cellAt(int rowIndex, int columnIndex) => _rows[rowIndex][columnIndex];

  /// Read a cell by its FieldX or ColumnX metadata ID.
  ///
  /// Returns null for an unknown field or null value, and throws
  /// [ArgumentError] if the ID matches multiple fields.
  Object? byId(int rowIndex, int id) =>
      _valueAt(rowIndex, schema.indexById(id));

  /// Read a cell by its exact field code.
  ///
  /// Returns null for an unknown field or null value, and throws
  /// [ArgumentError] if the code matches multiple fields.
  Object? byCode(int rowIndex, String code) =>
      _valueAt(rowIndex, schema.indexByCode(code));

  /// Read a cell by its exact field display name.
  ///
  /// Returns null for an unknown field or null value, and throws
  /// [ArgumentError] if the name matches multiple fields.
  Object? byName(int rowIndex, String name) =>
      _valueAt(rowIndex, schema.indexByName(name));

  Object? _valueAt(int rowIndex, int? columnIndex) {
    final row = _rows[rowIndex];
    return columnIndex == null ? null : row[columnIndex];
  }
}
