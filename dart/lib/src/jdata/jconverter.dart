import 'data_type_registry.dart';
import 'data_type_mapping.dart';
import 'jsonc.dart';
import 'numeric_value_validation.dart';

/// JConverter - utilities for working with JSONC format
///
/// Provides validation, type checking, and conversion utilities
/// for AIX JSONC data interchange format.
class JConverter {
  /// Validate JSONC structure and data types
  ///
  /// Returns list of validation errors, empty if valid
  static List<String> validate(JsonC jsonc) {
    final errors = <String>[];

    // Basic structure validation
    if (jsonc.jv < 0) {
      errors.add('Invalid jv (schema version): ${jsonc.jv}');
    }

    if (jsonc.jid < 0) {
      errors.add('Invalid jid (schema id): ${jsonc.jid}');
    }

    // Must have schema or data
    if (!jsonc.hasSchema && !jsonc.hasData) {
      errors.add('JSONC must have either schema or data');
    }

    // Schema validation
    if (jsonc.hasSchema) {
      final schemaErrors = validateSchema(jsonc.schema!);
      errors.addAll(schemaErrors);
    }

    // Data validation
    if (jsonc.hasData && jsonc.hasSchema) {
      final dataErrors = validateData(
        jsonc.data!,
        jsonc.schema!,
        jsonc.columnNames,
      );
      errors.addAll(dataErrors);
    }

    return errors;
  }

  /// Validate schema definition
  ///
  /// Checks that all data type IDs are valid
  static List<String> validateSchema(Map<String, int> schema) {
    final errors = <String>[];

    if (schema.isEmpty) {
      errors.add('Schema cannot be empty');
      return errors;
    }

    for (final entry in schema.entries) {
      final columnName = entry.key;
      final dataTypeId = entry.value;

      // Validate column name
      if (columnName.isEmpty) {
        errors.add('Column name cannot be empty');
      }

      // Validate data type ID
      if (!DataTypeRegistry.isValid(dataTypeId)) {
        errors.add(
          'Invalid data type ID for column "$columnName": $dataTypeId',
        );
      }
    }

    return errors;
  }

  /// Validate data rows against schema
  ///
  /// Checks row length and basic type compatibility
  static List<String> validateData(
    List<List<dynamic>> data,
    Map<String, int> schema,
    List<String> columnNames,
  ) {
    final errors = <String>[];
    final expectedLength = schema.length;

    for (int rowIdx = 0; rowIdx < data.length; rowIdx++) {
      final row = data[rowIdx];

      // Check row length
      if (row.length != expectedLength) {
        errors.add(
          'Row $rowIdx has ${row.length} values, expected $expectedLength',
        );
        continue;
      }

      // Validate each cell
      for (int colIdx = 0; colIdx < row.length; colIdx++) {
        final value = row[colIdx];
        final columnName = columnNames[colIdx];
        final dataTypeId = schema[columnName]!;

        final error = validateValue(value, dataTypeId, rowIdx, columnName);
        if (error != null) {
          errors.add(error);
        }
      }
    }

    return errors;
  }

  /// Validate a single value against its data type
  ///
  /// Returns error message if invalid, null if valid
  static String? validateValue(
    dynamic value,
    int dataTypeId,
    int rowIdx,
    String columnName,
  ) {
    // Null handling - depends on your requirements
    if (value == null) {
      return 'Row $rowIdx, column "$columnName": null value';
    }

    // Get base type if it exists
    final dataType = DataType.fromId(dataTypeId);

    if (dataType != null) {
      switch (dataType) {
        case DataType.boolean:
          if (value is! bool) {
            return 'Row $rowIdx, column "$columnName": expected bool, got ${value.runtimeType}';
          }
          break;
        case DataType.smallint:
        case DataType.int32:
        case DataType.int64:
          final BigInt? integer;
          if (value is int) {
            integer = BigInt.from(value);
          } else if (value is BigInt) {
            integer = value;
          } else if (value is String &&
              RegExp(r'^[+-]?[0-9]+$').hasMatch(value)) {
            integer = BigInt.tryParse(value);
          } else {
            integer = null;
          }
          if (integer == null) {
            return 'Row $rowIdx, column "$columnName": expected integer or decimal integer string, got ${value.runtimeType}';
          }
          final bits = switch (dataType) {
            DataType.smallint => 16,
            DataType.int32 => 32,
            _ => 64,
          };
          final limit = BigInt.one << (bits - 1);
          if (integer < -limit || integer >= limit) {
            return 'Row $rowIdx, column "$columnName": integer out of range for ${dataType.name}';
          }
          break;
        case DataType.datetime:
        case DataType.time:
          if (value is! int) {
            return 'Row $rowIdx, column "$columnName": expected int (epoch millis), got ${value.runtimeType}';
          }
          break;
        case DataType.numeric:
          final error = numericValueError(value);
          if (error != null) return 'Row $rowIdx, column "$columnName": $error';
          break;
        case DataType.text:
        case DataType.cuid:
        case DataType.uuid:
          if (value is! String) {
            return 'Row $rowIdx, column "$columnName": expected String, got ${value.runtimeType}';
          }
          break;
        case DataType.json:
        case DataType.jsonb:
          // JSON/JSONB can be any JSON-serializable value.
          break;
      }
      return null;
    }

    // Check for parameterized types
    if (DataTypeRegistry.isValidNumeric(dataTypeId)) {
      final params = DataTypeRegistry.decodeNumeric(dataTypeId)!;
      final error = numericValueError(
        value,
        precision: params.precision,
        scale: params.scale,
      );
      if (error != null) return 'Row $rowIdx, column "$columnName": $error';
    } else if (DataTypeRegistry.isValidText(dataTypeId)) {
      // Parameterized TEXT
      if (value is! String) {
        return 'Row $rowIdx, column "$columnName": expected String for TEXT type, got ${value.runtimeType}';
      }

      // Validate length
      final maxLength = DataTypeRegistry.decodeText(dataTypeId);
      if (maxLength != null && value.length > maxLength) {
        return 'Row $rowIdx, column "$columnName": text length ${value.length} exceeds max $maxLength';
      }
    }

    return null; // Valid
  }

