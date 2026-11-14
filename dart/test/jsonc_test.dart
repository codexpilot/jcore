import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JsonC construction', () {
    test('creates full JSONC with schema and data', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      expect(jsonc.jv, equals(1));
      expect(jsonc.jid, equals(12345));
      expect(jsonc.hasSchema, isTrue);
      expect(jsonc.hasData, isTrue);
      expect(jsonc.type, equals(JsonCType.full));
      expect(jsonc.columnCount, equals(2));
      expect(jsonc.rowCount, equals(2));
    });

    test('creates schema-only JSONC', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
      );

      expect(jsonc.hasSchema, isTrue);
      expect(jsonc.hasData, isFalse);
      expect(jsonc.type, equals(JsonCType.schemaOnly));
    });

    test('creates data-only JSONC', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
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
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
          [2, 'Jane'],
        ],
      );

      expect(jsonc.isValid, isTrue);
    });

    test('rejects JSONC without schema and data', () {
      final jsonc = JsonC(jv: 1, jid: 12345);

      expect(jsonc.isValid, isFalse);
    });

    test('rejects JSONC with mismatched row length', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
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
    test('converts to JSON map', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000},
        data: [
          [1, 'John'],
        ],
      );

      final json = jsonc.toJson();

      expect(json['jv'], equals(1));
      expect(json['jid'], equals(12345));
      expect(json['schema'], equals({'id': 40000, 'name': 70000}));
      expect(
        json['data'],
        equals([
          [1, 'John'],
        ]),
      );
    });

    test('creates from JSON map', () {
      final json = {
        'jv': 1,
        'jid': 12345,
        'schema': {'id': 40000, 'name': 70000},
        'data': [
          [1, 'John'],
        ],
      };

      final jsonc = JsonC.fromJson(json);

      expect(jsonc.jv, equals(1));
      expect(jsonc.jid, equals(12345));
      expect(jsonc.schema, equals({'id': 40000, 'name': 70000}));
      expect(
        jsonc.data,
        equals([
          [1, 'John'],
        ]),
      );
    });

    test('encodes to JSON string', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      final jsonString = jsonc.encode();

      expect(jsonString, contains('"jv":1'));
      expect(jsonString, contains('"jid":12345'));
    });

    test('parses from JSON string', () {
      final jsonString =
          '{"jv":1,"jid":12345,"schema":{"id":40000},"data":[[1]]}';

      final jsonc = JsonC.parse(jsonString);

      expect(jsonc.jv, equals(1));
      expect(jsonc.jid, equals(12345));
    });
  });

  group('JsonC helpers', () {
    test('gets column names', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 12345,
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
        jv: 1,
        jid: 12345,
        schema: {'id': 40000, 'name': 70000, 'price': 61002},
      );

      final typeIds = jsonc.dataTypeIds;

      expect(typeIds, hasLength(3));
      expect(typeIds, contains(40000));
      expect(typeIds, contains(70000));
      expect(typeIds, contains(61002));
    });
  });

  group('JsonC equality', () {
    test('equal JSONC instances are equal', () {
      final jsonc1 = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      final jsonc2 = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 40000},
        data: [
          [1],
        ],
      );

      expect(jsonc1, equals(jsonc2));
    });

    test('different JSONC instances are not equal', () {
      final jsonc1 = JsonC(jv: 1, jid: 12345, schema: {'id': 40000});

      final jsonc2 = JsonC(
        jv: 1,
        jid: 12346, // Different jid
        schema: {'id': 40000},
      );

      expect(jsonc1, isNot(equals(jsonc2)));
    });
  });

  group('Real-world examples', () {
    test('product catalog example', () {
      final jsonc = JsonC(
        jv: 1,
        jid: 1001,
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
        jv: 1,
        jid: 2001,
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
  });
}
