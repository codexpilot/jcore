import 'view_model.dart';

/// Generic form ViewModel for JUX framework - works with any dynamic schema.
///
/// ## JUX Framework Integration
///
/// This ViewModel is part of JCore's JUX (UI/UX framework) and handles form
/// editing for ANY model defined through metadata, without code generation.
///
/// Uses metadata from JCore structure:
/// - **JUX**: View definition (fields, validation rules, query bindings)
/// - **MetaX**: Model schema (ModelX, ColumnX)
/// - **Data**: Data operations (QueryX bindings)
///
/// ## Dynamic Schema Support
///
/// Schemas are fully dynamic - users define models at runtime in ContextStudio.
/// This ViewModel interprets metadata at runtime to provide:
/// - Type-safe field updates (via metadata validation)
/// - Validation based on column definitions
/// - Data persistence via query operations
/// - Dirty tracking for unsaved changes
///
/// ## Example Usage
///
/// ```dart
/// // Works for customer, sales_order, or ANY model
/// final viewModel = JuxFormViewModel(
///   queryService: queryService,
///   jux: await juxRegistry.getView('customer_form'),
///   model: await metaRegistry.getModel('customer'),
///   columns: await metaRegistry.getColumns('customer'),
/// );
///
/// // Load existing record
/// await viewModel.load(recordId: 123);
///
/// // Update fields
/// viewModel.updateField('name', 'John Doe');
/// viewModel.updateField('email', 'john@example.com');
///
/// // Validate and save
/// if (viewModel.validate()) {
///   final saved = await viewModel.save();
/// }
/// ```
///
/// ## State Properties
///
/// - [draft]: Current edit state (null until loaded)
/// - [isDirty]: True if draft differs from original
/// - [hasErrors]: True if validation errors exist
/// - [fieldErrors]: Map of field codes to error messages
/// - [isLoading]: True during async operations
/// - [errorMessage]: General error message
class JuxFormViewModel extends ViewModel {
  // Dependencies
  final Map<String, dynamic> _jux; // JUX view definition
  final Map<String, Map<String, dynamic>> _columnMap; // MetaX columns

  // State
  Map<String, dynamic>? _original; // Original loaded data
  Map<String, dynamic>? _draft; // Current edit state
  final Map<String, String> _fieldErrors = {}; // Field-specific errors

  /// Current draft state.
  ///
  /// Returns a copy to prevent external modification.
  /// Null until [load] is called.
  Map<String, dynamic>? get draft => _draft != null ? Map.from(_draft!) : null;

  /// Whether the draft has unsaved changes.
  bool get isDirty {
    if (_draft == null) return false;
    if (_original == null) return true; // New record
    return !_mapsEqual(_draft!, _original!);
  }

  /// Whether validation errors exist.
  bool get hasErrors => _fieldErrors.isNotEmpty;

  /// Map of field codes to validation error messages.
  Map<String, String> get fieldErrors => Map.unmodifiable(_fieldErrors);

  /// Creates a JUX form ViewModel.
  ///
  /// Parameters:
  /// - [queryService]: Service for executing data operations
  /// - [jux]: JUX view definition containing field definitions and query bindings
  /// - [model]: MetaX model schema
  /// - [columns]: List of MetaX column definitions
  JuxFormViewModel({
    required this._jux,
    required List<Map<String, dynamic>> columns,
  }) : _columnMap = {for (var col in columns) col['c'] as String: col};

  @override
  Future<void> load({int? recordId}) async {
    if (recordId == null) {
      // New record mode
      _draft = _createEmptyRecord();
      _original = null;
      _fieldErrors.clear();
      notifyListeners();
      return;
    }

    // Get query ID from JUX definition
    final getQueryId = _jux['get_qxi'] as int?;
    if (getQueryId == null) {
      setError('No get query configured in JUX definition');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Execute query to load record
      // TODO: Replace with actual QueryService call
      final result = <String, dynamic>{
        'i': recordId,
      };

      _original = result;
      _draft = Map.from(_original!);
      _fieldErrors.clear();
    } catch (e) {
      setError('Failed to load record: $e');
    } finally {
      setLoading(false);
    }
  }

  /// Update a field value with metadata-driven validation.
  ///
  /// The value is type-coerced based on the column's data type from MetaX.
  void updateField(String fieldCode, dynamic value) {
    if (_draft == null) return;

    // Get column metadata from MetaX
    final column = _columnMap[fieldCode];
    if (column == null) {
      print('Warning: Unknown field $fieldCode');
      return;
    }

    // Type coercion based on DataType
    final dataTypeId = column['dti'] as int;
    final typedValue = _coerceValue(value, dataTypeId);

    _draft![fieldCode] = typedValue;
    _fieldErrors.remove(fieldCode);

    notifyListeners();
  }

  /// Get current value for a field.
  dynamic getFieldValue(String fieldCode) {
    return _draft?[fieldCode];
  }

  /// Validate all fields based on JUX and MetaX metadata.
  ///
  /// Checks:
  /// - Required fields (from JUX view options or MetaX column metadata)
  /// - Data type validation
  /// - Custom validation rules (from JUX view options)
  /// - Min/max constraints for numbers
  /// - Length constraints for text
  bool validate() {
    _fieldErrors.clear();

    if (_draft == null) {
      setError('No draft to validate');
      return false;
    }

    // Iterate through JUX definition to find all field controls
    final children = _jux['definition']?['children'] as List?;
    if (children != null) {
      _validateFields(children);
    }

    notifyListeners();
    return _fieldErrors.isEmpty;
  }

