/// Generic editable JSON representation of one ModelX record.
///
/// RecordX provides a clean editing interface for composed and non-composed
/// models. It carries the model ID, record identity when available, and
/// the schema revision and record version separately. Editing a RecordX
/// leaves the cached row untouched.
library;

import 'jx_row.dart';

/// Editable record representation for MJUX.
///
/// Usage:
/// ```dart
/// // Load and open for editing
/// final record = await DbContext.instance.fetchRecord(modelId: 500, recordId: 1);
/// final editable = DbContext.instance.openForEdit(
///   record,
///   modelId: 500,
///   recordId: 1,
/// );
///
/// // Edit fields
/// editable.setField('customer_name', 'New Customer');
/// editable.setField('total_amount', '2500.00');
///
/// // Edit sections
/// editable.setSectionRow('invoiceDetails', 0, {
///   'product_name': 'Updated Product',
///   'quantity': 20,
/// });
///
/// // Add new section row
/// editable.addSectionRow('invoiceDetails', {
///   'line_id': 3,
///   'product_name': 'New Product',
///   'quantity': 5,
/// });
///
/// // Remove section row
/// editable.removeSectionRow('invoiceDetails', 1);
///
/// // Save changes
/// final saved = await DbContext.instance.saveChanges(editable);
/// ```
class RecordX {
  /// Model ID this record belongs to
  final int modelId;

  /// Record ID (null for new records)
  final int? recordId;

  /// Version of the schema used by this draft.
  final int schemaVersion;

  /// Version of the persisted record for optimistic concurrency.
  final int? recordVersion;

  /// Original cached row (immutable)
  final JxRow? _cachedRow;

  /// Wire ID code for each section that declares one.
  final Map<String, String> _sectionIdentityCodes;

  /// Pending field edits, including explicit nulls, keyed by wire code.
  final Map<String, dynamic> _fieldEdits = {};

  /// Pending section edits
  final Map<String, _SectionEdit> _sectionEdits = {};

  /// Track if this record has been modified
  bool _isDirty = false;

  RecordX({
    required this.modelId,
    this.recordId,
    required this.schemaVersion,
    this.recordVersion,
    this._cachedRow,
    Map<String, String> sectionIdentityCodes = const {},
  }) : _sectionIdentityCodes = Map.unmodifiable(sectionIdentityCodes);

  /// Check if record has unsaved changes
  bool get isDirty => _isDirty;

  /// Get a field by its wire code or unambiguous display name.
  dynamic getField(String fieldName) {
    final row = _cachedRow;
    final index = _fieldIndex(fieldName);
    final code = index == null ? fieldName : row!.schema.fields[index].c;
    if (_fieldEdits.containsKey(code)) {
      return _fieldEdits[code];
    }
    if (row == null) return null;
    if (index == null) {
      throw ArgumentError.value(fieldName, 'fieldName', 'Unknown field');
    }
    return row.getAt(index);
  }

  /// Set a field by its wire code or unambiguous display name.
  /// An explicit null clears a nullable field.
  void setField(String fieldName, dynamic value) {
    _validateEditKey(fieldName);
    final index = _fieldIndex(fieldName);
    final code = index == null ? fieldName : _cachedRow!.schema.fields[index].c;
    if (code != fieldName) _validateEditKey(code);
    _fieldEdits[code] = value;
    _isDirty = true;
  }

  int? _fieldIndex(String key) {
    final schema = _cachedRow?.schema;
    return schema?.indexByCode(key) ?? schema?.indexByName(key);
  }

  /// Get section rows (returns edited rows if changed, otherwise cached rows)
  List<Map<String, dynamic>> getSectionRows(String sectionKey) {
    final edit = _sectionEdits[sectionKey];
    if (edit != null) {
      return edit.getRows();
    }

    // Return cached rows if no edits
    if (_cachedRow is JxComposedRow) {
      final section = _cachedRow.sections[sectionKey];
      if (section is JxOneSection) {
        return section.row != null ? [section.row!.toMap()] : [];
      } else if (section is JxManySection) {
        return section.rows.map((r) => r.toMap()).toList();
      }
    }
    return [];
  }

  /// Set entire section rows (replaces all rows)
  void setSectionRows(String sectionKey, List<Map<String, dynamic>> rows) {
    _validateEditKey(sectionKey);
    _sectionEdits[sectionKey] = _SectionEdit(
      rows,
      identityCode: _sectionIdentityCodes[sectionKey],
    );
    _isDirty = true;
  }

  /// Update a specific section row by stable ID
  void setSectionRowById(
    String sectionKey,
    dynamic id,
    Map<String, dynamic> row,
  ) {
    _editSection(sectionKey, (edit) => edit.updateRowById(id, row));
  }

  /// Update a specific section row by index.
  void setSectionRow(String sectionKey, int index, Map<String, dynamic> row) {
    _editSection(
      sectionKey,
      (edit) => edit.updateRowById(edit.idAt(index), row),
    );
  }

