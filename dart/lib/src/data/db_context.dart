/// Database context singleton for model and schema registry.
///
/// Provides centralized access to validated ModelX and JxSchema instances
/// within the active scope. The host application supplies authorized loading
/// through QueryService, and DbContext manages activation and clearing.
library;

import 'package:jcore/metax.dart';
import 'jx_schema.dart';
import 'jx_row.dart';
import 'query_service.dart';
import 'record_x.dart';

/// Singleton database context for model and schema management.
///
/// Usage:
/// ```dart
/// // Access registries
/// final models = DbContext.instance.models;
/// final schemas = DbContext.instance.schemas;
///
/// // Look up models
/// final model = models.byId(123);
/// final modelByName = models.byName('Customer');
/// final modelByCode = models.byCode('CUST');
///
/// // Activate models and schemas together
/// await DbContext.instance.activate(
///   models: [model1, model2],
///   schemas: {123: schema1, 124: schema2},
/// );
///
/// // Set query service for data operations
/// DbContext.instance.setQueryService(myQueryService);
///
/// // Fetch and edit records
/// final record = await DbContext.instance.fetchRecord(modelId: 500, recordId: 1);
/// final editable = DbContext.instance.openForEdit(record);
/// editable.setField('customer_name', 'New Name');
/// final saved = await DbContext.instance.saveChanges(editable);
///
/// // Clear on session/scope change
/// DbContext.instance.clear();
/// ```
class DbContext {
  DbContext._();

  /// Singleton instance
  static final DbContext instance = DbContext._();

  /// Model registry
  final ModelRegistry models = ModelRegistry._();

  /// Schema registry
  final SchemaRegistry schemas = SchemaRegistry._();

  /// Query service for data operations
  QueryService? _queryService;

  /// Record cache (keyed by "modelId:recordId")
  final Map<String, JxRow> _recordCache = {};

  /// Set the query service for data operations.
  ///
  /// The query service executes backend operations for fetching and saving records.
  void setQueryService(QueryService service) {
    _queryService = service;
  }

  /// Fetch a record by model ID and record ID.
  ///
  /// Loads the record from the query service and caches it.
  /// Returns the cached row ready for viewing or editing.
  ///
  /// Throws [StateError] if no query service is set.
  /// Throws [ArgumentError] if model or schema not found.
  Future<JxRow> fetchRecord({
    required int modelId,
    required int recordId,
    int queryId = 5000, // Default query ID for get operations
  }) async {
    if (_queryService == null) {
      throw StateError('No query service set. Call setQueryService() first.');
    }

    // Validate model exists
    final model = models.byId(modelId);
    if (model == null) {
      throw ArgumentError('Model not found: $modelId');
    }

    // Validate schema exists
    final schema = schemas.byModelId(modelId);
    if (schema == null) {
      throw ArgumentError('Schema not found for model: $modelId');
    }

    // Execute query
    final result = await _queryService!.executeQuery(queryId, {'i': recordId});

    // Deserialize result to JxRow
    final row = _deserializeRecord(result, model, schema);

    // Cache the row
    final cacheKey = '$modelId:$recordId';
    _recordCache[cacheKey] = row;

    return row;
  }

  /// Open a record for editing.
  ///
  /// Creates a RecordX that tracks edits without modifying the cached row.
  RecordX openForEdit(JxRow row, {required int modelId, int? recordId}) {
    return RecordX(
      modelId: modelId,
      recordId: recordId,
      schemaVersion: 1, // TODO: Extract from row when version tracking is added
      cachedRow: row,
    );
  }

  /// Save changes to a record.
  ///
  /// Executes the save operation through the query service.
  /// On success, updates the cache with the returned result.
  /// On failure, preserves the RecordX for retry.
  ///
  /// Returns the updated cached row on success.
  /// Throws exception on failure (RecordX remains unchanged).
  Future<JxRow> saveChanges(
    RecordX record, {
    int queryId = 5001, // Default query ID for save operations
  }) async {
    if (_queryService == null) {
      throw StateError('No query service set. Call setQueryService() first.');
    }

    // Validate model exists
    final model = models.byId(record.modelId);
    if (model == null) {
      throw ArgumentError('Model not found: ${record.modelId}');
    }

    // Validate schema exists
    final schema = schemas.byModelId(record.modelId);
    if (schema == null) {
      throw ArgumentError('Schema not found for model: ${record.modelId}');
    }

    // Execute save
    final result = await _queryService!.executeQuery(queryId, record.toJson());

    // Deserialize result
    final updatedRow = _deserializeRecord(result, model, schema);

    // Update cache
    if (record.recordId != null) {
      final cacheKey = '${record.modelId}:${record.recordId}';
      _recordCache[cacheKey] = updatedRow;
    }

    return updatedRow;
  }

  /// Deserialize a record from query result
  JxRow _deserializeRecord(
    dynamic result,
    ModelX model,
    JxSchema schema,
  ) {
    if (result is! Map<String, dynamic>) {
      throw ArgumentError('Expected Map result, got ${result.runtimeType}');
    }

    // Extract root cells
    final cells = <dynamic>[];
    for (final field in schema.fields) {
      cells.add(result[field.n]);
    }

    // Check if composed model
    if (model.isComposed) {
      // Extract sections
      final sections = <String, JxSection>{};

      // Map child model IDs to section keys
      // For sales invoice: 501=invoiceInfo, 502=invoiceDetails, 503=payments
      final childModels = model.mxis;
      final sectionKeys = _inferSectionKeys(result, childModels);

      for (final entry in sectionKeys.entries) {
        final sectionKey = entry.key;
        final childModelId = entry.value;
        final childSchema = schemas.byModelId(childModelId);

        if (childSchema == null) continue;

        final sectionData = result[sectionKey];
        if (sectionData is List) {
          if (sectionKey == 'invoiceInfo') {
            // One section
            if (sectionData.isNotEmpty) {
              final rowData = sectionData.first as Map<String, dynamic>;
              final row = _mapToRow(rowData, childSchema);
              sections[sectionKey] = JxOneSection(row: row);
            } else {
              sections[sectionKey] = const JxOneSection(row: null);
            }
          } else {
            // Many section
            final rows = sectionData
                .map((d) => _mapToRow(d as Map<String, dynamic>, childSchema))
                .toList();
            sections[sectionKey] = JxManySection(rows: rows);
          }
        }
      }

      return JxComposedRow(
        schema: schema,
        cells: cells,
        sections: sections,
      );
    }

    return JxRow(schema: schema, cells: cells);
  }