  /// Validate fields recursively through JUX view definition tree.
  void _validateFields(List<dynamic> children) {
    for (final child in children) {
      final childMap = child as Map<String, dynamic>;

      // Recurse for layouts (have children)
      if (childMap['children'] != null) {
        _validateFields(childMap['children'] as List);
        continue;
      }

      // Validate field controls (have field binding)
      final fieldCode = childMap['field'] as String?;
      if (fieldCode == null) continue;

      final value = _draft![fieldCode];
      final options = childMap['options'] as Map<String, dynamic>?;
      final column = _columnMap[fieldCode];

      if (column == null) continue;

      // Check required
      final isRequired = options?['required'] == true;
      if (isRequired && _isEmpty(value)) {
        _fieldErrors[fieldCode] = options?['requiredMessage'] as String? ?? 'Required';
        continue;
      }

      if (_isEmpty(value)) continue;

      // Custom validation from JUX view options
      if (options?['validation'] != null) {
        final customError = _validateByRule(value, options!['validation'] as String);
        if (customError != null) {
          _fieldErrors[fieldCode] = customError;
          continue;
        }
      }

      // Data type specific validation
      final dataTypeId = column['dti'] as int;
      _validateByDataType(fieldCode, value, dataTypeId, options);
    }
  }

  /// Validate field value by data type.
  void _validateByDataType(
    String fieldCode,
    dynamic value,
    int dataTypeId,
    Map<String, dynamic>? options,
  ) {
    switch (dataTypeId) {
      case 1: // INT
        if (value is! int) {
          _fieldErrors[fieldCode] = 'Must be a number';
          return;
        }
        if (options?['min'] != null && value < (options!['min'] as int)) {
          _fieldErrors[fieldCode] = 'Minimum value is ${options['min']}';
        }
        if (options?['max'] != null && value > (options!['max'] as int)) {
          _fieldErrors[fieldCode] = 'Maximum value is ${options['max']}';
        }
        break;

      case 2: // TEXT
        if (value is! String) {
          _fieldErrors[fieldCode] = 'Must be text';
          return;
        }
        if (options?['minLength'] != null && value.length < (options!['minLength'] as int)) {
          _fieldErrors[fieldCode] = 'Minimum length is ${options['minLength']}';
        }
        if (options?['maxLength'] != null && value.length > (options!['maxLength'] as int)) {
          _fieldErrors[fieldCode] = 'Maximum length is ${options['maxLength']}';
        }
        break;

      case 6: // DECIMAL
        if (value is! double && value is! int) {
          _fieldErrors[fieldCode] = 'Must be a decimal number';
        }
        break;
    }
  }

  /// Validate by custom rule name.
  String? _validateByRule(dynamic value, String rule) {
    switch (rule) {
      case 'email':
        final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return regex.hasMatch(value.toString()) ? null : 'Invalid email format';

      case 'url':
        final uri = Uri.tryParse(value.toString());
        return uri != null && uri.hasScheme ? null : 'Invalid URL';

      case 'phone':
        final regex = RegExp(r'^\+?[\d\s\-\(\)]+$');
        return regex.hasMatch(value.toString()) ? null : 'Invalid phone number';

      default:
        return null;
    }
  }

  /// Save the current draft using the configured query operation.
  Future<Map<String, dynamic>?> save() async {
    if (!validate()) return null;

    final saveQueryId = _jux['save_qxi'] as int?;
    if (saveQueryId == null) {
      setError('No save query configured in JUX definition');
      return null;
    }

    setLoading(true);
    setError(null);

    try {
      // Execute save operation
      // TODO: Replace with actual QueryService call
      final saved = Map<String, dynamic>.from(_draft!);
      if (saved['i'] == null || saved['i'] == 0) {
        saved['i'] = DateTime.now().millisecondsSinceEpoch;
      }

      _original = saved;
      _draft = Map.from(saved);

      return saved;
    } catch (e) {
      setError('Failed to save: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// Discard changes and revert to original state.
  void discard() {
    _draft = _original != null ? Map.from(_original!) : _createEmptyRecord();
    _fieldErrors.clear();
    notifyListeners();
  }

  /// Create empty record with default values based on MetaX schema.
  Map<String, dynamic> _createEmptyRecord() {
    final empty = <String, dynamic>{};
    for (final entry in _columnMap.entries) {
      final column = entry.value;
      final dataTypeId = column['dti'] as int;
      empty[entry.key] = _getDefaultValue(dataTypeId);
    }
    return empty;
  }

  /// Coerce value to appropriate type based on JCore DataType catalog.
  dynamic _coerceValue(dynamic value, int dataTypeId) {
    if (value == null) return null;

    switch (dataTypeId) {
      case 1: // INT
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
        return null;

      case 2: // TEXT
        return value.toString();

      case 3: // BOOLEAN
        if (value is bool) return value;
        if (value is int) return value == 1;
        if (value is String) return value.toLowerCase() == 'true';
        return false;

      case 5: // TIMESTAMP (epoch ms)
        if (value is int) return value;
        if (value is DateTime) return value.millisecondsSinceEpoch;
        if (value is String) {
          final dt = DateTime.tryParse(value);
          return dt?.millisecondsSinceEpoch;
        }
        return null;

      case 6: // DECIMAL
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) return double.tryParse(value);
        return null;

      default:
        return value;
    }
  }

  /// Get default value for a data type.
  dynamic _getDefaultValue(int dataTypeId) {
    switch (dataTypeId) {
      case 1:
        return 0;
      case 2:
        return '';
      case 3:
        return false;
      case 5:
        return DateTime.now().millisecondsSinceEpoch;
      case 6:
        return 0.0;
      default:
        return null;
    }
  }

  bool _isEmpty(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
