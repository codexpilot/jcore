/// Session-scoped database context and model and schema registries.
library;

import 'package:jcore/metax.dart';

import 'composed_row_decoder.dart';
import 'jx_row.dart';
import 'jx_schema.dart';
import 'jx_table.dart';
import 'query_service.dart';
import 'record_x.dart';

/// Coordinates metadata, query results, and drafts for one session.
///
/// Create a context for each session and inject it into its consumers. The
/// [instance] singleton remains available for apps with one active session.
class DbContext {
  DbContext({this._queryService});

  static final DbContext instance = DbContext();

  final ModelRegistry models = ModelRegistry._();
  final SchemaRegistry schemas = SchemaRegistry._();

  static final _rowOrigins = Expando<_RecordOrigin>();
  static final _draftScopes = Expando<Object>();

  QueryTransport? _queryService;
  Map<int, JxResultProjection> _projections = {};
  Object _scope = Object();

  /// Replace the service and invalidate work from the previous service.
  void setQueryService(QueryTransport service) {
    if (identical(_queryService, service)) return;
    _queryService = service;
    _scope = Object();
  }

  /// Fetch a flat JX result as one schema and a matrix of positional rows.
  ///
  /// An active query projection supplies its schema. For a tabular query
  /// without a registered projection, pass its exact ordered [schema].
  /// The caller holds the returned table for as long as it needs the result.
  Future<JxTable> fetchTable({
    required int queryId,
    JxSchema? schema,
    Map<String, dynamic> params = const {},
    String? timezone,
  }) async {
    final service = _requireService();
    if (service is! JxQueryService) {
      throw StateError('Fetching a JX table requires a JxQueryService.');
    }
    final scope = _scope;
    final projection = _projections[queryId];
    if (projection != null && projection.sections.isNotEmpty) {
      throw ArgumentError('Query $queryId has a composed result.');
    }
    final resultSchema = projection?.schema ?? schema;
    if (resultSchema == null) {
      throw ArgumentError(
        'An ordered result schema is required for query $queryId.',
      );
    }
    final response = await service.executeJxQuery(queryId, params);
    _requireScope(scope);
    return JxTable.fromJson(
      body: response.body,
      encoding: response.encoding,
      schema: resultSchema,
      timezone: timezone,
    );
  }

  /// Fetch a record using the active projection for the effective query.
  Future<JxRow> fetchRecord({
    required int modelId,
    required int recordId,
    int queryId = 5000,
  }) async {
    final service = _requireRecordService();
    final scope = _scope;
    final plan = _resolveResult(modelId, queryId);
    final result = await service.executeQuery(queryId, {'i': recordId});
    _requireScope(scope);
    return _decodeResult(result, plan, modelId, recordId);
  }

  /// Open a row for editing in this scope.
  ///
  /// A row returned by this context carries its record identity and version.
  RecordX openForEdit(JxRow row, {required int modelId, int? recordId}) {
    final origin = _checkRow(row, modelId, recordId);
    final draft = RecordX(
      modelId: modelId,
      recordId: recordId ?? origin?.recordId,
      schemaVersion: 1,
      recordVersion: origin?.recordVersion ?? _recordVersion(row.byCode('v')),
      cachedRow: row,
      sectionIdentityCodes:
          origin?.projection?.sectionIdentityCodes ?? const {},
    );
    _draftScopes[draft] = _scope;
    return draft;
  }

  /// Open an insert draft bound to this scope.
  RecordX openForCreate({required int modelId, int queryId = 5001}) {
    final plan = _resolveResult(modelId, queryId);
    final draft = RecordX(
      modelId: modelId,
      schemaVersion: 1,
      sectionIdentityCodes: plan.projection?.sectionIdentityCodes ?? const {},
    );
    _draftScopes[draft] = _scope;
    return draft;
  }

  /// Save the draft using its record version and decode the returned record.
  ///
  /// A standalone draft becomes bound to the context on its first save. For an
  /// app-created draft, use [openForEdit] or [openForCreate] to bind it earlier.
  Future<JxRow> saveChanges(RecordX record, {int queryId = 5001}) async {
    final service = _requireRecordService();
    final scope = _scope;
    final draftScope = _draftScopes[record];
    if (draftScope != null) _requireScope(draftScope);
    final cachedRow = record.cachedRow;
    if (cachedRow != null) {
      final origin = _checkRow(cachedRow, record.modelId, record.recordId);
      if (origin != null &&
          ((origin.recordId != null && record.recordId != origin.recordId) ||
              (origin.recordVersion != null &&
                  record.recordVersion != origin.recordVersion))) {
        throw ArgumentError(
          'The draft must use the loaded record ID and version.',
        );
      }
    }
    final plan = _resolveResult(record.modelId, queryId);
    _draftScopes[record] = scope;
    final result = await service.executeQuery(queryId, record.toJson());
    _requireScope(scope);
    return _decodeResult(
      result,
      plan,
      record.modelId,
      record.recordId == 0 ? null : record.recordId,
    );
  }