  /// Convert JSONC to list of maps (rows as objects)
  ///
  /// Example:
  /// Schema: {"id": 40000, "name": 70000}
  /// Data: [[1, "John"], [2, "Jane"]]
  /// Result: [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]
  static List<Map<String, dynamic>> toMaps(JsonC jsonc) {
    if (!jsonc.hasData || !jsonc.hasSchema) {
      throw ArgumentError('JSONC must have both schema and data');
    }

    final normalized = jsonc.normalizeInt64();
    final columnNames = normalized.columnNames;
    final result = <Map<String, dynamic>>[];

    for (final row in normalized.data!) {
      final map = <String, dynamic>{};
      for (int i = 0; i < columnNames.length; i++) {
        map[columnNames[i]] = row[i];
      }
      result.add(map);
    }

    return result;
  }

  /// Convert list of maps to JSONC format
  ///
  /// Example:
  /// Maps: [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]
  /// Schema: {"id": 40000, "name": 70000}
  /// Result: JSONC with data [[1, "John"], [2, "Jane"]]
  static JsonC fromMaps(
    List<Map<String, dynamic>> maps,
    Map<String, int> schema, {
    required int jv,
    required int jid,
    int? jnf,
  }) {
    if (maps.isEmpty) {
      return JsonC(jv: jv, jid: jid, jnf: jnf, schema: schema, data: []);
    }

    final columnNames = schema.keys.toList();
    final data = <List<dynamic>>[];

    for (final map in maps) {
      final row = <dynamic>[];
      for (final columnName in columnNames) {
        row.add(map[columnName]);
      }
      data.add(row);
    }

    return JsonC(
      jv: jv,
      jid: jid,
      jnf: jnf,
      schema: schema,
      data: data,
    ).normalizeInt64();
  }

  /// Get PostgreSQL CREATE TABLE DDL from JSONC schema
  ///
  /// Example:
  /// ```dart
  /// final ddl = JConverter.toCreateTableDDL(jsonc, 'products');
  /// // CREATE TABLE products (
  /// //   id integer,
  /// //   name text,
  /// //   price numeric(10,2)
  /// // );
  /// ```
  static String toCreateTableDDL(JsonC jsonc, String tableName) {
    if (!jsonc.hasSchema) {
      throw ArgumentError('JSONC must have schema to generate DDL');
    }

    final columns = <String>[];

    for (final entry in jsonc.schema!.entries) {
      final columnName = entry.key;
      final dataTypeId = entry.value;
      final pgType = getPostgresType(dataTypeId);

      if (pgType == null) {
        throw ArgumentError('Invalid data type ID: $dataTypeId');
      }

      columns.add('  $columnName $pgType');
    }

    return 'CREATE TABLE $tableName (\n${columns.join(',\n')}\n);';
  }

  /// Merge schema-only and data-only JSONC into full JSONC
  ///
  /// Use when schema is sent separately from data
  static JsonC merge(JsonC schemaJsonc, JsonC dataJsonc) {
    if (!schemaJsonc.hasSchema) {
      throw ArgumentError('First JSONC must have schema');
    }

    if (!dataJsonc.hasData) {
      throw ArgumentError('Second JSONC must have data');
    }

    // Validate JID match
    if (schemaJsonc.jid != dataJsonc.jid) {
      throw ArgumentError(
        'Schema JID (${schemaJsonc.jid}) does not match data JID (${dataJsonc.jid})',
      );
    }

    return JsonC(
      jv: schemaJsonc.jv,
      jid: schemaJsonc.jid,
      jnf: dataJsonc.jnf,
      schema: schemaJsonc.schema,
      data: dataJsonc.data,
    ).normalizeInt64();
  }

  /// Extract schema from full JSONC (for sending schema separately)
  static JsonC extractSchema(JsonC jsonc) {
    if (!jsonc.hasSchema) {
      throw ArgumentError('JSONC must have schema');
    }

    return JsonC(jv: jsonc.jv, jid: jsonc.jid, schema: jsonc.schema);
  }

  /// Extract data from full JSONC (for sending data without schema)
  static JsonC extractData(JsonC jsonc) {
    if (!jsonc.hasData) {
      throw ArgumentError('JSONC must have data');
    }

    return JsonC(
      jv: jsonc.jv,
      jid: jsonc.jid,
      jnf: jsonc.jnf,
      data: jsonc.data,
    );
  }

  /// Get column metadata
  static List<Map<String, dynamic>> getColumnMetadata(JsonC jsonc) {
    if (!jsonc.hasSchema) {
      throw ArgumentError('JSONC must have schema');
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in jsonc.schema!.entries) {
      final columnName = entry.key;
      final dataTypeId = entry.value;
      final pgType = getPostgresType(dataTypeId);
      final dataType = DataType.fromId(dataTypeId);

      result.add({
        'name': columnName,
        'dataTypeId': dataTypeId,
        'postgresType': pgType,
        'typeName': dataType?.name,
        'isNumeric': DataTypeRegistry.isValidNumeric(dataTypeId),
        'isText': DataTypeRegistry.isValidText(dataTypeId),
        'isBase': dataType != null,
      });
    }

    return result;
  }
}