  /// Infer section keys from result data
  Map<String, int> _inferSectionKeys(Map<String, dynamic> result, List<int> childModelIds) {
    // For sales invoice fixture: map known section keys to child model IDs
    final keys = <String, int>{};

    if (result.containsKey('invoiceInfo') && childModelIds.isNotEmpty) {
      keys['invoiceInfo'] = childModelIds[0]; // 501
    }
    if (result.containsKey('invoiceDetails') && childModelIds.length > 1) {
      keys['invoiceDetails'] = childModelIds[1]; // 502
    }
    if (result.containsKey('payments') && childModelIds.length > 2) {
      keys['payments'] = childModelIds[2]; // 503
    }

    return keys;
  }

  /// Convert Map to JxRow using schema
  JxRow _mapToRow(Map<String, dynamic> map, JxSchema schema) {
    final cells = <dynamic>[];
    for (final field in schema.fields) {
      cells.add(map[field.n]);
    }
    return JxRow(schema: schema, cells: cells);
  }

  /// Activate validated models and schemas together.
  ///
  /// This method atomically replaces the current registries with new validated
  /// data. All models and their corresponding schemas must be provided together.
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - Duplicate model IDs, names, or codes
  /// - Schema missing for a model
  /// - Invalid model or schema data
  void activate({
    required List<ModelX> models,
    required Map<int, JxSchema> schemas,
  }) {
    // Validate models
    final idSet = <int>{};
    final nameMap = <String, List<int>>{};
    final codeMap = <String, int>{};

    for (final model in models) {
      // Check duplicate IDs
      if (!idSet.add(model.i)) {
        throw ArgumentError('Duplicate model ID: ${model.i}');
      }

      // Track names (allow duplicates, will check for ambiguity on lookup)
      nameMap.putIfAbsent(model.n, () => []).add(model.i);

      // Check duplicate codes
      if (codeMap.containsKey(model.c)) {
        throw ArgumentError(
          'Duplicate model code: ${model.c} '
          '(IDs ${codeMap[model.c]}, ${model.i})',
        );
      }
      codeMap[model.c] = model.i;

      // Validate schema exists
      if (!schemas.containsKey(model.i)) {
        throw ArgumentError('Missing schema for model ${model.i} (${model.c})');
      }
    }

    // Atomically activate
    this.models._activate(models, nameMap, codeMap);
    this.schemas._activate(schemas);
  }

  /// Clear all registries and cached records.
  ///
  /// Call this when the session or scope changes to reject stale results.
  void clear() {
    models._clear();
    schemas._clear();
    _recordCache.clear();
    _queryService = null;
  }
}

/// Model registry with lookup by ID, name, and code.
class ModelRegistry {
  ModelRegistry._();

  Map<int, ModelX> _byId = {};
  Map<String, List<int>> _byName = {};
  Map<String, int> _byCode = {};

  /// Look up model by ID.
  ///
  /// Returns null if not found.
  ModelX? byId(int id) => _byId[id];

  /// Look up model by name.
  ///
  /// Throws [ArgumentError] if the name is ambiguous (multiple models with
  /// the same name exist in the active scope).
  ///
  /// Returns null if not found.
  ModelX? byName(String name) {
    final ids = _byName[name];
    if (ids == null || ids.isEmpty) return null;
    if (ids.length > 1) {
      throw ArgumentError(
        'Ambiguous model name "$name": matches ${ids.length} models '
        '(IDs: ${ids.join(", ")})',
      );
    }
    return _byId[ids.first];
  }

  /// Look up model by code.
  ///
  /// Returns null if not found.
  ModelX? byCode(String code) {
    final id = _byCode[code];
    return id != null ? _byId[id] : null;
  }

  /// Get all active model IDs.
  Iterable<int> get ids => _byId.keys;

  /// Get all active models.
  Iterable<ModelX> get all => _byId.values;

  /// Check if a model ID is active.
  bool contains(int id) => _byId.containsKey(id);

  void _activate(
    List<ModelX> models,
    Map<String, List<int>> nameMap,
    Map<String, int> codeMap,
  ) {
    _byId = {for (final m in models) m.i: m};
    _byName = nameMap;
    _byCode = codeMap;
  }

  void _clear() {
    _byId = {};
    _byName = {};
    _byCode = {};
  }
}

/// Schema registry with lookup by model ID.
class SchemaRegistry {
  SchemaRegistry._();

  Map<int, JxSchema> _schemas = {};

  /// Look up schema by model ID.
  ///
  /// Returns null if not found.
  JxSchema? byModelId(int modelId) => _schemas[modelId];

  /// Get all active schema IDs.
  Iterable<int> get ids => _schemas.keys;

  /// Check if a schema exists for a model ID.
  bool contains(int modelId) => _schemas.containsKey(modelId);

  void _activate(Map<int, JxSchema> schemas) {
    _schemas = Map.from(schemas);
  }

  void _clear() {
    _schemas = {};
  }
}