  QueryTransport _requireService() =>
      _queryService ??
      (throw StateError('No query service set. Call setQueryService() first.'));

  QueryService _requireRecordService() {
    final service = _requireService();
    if (service is! QueryService) {
      throw StateError('Fetching and saving records requires a QueryService.');
    }
    return service;
  }

  void _requireScope(Object scope) {
    if (!identical(scope, _scope)) {
      throw StateError('The database session or metadata has changed.');
    }
  }

  _RecordOrigin? _checkRow(JxRow row, int modelId, int? recordId) {
    final origin = _rowOrigins[row];
    if (origin != null) {
      _requireScope(origin.scope);
      if (origin.modelId != modelId ||
          (recordId != null &&
              origin.recordId != null &&
              recordId != origin.recordId)) {
        throw ArgumentError('The row belongs to a different model or record.');
      }
    }
    return origin;
  }

  ({JxSchema schema, JxResultProjection? projection}) _resolveResult(
    int modelId,
    int queryId,
  ) {
    final model = models.byId(modelId);
    if (model == null) throw ArgumentError('Model not found: $modelId');

    final projection = _projections[queryId];
    if (projection != null) {
      if (projection.modelId != modelId) {
        throw ArgumentError(
          'Result projection for query $queryId belongs to model '
          '${projection.modelId}, not $modelId.',
        );
      }
      return (schema: projection.schema, projection: projection);
    }
    if (model.isComposed) {
      throw StateError('No result projection registered for query $queryId.');
    }
    final schema = schemas.byModelId(modelId);
    if (schema == null) {
      throw StateError('Schema not found for model: $modelId');
    }
    return (schema: schema, projection: null);
  }

  JxRow _decodeResult(
    Object? result,
    ({JxSchema schema, JxResultProjection? projection}) plan,
    int modelId,
    int? recordId,
  ) {
    final projection = plan.projection;
    final row = projection == null
        ? decodeRecord(result, plan.schema)
        : projection.decode(result);
    final data = result as Map<String, Object?>;
    final resultId = data['i'];
    if (resultId is int && resultId > 0) {
      if (recordId != null && recordId != resultId) {
        throw FormatException('Expected record $recordId, got $resultId.');
      }
      recordId = resultId;
    }
    _rowOrigins[row] = _RecordOrigin(
      scope: _scope,
      modelId: modelId,
      recordId: recordId,
      recordVersion: _recordVersion(data['v']),
      projection: projection,
    );
    return row;
  }

  static int? _recordVersion(Object? value) {
    if (value == null) return null;
    if (value is int && value >= 0) return value;
    throw FormatException('Invalid record version: $value.');
  }

  /// Replace the registries and invalidate rows and drafts from prior metadata.
  ///
  /// Model codes and IDs must be unique. Display names may repeat; lookup by
  /// an ambiguous name throws. Projections are keyed by effective query ID.
  void activate({
    required List<ModelX> models,
    required Map<int, JxSchema> schemas,
    Map<int, JxResultProjection> projections = const {},
  }) {
    final idSet = <int>{};
    final nameMap = <String, List<int>>{};
    final codeMap = <String, int>{};

    for (final model in models) {
      if (!idSet.add(model.i)) {
        throw ArgumentError('Duplicate model ID: ${model.i}');
      }
      nameMap.putIfAbsent(model.n, () => []).add(model.i);
      if (codeMap.containsKey(model.c)) {
        throw ArgumentError(
          'Duplicate model code: ${model.c} '
          '(IDs ${codeMap[model.c]}, ${model.i})',
        );
      }
      codeMap[model.c] = model.i;
      if (!schemas.containsKey(model.i)) {
        throw ArgumentError('Missing schema for model ${model.i} (${model.c})');
      }
    }
    for (final entry in projections.entries) {
      if (!idSet.contains(entry.value.modelId)) {
        throw ArgumentError(
          'Query ${entry.key} projects inactive model ${entry.value.modelId}.',
        );
      }
    }

    this.models._activate(models, nameMap, codeMap);
    this.schemas._activate(schemas);
    _projections = Map.of(projections);
    _scope = Object();
  }

  /// Clear metadata and invalidate outstanding requests, rows, and drafts.
  void clear() {
    models._clear();
    schemas._clear();
    _projections = {};
    _queryService = null;
    _scope = Object();
  }
}

class _RecordOrigin {
  const _RecordOrigin({
    required this.scope,
    required this.modelId,
    required this.recordId,
    required this.recordVersion,
    required this.projection,
  });

  final Object scope;
  final int modelId;
  final int? recordId;
  final int? recordVersion;
  final JxResultProjection? projection;
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