  /// Add a new row to a section (assigns an internal ID when needed).
  void addSectionRow(String sectionKey, Map<String, dynamic> row) {
    _editSection(sectionKey, (edit) => edit.addRow(row));
  }

  /// Remove a row from a section by index.
  void removeSectionRow(String sectionKey, int index) {
    _editSection(sectionKey, (edit) => edit.removeRowById(edit.idAt(index)));
  }

  /// Remove a row from a section by stable ID
  void removeSectionRowById(String sectionKey, dynamic id) {
    _editSection(sectionKey, (edit) => edit.removeRowById(id));
  }

  void _editSection(String key, bool Function(_SectionEdit) apply) {
    _validateEditKey(key);
    final edit =
        _sectionEdits[key] ??
        _SectionEdit(
          getSectionRows(key),
          identityCode: _sectionIdentityCodes[key],
        );
    if (apply(edit)) {
      _sectionEdits[key] = edit;
      _isDirty = true;
    }
  }

  void _validateEditKey(String key) {
    if (key == 'i' || key == 'v' || key.startsWith('_removed_')) {
      throw ArgumentError.value(key, 'key', 'Reserved record control key');
    }
  }

  /// Export to JSON for save operation
  ///
  /// Returns a map with:
  /// - i: record ID (0 for new records)
  /// - v: record version, when available
  /// - edited field keys and values
  /// - section keys with their edited rows
  /// - _removed_{sectionKey}: array of removed row IDs
  ///
  /// Omitted fields mean no change, explicit null clears nullable field.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'i': recordId ?? 0,
      if (recordVersion != null) 'v': recordVersion,
    };

    // Add edited fields
    _fieldEdits.forEach((key, value) {
      json[key] = value;
    });

    // Add edited sections with removed IDs
    _sectionEdits.forEach((key, edit) {
      json[key] = edit.getRows();
      final removed = edit.getRemovedIds();
      if (removed.isNotEmpty) {
        json['_removed_$key'] = removed;
      }
    });

    return json;
  }

  /// Get the original cached row (immutable)
  JxRow? get cachedRow => _cachedRow;

  /// Reset all edits (clear dirty state)
  void reset() {
    _fieldEdits.clear();
    _sectionEdits.clear();
    _isDirty = false;
  }
}

/// Track visible rows in insertion order and persisted IDs removed by the draft.
class _SectionEdit {
  static const _legacyIdentityCodes = ['line_id', 'payment_id', 'id', 'i'];

  final String? identityCode;
  final _rowsById = <Object, Map<String, dynamic>>{};
  final _persistedIds = <Object>{};
  final _removedIds = <Object>{};

  _SectionEdit(
    List<Map<String, dynamic>> initialRows, {
    required this.identityCode,
  }) {
    for (final row in initialRows) {
      final id = _explicitId(row);
      _insertRow(id ?? Object(), row);
      if (id != null) _persistedIds.add(id);
    }
  }

  String? _identityCodeIn(Map<String, dynamic> row) {
    if (identityCode != null) return identityCode;
    for (final code in _legacyIdentityCodes) {
      if (row.containsKey(code)) return code;
    }
    return null;
  }

  Object? _explicitId(Map<String, dynamic> row) {
    final id = row[_identityCodeIn(row)];
    return switch (id) {
      int value when value > 0 => value,
      String value when value.isNotEmpty && value != '0' => value,
      _ => null,
    };
  }

  void _insertRow(Object id, Map<String, dynamic> row) {
    if (_rowsById.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Duplicate section row ID');
    }
    _rowsById[id] = Map.of(row);
  }

  Object? idAt(int index) => index >= 0 && index < _rowsById.length
      ? _rowsById.keys.elementAt(index)
      : null;

  bool updateRowById(Object? id, Map<String, dynamic> row) {
    if (id == null) return false;
    final current = _rowsById[id];
    if (current == null) return false;

    final updated = Map.of(row);
    final code = _identityCodeIn(current);
    if (code != null && current.containsKey(code)) {
      final identity = current[code];
      if (updated.containsKey(code) && updated[code] != identity) {
        throw ArgumentError.value(
          updated[code],
          code,
          'Cannot change a section row ID',
        );
      }
      updated[code] = identity;
    }
    _rowsById[id] = updated;
    return true;
  }

  bool addRow(Map<String, dynamic> row) {
    final id = _explicitId(row) ?? Object();
    _insertRow(id, row);
    _removedIds.remove(id);
    return true;
  }

  bool removeRowById(Object? id) {
    if (id == null || _rowsById.remove(id) == null) return false;
    if (_persistedIds.contains(id)) _removedIds.add(id);
    return true;
  }

  List<Map<String, dynamic>> getRows() {
    return [for (final row in _rowsById.values) Map.of(row)];
  }

  List<Object> getRemovedIds() => _removedIds.toList();
}
