/// Generic editable JSON representation of one ModelX record.
///
/// RecordX provides a clean editing interface for composed and non-composed
/// models. It carries the model ID, record identity when available, and
/// schema version. Editing a RecordX leaves the cached row untouched until
/// a save succeeds.
library;

import 'jx_row.dart';

/// Editable record representation for MJUX.
///
/// Usage:
/// ```dart
/// // Load and open for editing
/// final record = await DbContext.instance.fetchRecord(modelId: 500, recordId: 1);
/// final editable = DbContext.instance.openForEdit(record);
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

  /// Schema version (for optimistic concurrency)
  final int schemaVersion;

  /// Original cached row (immutable)
  final JxRow? _cachedRow;

  /// Pending field edits (null means no change, explicit value means change)
  final Map<String, dynamic> _fieldEdits = {};

  /// Pending section edits
  final Map<String, _SectionEdit> _sectionEdits = {};

  /// Track if this record has been modified
  bool _isDirty = false;

  RecordX({
    required this.modelId,
    this.recordId,
    required this.schemaVersion,
    this._cachedRow,
  });

  /// Check if record has unsaved changes
  bool get isDirty => _isDirty;

  /// Get field value (returns edited value if changed, otherwise cached value)
  dynamic getField(String fieldName) {
    if (_fieldEdits.containsKey(fieldName)) {
      return _fieldEdits[fieldName];
    }
    return _cachedRow?[fieldName];
  }

  /// Set field value (null clears nullable field)
  void setField(String fieldName, dynamic value) {
    _fieldEdits[fieldName] = value;
    _isDirty = true;
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
    _sectionEdits[sectionKey] = _SectionEdit.replace(rows);
    _isDirty = true;
  }

  /// Update a specific section row by stable ID
  void setSectionRowById(String sectionKey, dynamic id, Map<String, dynamic> row) {
    final edit = _sectionEdits.putIfAbsent(
      sectionKey,
      () => _SectionEdit.incremental(getSectionRows(sectionKey)),
    );
    edit.updateRowById(id, row);
    _isDirty = true;
  }

  /// Update a specific section row by index (finds stable ID first)
  void setSectionRow(String sectionKey, int index, Map<String, dynamic> row) {
    final currentRows = getSectionRows(sectionKey);
    if (index >= 0 && index < currentRows.length) {
      final id = _extractRowId(currentRows[index]);
      setSectionRowById(sectionKey, id, row);
    }
  }

  /// Add a new row to a section (assigns temporary ID)
  void addSectionRow(String sectionKey, Map<String, dynamic> row) {
    final edit = _sectionEdits.putIfAbsent(
      sectionKey,
      () => _SectionEdit.incremental(getSectionRows(sectionKey)),
    );
    edit.addRow(row);
    _isDirty = true;
  }

  /// Remove a row from a section by index (finds stable ID first)
  void removeSectionRow(String sectionKey, int index) {
    final currentRows = getSectionRows(sectionKey);
    if (index >= 0 && index < currentRows.length) {
      final id = _extractRowId(currentRows[index]);
      removeSectionRowById(sectionKey, id);
    }
  }

  /// Remove a row from a section by stable ID
  void removeSectionRowById(String sectionKey, dynamic id) {
    final edit = _sectionEdits.putIfAbsent(
      sectionKey,
      () => _SectionEdit.incremental(getSectionRows(sectionKey)),
    );
    edit.removeRowById(id);
    _isDirty = true;
  }

  /// Extract stable ID from a row (looks for common ID fields)
  dynamic _extractRowId(Map<String, dynamic> row) {
    // Try common ID field names
    for (final key in ['line_id', 'payment_id', 'id', 'i']) {
      if (row.containsKey(key)) {
        return row[key];
      }
    }
    // Fall back to row hashcode if no ID field found
    return row.hashCode;
  }

  /// Export to JSON for save operation
  ///
  /// Returns a map with:
  /// - i: record ID (0 for new records)
  /// - v: schema version
  /// - edited field keys and values
  /// - section keys with their edited rows
  /// - _removed_{sectionKey}: array of removed row IDs
  ///
  /// Omitted fields mean no change, explicit null clears nullable field.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'i': recordId ?? 0,
      'v': schemaVersion,
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

/// Internal class for tracking section edits with stable IDs
class _SectionEdit {
  final Map<dynamic, Map<String, dynamic>> _rowsById = {};
  final Set<dynamic> _removedIds = {};
  final List<dynamic> _insertionOrder = [];
  int _tempIdCounter = -1;

  _SectionEdit.replace(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final id = _extractId(row);
      _rowsById[id] = Map.from(row);
      _insertionOrder.add(id);
    }
  }

  _SectionEdit.incremental(List<Map<String, dynamic>> initialRows) {
    for (final row in initialRows) {
      final id = _extractId(row);
      _rowsById[id] = Map.from(row);
      _insertionOrder.add(id);
    }
  }

  dynamic _extractId(Map<String, dynamic> row) {
    // Try common ID field names
    for (final key in ['line_id', 'payment_id', 'id', 'i']) {
      if (row.containsKey(key)) {
        return row[key];
      }
    }
    // Assign temporary ID for new rows without ID
    return _tempIdCounter--;
  }

  void updateRowById(dynamic id, Map<String, dynamic> row) {
    if (_rowsById.containsKey(id) && !_removedIds.contains(id)) {
      _rowsById[id] = Map.from(row);
    }
  }

  void addRow(Map<String, dynamic> row) {
    final id = _extractId(row);
    // If no ID in row, ensure temporary ID is added
    if (!row.containsKey('line_id') &&
        !row.containsKey('payment_id') &&
        !row.containsKey('id') &&
        !row.containsKey('i')) {
      row = Map.from(row);
      row['_temp_id'] = id;
    }
    _rowsById[id] = row;
    _insertionOrder.add(id);
  }

  void removeRowById(dynamic id) {
    if (_rowsById.containsKey(id)) {
      _removedIds.add(id);
    }
  }

  List<Map<String, dynamic>> getRows() {
    return [
      for (final id in _insertionOrder)
        if (!_removedIds.contains(id) && _rowsById.containsKey(id))
          _rowsById[id]!
    ];
  }

  List<dynamic> getRemovedIds() {
    return _removedIds.where((id) => id is! int || id >= 0).toList();
  }
}
