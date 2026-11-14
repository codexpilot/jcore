import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  // Reset JBase before each test
  setUp(() {
    JBase.instance.clear();
  });

  group('JBase singleton', () {
    test('is singleton', () {
      final instance1 = JBase.instance;
      final instance2 = JBase.instance;

      expect(identical(instance1, instance2), isTrue);
    });

    test('starts empty', () {
      expect(JBase.instance.isEmpty, isTrue);
      expect(JBase.instance.count, equals(0));
    });
  });

  group('JBase register', () {
    test('registers schema', () {
      final schema = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003, 'name': 300008},
      );

      JBase.instance.register(schema);

      expect(JBase.instance.has(12345), isTrue);
      expect(JBase.instance.count, equals(1));
    });

    test('registers schema from full JSONC', () {
      final full = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003, 'name': 300008},
        data: [[1, 'John']],
      );

      final registered = JBase.instance.register(full);

      expect(registered.hasSchema, isTrue);
      expect(registered.hasData, isFalse); // Only schema stored
    });

    test('throws when registering JSONC without schema', () {
      final dataOnly = JsonC(
        jv: 1,
        jid: 12345,
        data: [[1, 'John']],
      );

      expect(
        () => JBase.instance.register(dataOnly),
        throwsArgumentError,
      );
    });

    test('replaces existing schema with same JID', () {
      final schema1 = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003},
      );

      final schema2 = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003, 'name': 300008}, // More columns
      );

      JBase.instance.register(schema1);
      JBase.instance.register(schema2);

      final retrieved = JBase.instance.get(12345);
      expect(retrieved!.columnCount, equals(2)); // Updated
    });

    test('registers multiple schemas', () {
      final schemas = [
        JsonC(jv: 1, jid: 1001, schema: {'id': 300003}),
        JsonC(jv: 1, jid: 1002, schema: {'name': 300008}),
        JsonC(jv: 1, jid: 1003, schema: {'price': 310020}),
      ];

      final count = JBase.instance.registerAll(schemas);

      expect(count, equals(3));
      expect(JBase.instance.count, equals(3));
    });
  });

  group('JBase get', () {
    test('retrieves registered schema', () {
      final schema = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003, 'name': 300008},
      );

      JBase.instance.register(schema);
      final retrieved = JBase.instance.get(12345);

      expect(retrieved, isNotNull);
      expect(retrieved!.jid, equals(12345));
      expect(retrieved.columnCount, equals(2));
    });

    test('returns null for non-existent JID', () {
      final retrieved = JBase.instance.get(99999);

      expect(retrieved, isNull);
    });

    test('getOrThrow throws for non-existent JID', () {
      expect(
        () => JBase.instance.getOrThrow(99999),
        throwsStateError,
      );
    });
  });

  group('JBase remove', () {
    test('removes schema', () {
      final schema = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003},
      );

      JBase.instance.register(schema);
      expect(JBase.instance.has(12345), isTrue);

      final removed = JBase.instance.remove(12345);

      expect(removed, isTrue);
      expect(JBase.instance.has(12345), isFalse);
    });

    test('returns false when removing non-existent schema', () {
      final removed = JBase.instance.remove(99999);

      expect(removed, isFalse);
    });
  });

  group('JBase clear', () {
    test('clears all schemas', () {
      JBase.instance.registerAll([
        JsonC(jv: 1, jid: 1001, schema: {'id': 300003}),
        JsonC(jv: 1, jid: 1002, schema: {'name': 300008}),
      ]);

      expect(JBase.instance.count, equals(2));

      JBase.instance.clear();

      expect(JBase.instance.isEmpty, isTrue);
      expect(JBase.instance.count, equals(0));
    });
  });

  group('JBase mergeWithSchema', () {
    test('merges data-only JSONC with registered schema', () {
      final schema = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003, 'name': 300008},
      );

      JBase.instance.register(schema);

      final dataOnly = JsonC(
        jv: 1,
        jid: 12345,
        data: [[1, 'John'], [2, 'Jane']],
      );

      final merged = JBase.instance.mergeWithSchema(dataOnly);

      expect(merged.hasSchema, isTrue);
      expect(merged.hasData, isTrue);
      expect(merged.rowCount, equals(2));
    });

    test('throws when schema not registered', () {
      final dataOnly = JsonC(
        jv: 1,
        jid: 99999,
        data: [[1, 'John']],
      );

      expect(
        () => JBase.instance.mergeWithSchema(dataOnly),
        throwsStateError,
      );
    });

    test('throws when JSONC has no data', () {
      final schemaOnly = JsonC(
        jv: 1,
        jid: 12345,
        schema: {'id': 300003},
      );

      expect(
        () => JBase.instance.mergeWithSchema(schemaOnly),
        throwsArgumentError,
      );
    });
  });

  group('JBase metadata', () {
    test('gets all JIDs', () {
      JBase.instance.registerAll([
        JsonC(jv: 1, jid: 1001, schema: {'id': 300003}),
        JsonC(jv: 1, jid: 1002, schema: {'name': 300008}),
        JsonC(jv: 1, jid: 1003, schema: {'price': 310020}),
      ]);

      final jids = JBase.instance.jids;

      expect(jids, hasLength(3));
      expect(jids, containsAll([1001, 1002, 1003]));
    });

    test('gets metadata for all schemas', () {
      JBase.instance.register(
        JsonC(
          jv: 1,
          jid: 12345,
          schema: {'id': 300003, 'name': 300008, 'price': 310020},
        ),
      );

      final metadata = JBase.instance.getMetadata();

      expect(metadata, hasLength(1));
      expect(metadata[0]['jid'], equals(12345));
      expect(metadata[0]['columnCount'], equals(3));
      expect(metadata[0]['columns'], equals(['id', 'name', 'price']));
    });
  });

  group('JBase export/import', () {
    test('exports schemas to JSON', () {
      JBase.instance.registerAll([
        JsonC(jv: 1, jid: 1001, schema: {'id': 300003}),
        JsonC(jv: 1, jid: 1002, schema: {'name': 300008}),
      ]);

      final exported = JBase.instance.export();

      expect(exported, hasLength(2));
      expect(exported[0]['jid'], isA<int>());
      expect(exported[0]['schema'], isA<Map>());
    });

    test('imports schemas from JSON', () {
      final jsonList = [
        {'jv': 1, 'jid': 1001, 'schema': {'id': 300003}},
        {'jv': 1, 'jid': 1002, 'schema': {'name': 300008}},
      ];

      final count = JBase.instance.import(jsonList);

      expect(count, equals(2));
      expect(JBase.instance.has(1001), isTrue);
      expect(JBase.instance.has(1002), isTrue);
    });

    test('skips invalid schemas during import', () {
      final jsonList = [
        {'jv': 1, 'jid': 1001, 'schema': {'id': 300003}}, // Valid
        {'jv': 1, 'jid': 1002}, // Invalid - no schema
        {'invalid': 'data'}, // Invalid - bad structure
      ];

      final count = JBase.instance.import(jsonList);

      expect(count, equals(1)); // Only one imported
    });
  });

  group('JBase search', () {
    setUp(() {
      JBase.instance.registerAll([
        JsonC(jv: 1, jid: 1001, schema: {'user_id': 300003, 'name': 300008}),
        JsonC(jv: 1, jid: 1002, schema: {'product_id': 300003, 'price': 310020}),
        JsonC(jv: 1, jid: 1003, schema: {'order_id': 300003, 'user_id': 300003}),
      ]);
    });

    test('finds schemas by column name', () {
      final jids = JBase.instance.findByColumn('user_id');

      expect(jids, hasLength(2));
      expect(jids, containsAll([1001, 1003]));
    });

    test('finds schemas by data type', () {
      final jids = JBase.instance.findByDataType(300003); // INT64

      expect(jids, hasLength(3)); // All have INT64
    });

    test('returns empty list when no matches', () {
      final jids = JBase.instance.findByColumn('nonexistent');

      expect(jids, isEmpty);
    });
  });

  group('Real-world scenario', () {
    test('schema caching workflow', () {
      // Step 1: Server sends schema definition (once)
      final schemaPayload = {
        'jv': 1,
        'jid': 5001,
        'schema': {
          'user_id': 300003,
          'username': 301008,
          'email': 302558,
          'is_active': 300001,
        }
      };

      final schema = JsonC.fromJson(schemaPayload);
      JBase.instance.register(schema);

      // Step 2: Server sends data-only payloads (efficient)
      final dataBatch1 = JsonC.fromJson({
        'jv': 1,
        'jid': 5001,
        'data': [
          [1, 'alice', 'alice@example.com', true],
          [2, 'bob', 'bob@example.com', true],
        ]
      });

      final dataBatch2 = JsonC.fromJson({
        'jv': 1,
        'jid': 5001,
        'data': [
          [3, 'charlie', 'charlie@example.com', false],
        ]
      });

      // Step 3: Client merges with cached schema
      final full1 = JBase.instance.mergeWithSchema(dataBatch1);
      final full2 = JBase.instance.mergeWithSchema(dataBatch2);

      expect(full1.hasSchema, isTrue);
      expect(full1.rowCount, equals(2));
      expect(full2.hasSchema, isTrue);
      expect(full2.rowCount, equals(1));

      // Step 4: Convert to maps for UI
      final users1 = JsonCConverter.toMaps(full1);
      final users2 = JsonCConverter.toMaps(full2);

      expect(users1[0]['username'], equals('alice'));
      expect(users2[0]['username'], equals('charlie'));
    });
  });
}
