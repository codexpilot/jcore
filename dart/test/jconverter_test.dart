import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JConverter validation', () {
    test('validates correct JSONC', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isEmpty);
    });

    test('detects invalid data type in schema', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 999999}, // Invalid type ID
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('Invalid data type'));
    });

    test('detects row length mismatch', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John', 'Extra'], // Too many values
        ],
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('has 3 values, expected 2'));
    });

    test('validates type compatibility - boolean', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'is_active': 10000}, // BOOLEAN
        data: [
          ['not a boolean'], // Wrong type
        ],
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('expected bool'));
    });

    test('validates type compatibility - integer', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000}, // INT64
        data: [
          ['not an int'], // Wrong type
        ],
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('expected int'));
    });

    test('validates TEXT length constraint', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'code': 300028}, // TEXT(2) - only 2 characters allowed
        data: [
          ['ABC'], // 3 characters - exceeds limit
        ],
      );

      final errors = JConverter.validate(jsonc);

      expect(errors, isNotEmpty);
      expect(errors.first, contains('exceeds max'));
    });
  });

  group('JConverter toMaps', () {
    test('converts JSONC data to list of maps', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000, 'age': 30000},
        data: [
          [1, 'John', 30],
          [2, 'Jane', 25],
        ],
      );

      final maps = JConverter.toMaps(jsonc);

      expect(maps, hasLength(2));
      expect(maps[0], equals({'id': 1, 'name': 'John', 'age': 30}));
      expect(maps[1], equals({'id': 2, 'name': 'Jane', 'age': 25}));
    });

    test('throws when JSONC lacks schema', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        data: [
          [1, 'John'],
        ],
      );

      expect(() => JConverter.toMaps(jsonc), throwsArgumentError);
    });

    test('throws when JSONC lacks data', () {
      final jsonc = JsonC(jv: 1, jid: 12345, schema: {'id': 40000});

      expect(() => JConverter.toMaps(jsonc), throwsArgumentError);
    });
  });

  group('JConverter fromMaps', () {
    test('converts list of maps to JSONC', () {
      final maps = [
        {'id': 1, 'name': 'John'},
        {'id': 2, 'name': 'Jane'},
      ];

      final schema = {'id': 40000, 'name': 70000};

      final jsonc = JConverter.fromMaps(maps, schema, jv: 1, jid: 12345);

      expect(jsonc.jv, equals(1));
      expect(jsonc.jid, equals(12345));
      expect(jsonc.schema, equals(schema));
      expect(
        jsonc.data,
        equals([
          [1, 'John'],
          [2, 'Jane'],
        ]),
      );
    });

    test('handles empty maps list', () {
      final jsonc = JConverter.fromMaps([], {'id': 40000}, jv: 1, jid: 12345);

      expect(jsonc.data, isEmpty);
      expect(jsonc.hasSchema, isTrue);
    });
  });

  group('JConverter toCreateTableDDL', () {
    test('generates PostgreSQL CREATE TABLE statement', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {
          'id': 40000, // INT64 -> bigint
          'name': 70000, // TEXT -> text
          'price': 310020, // NUMERIC(10,2)
        },
      );

      final ddl = JConverter.toCreateTableDDL(jsonc, 'products');

      expect(ddl, contains('CREATE TABLE products'));
      expect(ddl, contains('id bigint'));
      expect(ddl, contains('name text'));
      expect(ddl, contains('price numeric(10,2)'));
    });

    test('throws when JSONC lacks schema', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        data: [
          [1],
        ],
      );

      expect(
        () => JConverter.toCreateTableDDL(jsonc, 'test'),
        throwsArgumentError,
      );
    });
  });

  group('JConverter merge', () {
    test('merges schema-only and data-only JSONC', () {
      final schemaJsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
      );

      final dataJsonc = JsonC(
        jv: 1,
        jid: 12345,
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      final merged = JConverter.merge(schemaJsonc, dataJsonc);

      expect(merged.hasSchema, isTrue);
      expect(merged.hasData, isTrue);
      expect(merged.type, equals(JsonCType.full));
      expect(merged.jid, equals(12345));
    });

    test('throws on JID mismatch', () {
      final schemaJsonc = JsonC(jv: 1, jid: 12345, schema: {'id': 40000});

      final dataJsonc = JsonC(
        jv: 1,
        jid: 99999, // Different JID
        data: [
          [1],
        ],
      );

      expect(
        () => JConverter.merge(schemaJsonc, dataJsonc),
        throwsArgumentError,
      );
    });
  });

  group('JConverter extract', () {
    test('extracts schema from full JSONC', () {
      final fullJsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
        ],
      );

      final schemaOnly = JConverter.extractSchema(fullJsonc);

      expect(schemaOnly.hasSchema, isTrue);
      expect(schemaOnly.hasData, isFalse);
      expect(schemaOnly.type, equals(JsonCType.schemaOnly));
    });

    test('extracts data from full JSONC', () {
      final fullJsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
        ],
      );

      final dataOnly = JConverter.extractData(fullJsonc);

      expect(dataOnly.hasSchema, isFalse);
      expect(dataOnly.hasData, isTrue);
      expect(dataOnly.type, equals(JsonCType.dataOnly));
    });
  });

  group('JConverter getColumnMetadata', () {
    test('returns column metadata', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {
          'id': 40000, // INT64
          'price': 310020, // NUMERIC(10,2)
          'name': 301008, // TEXT(100)
        },
      );

      final metadata = JConverter.getColumnMetadata(jsonc);

      expect(metadata, hasLength(3));

      final idCol = metadata.firstWhere((m) => m['name'] == 'id');
      expect(idCol['dataTypeId'], equals(40000));
      expect(idCol['postgresType'], equals('bigint'));
      expect(idCol['isBase'], isTrue);

      final priceCol = metadata.firstWhere((m) => m['name'] == 'price');
      expect(priceCol['postgresType'], equals('numeric(10,2)'));
      expect(priceCol['isNumeric'], isTrue);

      final nameCol = metadata.firstWhere((m) => m['name'] == 'name');
      expect(nameCol['postgresType'], equals('text(100)'));
      expect(nameCol['isText'], isTrue);
    });
  });

  group('Real-world scenarios', () {
    test('API response scenario', () {
      // Simulating aixhub sending data to contextstudio
      final apiResponse = {
        'jv': 1,
        'jid': 5001,
        'schema': {
          'user_id': 40000,
          'username': 301008,
          'email': 302558,
          'created_at': 40001,
        },
        'data': [
          [1, 'alice', 'alice@example.com', 1699123200000],
          [2, 'bob', 'bob@example.com', 1699209600000],
        ],
      };

      final jsonc = JsonC.fromJson(apiResponse);
      final errors = JConverter.validate(jsonc);

      expect(errors, isEmpty);
      expect(jsonc.rowCount, equals(2));

      // Convert to maps for UI
      final users = JConverter.toMaps(jsonc);
      expect(users[0]['username'], equals('alice'));
      expect(users[1]['username'], equals('bob'));
    });

    test('Schema definition scenario', () {
      // contextstudio defining a new table structure
      final tableSchema = JsonC(
        jv: 1,
        jid: 6001,
        schema: {
          'product_id': 40000,
          'sku': 300108, // TEXT(10)
          'name': 302008, // TEXT(200)
          'price': 310020, // NUMERIC(10,2)
          'stock': 30000, // INT32
          'is_active': 10000, // BOOLEAN
        },
      );

      final ddl = JConverter.toCreateTableDDL(tableSchema, 'products');

      expect(ddl, contains('CREATE TABLE products'));
      expect(ddl, contains('product_id bigint'));
      expect(ddl, contains('price numeric(10,2)'));
      expect(ddl, contains('is_active boolean'));
    });

    test('Incremental data loading scenario', () {
      // First: Send schema
      final schemaJsonc = JsonC(
        jv: 1,
        jid: 7001,
        schema: {'id': 40000, 'value': 70000},
      );

      // Later: Send data batches with same JID
      final batch1 = JsonC(
        jv: 1,
        jid: 7001,
        data: [
          [1, 'First'],
          [2, 'Second'],
        ],
      );

      final batch2 = JsonC(
        jv: 1,
        jid: 7001,
        data: [
          [3, 'Third'],
          [4, 'Fourth'],
        ],
      );

      // Merge schema with each batch
      final full1 = JConverter.merge(schemaJsonc, batch1);
      final full2 = JConverter.merge(schemaJsonc, batch2);

      expect(full1.rowCount, equals(2));
      expect(full2.rowCount, equals(2));
    });
  });
}
