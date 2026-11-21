import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JsonC construction', () {
    test('creates full JSONC with schema and data', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      expect(jsonc.dataSchemaVersion, equals(1));
      expect(jsonc.resultSchemaId, equals(12345));
      expect(jsonc.hasSchema, isTrue);
      expect(jsonc.hasData, isTrue);
      expect(jsonc.type, equals(JsonCType.full));
      expect(jsonc.columnCount, equals(2));
      expect(jsonc.rowCount, equals(2));
    });

    test('creates schema-only JSONC', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000},
      );

      expect(jsonc.hasSchema, isTrue);
      expect(jsonc.hasData, isFalse);
      expect(jsonc.type, equals(JsonCType.schemaOnly));
    });

    test('creates data-only JSONC', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      expect(jsonc.hasSchema, isFalse);
      expect(jsonc.hasData, isTrue);
      expect(jsonc.type, equals(JsonCType.dataOnly));
    });
  });

  group('JsonC validation', () {
    test('validates correct JSONC', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      expect(jsonc.isValid, isTrue);
    });

    test('rejects JSONC without schema and data', () {
      final jsonc = JsonC(dataSchemaVersion: 1, resultSchemaId: 12345);

      expect(jsonc.isValid, isFalse);
    });

    test('rejects JSONC with mismatched row length', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane', 'Extra'], // Wrong length
        ],
      );

      expect(jsonc.isValid, isFalse);
    });
  });

  group('JsonC JSON serialization', () {
    test('converts to JSON map with canonical names', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
        ],
      );

      final json = jsonc.toJson();

      expect(json['dataSchemaVersion'], equals(1));
      expect(json['resultSchemaId'], equals(12345));
      expect(json['schema'], equals({'id': 40000, 'name': 70000}));
      expect(
        json['data'],
        equals([
          [1, 'John'],
        ]),
      );
    });

    test('creates from JSON map with canonical names', () {
      final json = {
        'dataSchemaVersion': 1,
        'resultSchemaId': 12345,
        'schema': {'id': 40000, 'name': 70000},
        'data': [
          [1, 'John'],
        ],
      };

      final jsonc = JsonC.fromJson(json);

      expect(jsonc.dataSchemaVersion, equals(1));
      expect(jsonc.resultSchemaId, equals(12345));
      expect(jsonc.schema, equals({'id': 40000, 'name': 70000}));
      expect(
        jsonc.data,
        equals([
          [1, 'John'],
        ]),
      );
    });

    test('encodes to JSON string with canonical names', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      final jsonString = jsonc.encode();

      expect(jsonString, contains('"dataSchemaVersion":1'));
      expect(jsonString, contains('"resultSchemaId":12345'));
    });

    test('parses from JSON string with canonical names', () {
      final jsonString =
          '{"dataSchemaVersion":1,"resultSchemaId":12345,"schema":{"id":40000},"data":[[1]]}';

      final jsonc = JsonC.parse(jsonString);

      expect(jsonc.dataSchemaVersion, equals(1));
      expect(jsonc.resultSchemaId, equals(12345));
    });
  });

  group('JsonC helpers', () {
    test('gets column names', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000, 'price': 61002},
      );

      final names = jsonc.columnNames;

      expect(names, hasLength(3));
      expect(names, contains('id'));
      expect(names, contains('name'));
      expect(names, contains('price'));
    });

    test('gets data type IDs', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000, 'name': 70000, 'price': 61002},
      );

      final typeIds = jsonc.dataTypeIds;

      expect(typeIds, hasLength(3));
      expect(typeIds, contains(40000));
      expect(typeIds, contains(70000));
      expect(typeIds, contains(61002));
    });

    test('uses explicit columns ordering', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        columns: ['price', 'id', 'name'], // Explicit order
        schema: {'id': 40000, 'name': 70000, 'price': 61002},
      );

      expect(jsonc.columnNames, equals(['price', 'id', 'name']));
      expect(jsonc.dataTypeIds, equals([61002, 40000, 70000]));
    });
  });

  group('JsonC equality', () {
    test('equal JSONC instances are equal', () {
      final jsonc1 = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      final jsonc2 = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      expect(jsonc1, equals(jsonc2));
    });

    test('different JSONC instances are not equal', () {
      final jsonc1 = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12345,
        schema: {'id': 40000},
      );

      final jsonc2 = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 12346, // Different ID
        schema: {'id': 40000},
      );

      expect(jsonc1, isNot(equals(jsonc2)));
    });
  });

  group('JsonC encoding modes', () {
    test('validates encoding modes 0-5', () {
      for (final mode in [0, 1, 2, 3, 4, 5]) {
        final jsonc = JsonC(
          dataSchemaVersion: 1,
          resultSchemaId: 12345,
          encoding: mode,
        );
        expect(jsonc.isValidEncoding, isTrue, reason: 'Mode $mode');
        expect(jsonc.isExtendedMode, isFalse, reason: 'Mode $mode');
      }
    });

    test('validates extended encoding modes 8-13', () {
      for (final mode in [8, 9, 10, 11, 12, 13]) {
        final jsonc = JsonC(
          dataSchemaVersion: 1,
          resultSchemaId: 12345,
          encoding: mode,
        );
        expect(jsonc.isValidEncoding, isTrue, reason: 'Mode $mode');
        expect(jsonc.isExtendedMode, isTrue, reason: 'Mode $mode');
      }
    });

    test('rejects invalid encoding modes', () {
      for (final mode in [6, 7, 14, 15, 100, -1]) {
        final json = {
          'dataSchemaVersion': 1,
          'resultSchemaId': 12345,
          'encoding': mode,
        };
        expect(
          () => JsonC.fromJson(json),
          throwsFormatException,
          reason: 'Mode $mode should be rejected',
        );
      }
    });

    test('extended mode base calculation', () {
      final tests = {
        8: 0,
        9: 1,
        10: 2,
        11: 3,
        12: 4,
        13: 5,
      };

      tests.forEach((mode, expectedBase) {
        final jsonc = JsonC(
          dataSchemaVersion: 1,
          resultSchemaId: 12345,
          encoding: mode,
        );
        expect(jsonc.baseMode, equals(expectedBase),
            reason: 'Mode $mode should have base $expectedBase');
      });
    });
  });

  group('Real-world examples', () {
    test('product catalog example', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 1001,
        schema: {
          'product_id': 40000, // INT64
          'name': 70000, // TEXT
          'price': 61002, // NUMERIC(10,2)
          'created_at': 40001, // DATETIME
        },
        data: [
          [1, 'Laptop', 999.99, 1699123200000],
          [2, 'Mouse', 29.99, 1699209600000],
          [3, 'Keyboard', 79.99, 1699296000000],
        ],
      );

      expect(jsonc.isValid, isTrue);
      expect(jsonc.columnCount, equals(4));
      expect(jsonc.rowCount, equals(3));
    });

    test('user records example', () {
      final jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 2001,
        schema: {
          'user_id': 40000, // INT64
          'username': 70100, // TEXT(100)
          'email': 70255, // TEXT(255)
          'is_active': 10000, // BOOLEAN
        },
        data: [
          [1, 'john_doe', 'john@example.com', true],
          [2, 'jane_smith', 'jane@example.com', true],
          [3, 'bob_jones', 'bob@example.com', false],
        ],
      );

      expect(jsonc.isValid, isTrue);
      expect(jsonc.type, equals(JsonCType.full));
    });

    test('includes version fields', () {
      final jsonc = JsonC(
        jcore: '4.5.0',
        mjux: '0.2.0',
        appx: 'ContextStudio 1.0.0 (build 123)',
        dataSchemaVersion: 1737849600,
        uxSchemaVersion: 2,
        resultSchemaId: 5001,
        encoding: 13,
        schema: {'id': 40000},
      );

      final json = jsonc.toJson();
      expect(json['jcore'], equals('4.5.0'));
      expect(json['mjux'], equals('0.2.0'));
      expect(json['appx'], equals('ContextStudio 1.0.0 (build 123)'));
      expect(json['uxSchemaVersion'], equals(2));
    });
  });
}
