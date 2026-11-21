import 'view_model.dart';

/// Generic inspection ViewModel for JUX framework - read-only detail views.
///
/// ## JUX Framework Integration
///
/// This ViewModel is part of JCore's JUX (UI/UX framework) and handles
/// inspection (detail) views for ANY model defined through metadata.
/// Inspection views are read-only displays of a single record.
///
/// Uses metadata from JCore structure:
/// - **JUX**: View definition (field layout, query get binding)
/// - **MetaX**: Model schema (ModelX, ColumnX)
/// - **Data**: Data operations (QueryX bindings)
///
/// ## Differences from JuxFormViewModel
///
/// - **Read-only**: No editing, validation, or saving
/// - **Simpler state**: Just loaded record, no draft/dirty tracking
/// - **Lighter weight**: Fewer operations and less memory
///
/// ## Example Usage
///
/// ```dart
/// // Works for customer, sales_order, or ANY model
/// final viewModel = JuxInspectionViewModel(
///   queryService: queryService,
///   jux: await juxRegistry.getView('customer_inspection'),
///   model: await metaRegistry.getModel('customer'),
///   columns: await metaRegistry.getColumns('customer'),
/// );
///
/// // Load specific record
/// await viewModel.load(recordId: 123);
///
/// // Get formatted values for display
/// final name = viewModel.getDisplayValue('name');
/// final email = viewModel.getDisplayValue('email');
/// final createdDate = viewModel.getDisplayValue('created_date');
/// ```
class JuxInspectionViewModel extends ViewModel {
  // Dependencies
  final Map<String, dynamic> _jux; // JUX view definition
  final Map<String, Map<String, dynamic>> _columnMap; // MetaX columns

  // State
  Map<String, dynamic>? _record;
  int? _recordId;

  /// Loaded record data.
  ///
  /// Returns a copy to prevent external modification.
  /// Null until [load] is called successfully.
  Map<String, dynamic>? get record => _record != null ? Map.from(_record!) : null;

  /// ID of the loaded record.
  int? get recordId => _recordId;

  /// Whether a record is loaded.
  bool get hasData => _record != null;

  /// Creates a JUX inspection ViewModel.
  ///
  /// Parameters:
  /// - [queryService]: Service for executing data operations
  /// - [jux]: JUX view definition containing query get binding
  /// - [model]: MetaX model schema
  /// - [columns]: List of MetaX column definitions for display formatting
  JuxInspectionViewModel({
    required this._jux,
    required List<Map<String, dynamic>> columns,
  }) : _columnMap = {for (var col in columns) col['c'] as String: col};

  @override
  Future<void> load({int? recordId}) async {
    if (recordId == null) {
      setError('Record ID required for inspection view');
      return;
    }

    // Get query ID from JUX definition
    final getQueryId = _jux['get_qxi'] as int?;
    if (getQueryId == null) {
      setError('No get query configured in JUX definition');
      return;
    }

    _recordId = recordId;
    setLoading(true);
    setError(null);

    try {
      // Execute query to load record
      // TODO: Replace with actual QueryService call
      final result = <String, dynamic>{
        'i': recordId,
      };

      _record = result;
    } catch (e) {
      setError('Failed to load record: $e');
      _record = null;
    } finally {
      setLoading(false);
    }
  }

  /// Reload the current record.
  Future<void> reload() async {
    if (_recordId != null) {
      await load(recordId: _recordId);
    }
  }

  /// Get formatted display value for a field.
  ///
  /// Uses MetaX column metadata to format values appropriately for their data type.
  String getDisplayValue(String fieldCode) {
    if (_record == null) return '';

    final value = _record![fieldCode];
    if (value == null) return '';

    // Get column metadata from MetaX for formatting
    final column = _columnMap[fieldCode];
    if (column == null) return value.toString();

    // Format based on data type
    final dataTypeId = column['dti'] as int;
    return _formatValue(value, dataTypeId);
  }

  /// Format value based on JCore DataType catalog.
  String _formatValue(dynamic value, int dataTypeId) {
    switch (dataTypeId) {
      case 1: // INT
        return value.toString();

      case 2: // TEXT
        return value.toString();

      case 3: // BOOLEAN
        return value == true ? 'Yes' : 'No';

      case 5: // TIMESTAMP (epoch ms)
        if (value is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(value);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        }
        return value.toString();

      case 6: // DECIMAL
        if (value is num) {
          return value.toStringAsFixed(2);
        }
        return value.toString();

      default:
        return value.toString();
    }
  }

  /// Get the field value in its raw form.
  dynamic getRawValue(String fieldCode) {
    return _record?[fieldCode];
  }

  /// Check if a field exists in the loaded record.
  bool hasField(String fieldCode) {
    return _record?.containsKey(fieldCode) ?? false;
  }

  /// Get field label from MetaX column metadata.
  String getFieldLabel(String fieldCode) {
    final column = _columnMap[fieldCode];
    return column?['n'] as String? ?? fieldCode;
  }

  /// Get data type name for a field.
  String getDataTypeName(String fieldCode) {
    final column = _columnMap[fieldCode];
    if (column == null) return 'unknown';

    final dataTypeId = column['dti'] as int;
    switch (dataTypeId) {
      case 1:
        return 'integer';
      case 2:
        return 'text';
      case 3:
        return 'boolean';
      case 5:
        return 'timestamp';
      case 6:
        return 'decimal';
      default:
        return 'unknown';
    }
  }

  /// Clear loaded record data.
  void clear() {
    _record = null;
    _recordId = null;
    clearError();
    notifyListeners();
  }
}
