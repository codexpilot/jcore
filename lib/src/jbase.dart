import 'jsonc.dart';

/// JBase - Singleton schema registry for AIX
///
/// Stores and manages JSONC schemas by their JID (schema ID).
/// Use this to cache schemas and avoid re-transmitting them with every data payload.
///
/// Example usage:
/// ```dart
/// // Register a schema once
/// final schema = JsonC(
///   jv: 1,
///   jid: 12345,
///   schema: {'id': 300003, 'name': 300008},
/// );
/// JBase.instance.register(schema);
///
/// // Later, use data-only JSONC with same JID
/// final dataOnly = JsonC(jv: 1, jid: 12345, data: [[1, 'John']]);
///
/// // Retrieve schema when needed
/// final fullSchema = JBase.instance.get(12345);
/// ```
class JBase {
  /// Private constructor for singleton
  JBase._();

  /// Singleton instance
  static final JBase instance = JBase._();

  /// Schema registry: JID -> JsonC (schema-only)
  final Map<int, JsonC> _schemas = {};

  /// Register a schema
  ///
  /// The JsonC must have a schema. If it has data, only the schema is stored.
  /// If a schema with the same JID already exists, it will be replaced.
  ///
  /// Returns the registered schema (schema-only JsonC).
  JsonC register(JsonC jsonc) {
    if (!jsonc.hasSchema) {
      throw ArgumentError('JsonC must have schema to register');
    }

    // Extract schema-only version
    final schemaOnly = JsonC(
      jv: jsonc.jv,
      jid: jsonc.jid,
      schema: jsonc.schema,
    );

    _schemas[jsonc.jid] = schemaOnly;

    return schemaOnly;
  }

  /// Register multiple schemas at once
  ///
  /// Returns the number of schemas registered.
  int registerAll(List<JsonC> schemas) {
    int count = 0;
    for (final schema in schemas) {
      if (schema.hasSchema) {
        register(schema);
        count++;
      }
    }
    return count;
  }

  /// Get schema by JID
  ///
  /// Returns null if schema not found.
  JsonC? get(int jid) {
    return _schemas[jid];
  }

  /// Check if schema exists
  bool has(int jid) {
    return _schemas.containsKey(jid);
  }

  /// Get schema or throw if not found
  ///
  /// Use this when you expect the schema to exist.
  JsonC getOrThrow(int jid) {
    final schema = _schemas[jid];
    if (schema == null) {
      throw StateError('Schema with JID $jid not found in JBase');
    }
    return schema;
  }

  /// Remove schema by JID
  ///
  /// Returns true if schema was removed, false if it didn't exist.
  bool remove(int jid) {
    return _schemas.remove(jid) != null;
  }

  /// Clear all schemas
  void clear() {
    _schemas.clear();
  }

  /// Get all registered JIDs
  List<int> get jids => _schemas.keys.toList();

  /// Get number of registered schemas
  int get count => _schemas.length;

  /// Check if JBase is empty
  bool get isEmpty => _schemas.isEmpty;

  /// Check if JBase has schemas
  bool get isNotEmpty => _schemas.isNotEmpty;

  /// Get all schemas
  List<JsonC> get schemas => _schemas.values.toList();

  /// Get schema metadata for all registered schemas
  ///
  /// Returns list of maps with jv, jid, and column information.
  List<Map<String, dynamic>> getMetadata() {
    return _schemas.values.map((schema) {
      return {
        'jv': schema.jv,
        'jid': schema.jid,
        'columnCount': schema.columnCount,
        'columns': schema.columnNames,
        'dataTypes': schema.dataTypeIds,
      };
    }).toList();
  }

  /// Merge data-only JSONC with registered schema
  ///
  /// Looks up the schema by JID and creates a full JSONC.
  /// Throws if schema not found.
  ///
  /// Example:
  /// ```dart
  /// // Schema registered earlier
  /// JBase.instance.register(schemaJsonc);
  ///
  /// // Receive data-only payload
  /// final dataOnly = JsonC(jv: 1, jid: 12345, data: [[1, 'John']]);
  ///
  /// // Merge with schema
  /// final full = JBase.instance.mergeWithSchema(dataOnly);
  /// // Now has both schema and data
  /// ```
  JsonC mergeWithSchema(JsonC dataOnlyJsonc) {
    if (!dataOnlyJsonc.hasData) {
      throw ArgumentError('JsonC must have data to merge');
    }

    final schema = getOrThrow(dataOnlyJsonc.jid);

    return JsonC(
      jv: dataOnlyJsonc.jv,
      jid: dataOnlyJsonc.jid,
      jnf: dataOnlyJsonc.jnf,
      schema: schema.schema,
      data: dataOnlyJsonc.data,
    ).normalizeInt64();
  }

  /// Update schema version (jv) for a JID
  ///
  /// Returns true if update succeeded, false if JID not found.
  bool updateVersion(int jid, int newJv) {
    final schema = _schemas[jid];
    if (schema == null) return false;

    _schemas[jid] = JsonC(
      jv: newJv,
      jid: jid,
      schema: schema.schema,
    );

    return true;
  }

  /// Export all schemas as JSON-serializable list
  ///
  /// Useful for persisting schemas to storage.
  List<Map<String, dynamic>> export() {
    return _schemas.values.map((schema) => schema.toJson()).toList();
  }

  /// Import schemas from JSON-serializable list
  ///
  /// Useful for restoring schemas from storage.
  /// Returns the number of schemas imported.
  int import(List<Map<String, dynamic>> jsonList) {
    int count = 0;
    for (final json in jsonList) {
      try {
        final schema = JsonC.fromJson(json);
        if (schema.hasSchema) {
          register(schema);
          count++;
        }
      } catch (e) {
        // Skip invalid schemas
        continue;
      }
    }
    return count;
  }

  /// Find schemas by column name
  ///
  /// Returns list of JIDs that have the specified column.
  List<int> findByColumn(String columnName) {
    return _schemas.entries
        .where((entry) => entry.value.columnNames.contains(columnName))
        .map((entry) => entry.key)
        .toList();
  }

  /// Find schemas by data type ID
  ///
  /// Returns list of JIDs that use the specified data type.
  List<int> findByDataType(int dataTypeId) {
    return _schemas.entries
        .where((entry) => entry.value.dataTypeIds.contains(dataTypeId))
        .map((entry) => entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'JBase(schemas: ${_schemas.length})';
  }
}
