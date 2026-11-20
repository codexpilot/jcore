import 'package:flutter/foundation.dart';
import '../jdata/query_service.dart';
import 'view_model.dart';

/// Generic collection ViewModel for JUX framework - works with any dynamic schema.
///
/// ## JUX Framework Integration
///
/// This ViewModel is part of JCore's JUX (UI/UX framework) and handles
/// collection (list) views for ANY model defined through metadata.
///
/// Uses metadata from JCore structure:
/// - **JUX**: View definition (column display, query list binding)
/// - **MetaX**: Model schema (ModelX, ColumnX)
/// - **JData**: Data operations (QueryX bindings)
///
/// ## Features
///
/// - Load paginated data from query operations
/// - Search across records
/// - Filter by field values
/// - Select records for navigation to detail views
/// - Format display values based on data type metadata
///
/// ## Example Usage
///
/// ```dart
/// // Works for customer, sales_order, or ANY model
/// final viewModel = JuxCollectionViewModel(
///   queryService: queryService,
///   jux: await juxRegistry.getView('customer_list'),
///   model: await metaRegistry.getModel('customer'),
///   columns: await metaRegistry.getColumns('customer'),
/// );
///
/// // Load data
/// await viewModel.load();
///
/// // Search
/// viewModel.search('John');
///
/// // Filter
/// viewModel.setFilter('status', 'active');
///
/// // Select item
/// viewModel.selectItem(customers[0]);
/// ```
class JuxCollectionViewModel extends ViewModel {
  // Dependencies
  final dynamic _queryService;
  final Map<String, dynamic> _jux; // JUX view definition
  final Map<String, dynamic> _model; // MetaX model schema
  final Map<String, Map<String, dynamic>> _columnMap; // MetaX columns

  // State
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selectedItem;
  String? _searchQuery;
  int _currentPage = 1;
  int _pageSize = 20;
  final Map<String, dynamic> _filters = {};

  /// Immutable list of loaded items.
  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  /// Currently selected item, if any.
  Map<String, dynamic>? get selectedItem => _selectedItem;

  /// Total number of loaded items.
  int get totalItems => _items.length;

  /// Whether an item is currently selected.
  bool get hasSelection => _selectedItem != null;

  /// Current search query, if any.
  String? get searchQuery => _searchQuery;

  /// Current page number (1-based).
  int get currentPage => _currentPage;

  /// Number of items per page.
  int get pageSize => _pageSize;

  /// Active filters.
  Map<String, dynamic> get filters => Map.unmodifiable(_filters);

  /// Creates a JUX collection ViewModel.
  ///
  /// Parameters:
  /// - [queryService]: Service for executing data operations
  /// - [jux]: JUX view definition containing query list binding
  /// - [model]: MetaX model schema
  /// - [columns]: List of MetaX column definitions for display formatting
  /// - [pageSize]: Number of items per page (default 20)
  JuxCollectionViewModel({
    required dynamic queryService,
    required Map<String, dynamic> jux,
    required Map<String, dynamic> model,
    required List<Map<String, dynamic>> columns,
    int pageSize = 20,
  })  : _queryService = queryService,
        _jux = jux,
        _model = model,
        _columnMap = {for (var col in columns) col['c'] as String: col},
        _pageSize = pageSize;

  @override
  Future<void> load() async {
    // Get list query ID from JUX definition
    final listQueryId = _jux['list_qxi'] as int?;
    if (listQueryId == null) {
      setError('No list query configured in JUX definition');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Build query parameters
      final params = <String, dynamic>{
        'limit': _pageSize,
        'offset': (_currentPage - 1) * _pageSize,
        if (_searchQuery != null && _searchQuery!.isNotEmpty) 'search': _searchQuery,
        ..._filters,
      };

      // Execute query list operation
      // TODO: Replace with actual QueryService call
      final result = <Map<String, dynamic>>[];

      _items = result;
    } catch (e) {
      setError('Failed to load data: $e');
      _items = [];
    } finally {
      setLoading(false);
    }
  }

  /// Select an item from the collection.
  void selectItem(Map<String, dynamic> item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// Clear the current selection.
  void clearSelection() {
    _selectedItem = null;
    notifyListeners();
  }

  /// Search the collection.
  ///
  /// Resets to page 1 and reloads data with search query applied.
  /// Backend query operation determines search behavior.
  void search(String query) {
    if (_searchQuery != query) {
      _searchQuery = query.isEmpty ? null : query;
      _currentPage = 1;
      load();
    }
  }

  /// Set a filter on a specific field.
  void setFilter(String field, dynamic value) {
    _filters[field] = value;
    _currentPage = 1;
    load();
  }

  /// Remove a specific filter.
  void removeFilter(String field) {
    _filters.remove(field);
    _currentPage = 1;
    load();
  }

  /// Clear all filters.
  void clearFilters() {
    if (_filters.isNotEmpty) {
      _filters.clear();
      _currentPage = 1;
      load();
    }
  }

  /// Load the next page of data.
  void nextPage() {
    _currentPage++;
    load();
  }

  /// Load the previous page of data.
  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      load();
    }
  }

  /// Jump to a specific page.
  void goToPage(int page) {
    if (page >= 1 && page != _currentPage) {
      _currentPage = page;
      load();
    }
  }

  /// Get formatted display value for a field.
  ///
  /// Uses MetaX column metadata to format values appropriately for their
  /// data type (e.g., date formatting for timestamps, decimal places for numbers).
  String getDisplayValue(Map<String, dynamic> record, String fieldCode) {
    final value = record[fieldCode];
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
  ///
  /// Unlike [getDisplayValue], this returns the actual stored value without
  /// formatting.
  dynamic getRawValue(Map<String, dynamic> record, String fieldCode) {
    return record[fieldCode];
  }

  /// Check if a field exists in a record.
  bool hasField(Map<String, dynamic> record, String fieldCode) {
    return record.containsKey(fieldCode);
  }

  /// Refresh the current page.
  Future<void> refresh() async {
    await load();
  }
}
