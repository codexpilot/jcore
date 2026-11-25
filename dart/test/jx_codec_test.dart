import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JxEncoding', () {
    test('parses default encoding 8000', () {
      final enc = JxEncoding.parse(8000);
      expect(enc.j, equals(8));
      expect(enc.n, equals(0));
      expect(enc.l, equals(0));
      expect(enc.d, equals(0));
      expect(enc.toInt(), equals(8000));
    });

    test('parses encoding 8018', () {
      final enc = JxEncoding.parse(8018);
      expect(enc.j, equals(8));
      expect(enc.n, equals(0));
      expect(enc.l, equals(1));
      expect(enc.d, equals(8));
    });

    test('parses compact encoding 1000', () {
      final enc = JxEncoding.parse(1000);
      expect(enc.j, equals(1));
      expect(enc.isCompact, isTrue);
      expect(enc.hasMetadata, isFalse);
    });

    test('parses compact with metadata 2000', () {
      final enc = JxEncoding.parse(2000);
      expect(enc.j, equals(2));
      expect(enc.isCompact, isTrue);
      expect(enc.hasMetadata, isTrue);
    });

    test('validates J values', () {
      expect(() => JxEncoding.parse(5000), throwsFormatException);
      expect(() => JxEncoding.parse(6000), throwsFormatException);
      expect(() => JxEncoding.parse(7000), throwsFormatException);
    });

    test('validates N values', () {
      expect(() => JxEncoding.parse(8200), throwsFormatException);
      expect(() => JxEncoding.parse(8900), throwsFormatException);
    });

    test('validates L values', () {
      expect(() => JxEncoding.parse(8020), throwsFormatException);
      expect(() => JxEncoding.parse(8090), throwsFormatException);
    });

    test('validates D values', () {
      expect(() => JxEncoding.parse(8003), throwsFormatException);
      expect(() => JxEncoding.parse(8009), throwsFormatException);
    });

    test('validates range', () {
      expect(() => JxEncoding.parse(-1), throwsFormatException);
      expect(() => JxEncoding.parse(10000), throwsFormatException);
    });
  });

  group('JxSchema', () {
    test('creates schema with fields', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
        JxField(i: 2, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
      ]);

      expect(schema.fieldCount, equals(2));
      expect(schema.fields[0].c, equals('id'));
      expect(schema.fields[1].c, equals('name'));
    });

    test('validates unique names', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
        JxField(i: 2, c: 'name', n: 'ID', typeId: 10000, typeName: 'TEXT'),
      ]);

      expect(() => schema.validateUniqueNames(), throwsFormatException);
    });

    test('validates unique codes', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
        JxField(i: 2, c: 'id', n: 'Name', typeId: 10000, typeName: 'TEXT'),
      ]);

      expect(() => schema.validateUniqueCodes(), throwsFormatException);
    });
  });

  group('JxBody', () {
    test('creates body with data only', () {
      final body = JxBody(data: [
        [1, 'John']
      ]);

      expect(body.data, hasLength(1));
      expect(body.meta, isNull);
    });

    test('creates body with metadata', () {
      final body = JxBody(
        meta: [
          ['id', 'INT64'],
          ['name', 'TEXT']
        ],
        data: [
          [1, 'John']
        ],
      );

      expect(body.meta, hasLength(2));
      expect(body.data, hasLength(1));
    });

    test('converts to JSON', () {
      final body = JxBody(data: [
        [1, 'John']
      ]);

      final json = body.toJson();
      expect(json['data'], hasLength(1));
      expect(json.containsKey('meta'), isFalse);
    });

    test('parses from JSON string', () {
      final jsonStr = '{"data":[[1,"John"]]}';
      final body = JxBody.parse(jsonStr);

      expect(body.data, hasLength(1));
      expect(body.data[0][0], equals(1));
      expect(body.data[0][1], equals('John'));
    });
  });

  group('JxCodec - 8000 encoding (default)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'amount', n: 'Amount', typeId: 21002, typeName: 'NUMERIC(10,2)'),
      JxField(i: 3, c: 'observed_at', n: 'Observed At', typeId: 4, typeName: 'DATETIME'),
    ]);

    test('encodes full objects with code keys', () {
      final rows = [
        [BigInt.from(9223372036854775807), Numeric('1234.50'), 1704067200123],
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      expect(body.data, hasLength(1));
      expect(body.meta, isNull);

      final row = body.data[0] as Map;
      expect(row['id'], equals('9223372036854775807'));
      expect(row['amount'], equals('1234.50'));
      expect(row['observed_at'], isA<String>());
      expect(row['observed_at'], endsWith('Z'));
    });

    test('encodes scalar as one row with one cell', () {
      final scalarSchema = JxSchema([
        JxField(i: 1, c: 'count', n: 'Count', typeId: 3, typeName: 'INT64'),
      ]);

      final rows = [
        [BigInt.from(42)]
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: scalarSchema);

      expect(body.data, hasLength(1));
      final row = body.data[0] as Map;
      expect(row['count'], equals('42'));
    });

    test('encodes empty result', () {
      final body = JxCodec.encode(encoding: 8000, rows: [], schema: schema);

      expect(body.data, isEmpty);
      expect(body.meta, isNull);
    });

    test('decodes full objects with code keys', () {
      final body = JxBody(data: [
        {'id': '9223372036854775807', 'amount': '1234.50', 'observed_at': '2024-01-01T00:00:00.123Z'}
      ]);

      final rows = JxCodec.decode(encoding: 8000, body: body, schema: schema);

      expect(rows, hasLength(1));
      expect(rows[0][0], isA<BigInt>());
      expect(rows[0][0].toString(), equals('9223372036854775807'));
      expect(rows[0][1], isA<Numeric>());
      expect(rows[0][1].toString(), equals('1234.50'));
      expect(rows[0][2], isA<int>());
    });
  });

  group('JxCodec - 8018 encoding (native client)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'amount', n: 'Amount', typeId: 21002, typeName: 'NUMERIC(10,2)'),
      JxField(i: 3, c: 'observed_at', n: 'Observed At', typeId: 4, typeName: 'DATETIME'),
    ]);

    test('encodes INT64 as JSON integers', () {
      final rows = [
        [BigInt.from(42), Numeric('1234.50'), 1704067200123],
      ];

      final body = JxCodec.encode(encoding: 8018, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['id'], equals(42));
      expect(row['id'], isA<int>());
    });

    test('encodes NUMERIC as strings', () {
      final rows = [
        [BigInt.from(42), Numeric('1234.50'), 1704067200123],
      ];

      final body = JxCodec.encode(encoding: 8018, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['amount'], equals('1234.50'));
      expect(row['amount'], isA<String>());
    });

    test('encodes DATETIME as epoch milliseconds', () {
      final rows = [
        [BigInt.from(42), Numeric('1234.50'), 1704067200123],
      ];

      final body = JxCodec.encode(encoding: 8018, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['observed_at'], equals(1704067200123));
      expect(row['observed_at'], isA<int>());
    });
  });

  group('JxCodec - 9000 encoding (objects by name)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
    ]);

    test('encodes full objects with name keys', () {
      final rows = [
        [BigInt.from(1), 'John'],
      ];

      final body = JxCodec.encode(encoding: 9000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['ID'], equals('1'));
      expect(row['Name'], equals('John'));
      expect(row.containsKey('id'), isFalse);
      expect(row.containsKey('name'), isFalse);
    });

    test('rejects duplicate field names', () {
      final badSchema = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
        JxField(i: 2, c: 'name', n: 'ID', typeId: 10000, typeName: 'TEXT'),
      ]);

      final rows = [
        [BigInt.from(1), 'John']
      ];

      expect(
        () => JxCodec.encode(encoding: 9000, rows: rows, schema: badSchema),
        throwsFormatException,
      );
    });
  });

  group('JxCodec - 1000 encoding (compact positional)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
    ]);

    test('encodes compact positional rows', () {
      final rows = [
        [BigInt.from(1), 'John'],
        [BigInt.from(2), 'Jane'],
      ];

      final body = JxCodec.encode(encoding: 1000, rows: rows, schema: schema);

      expect(body.data, hasLength(2));
      expect(body.meta, isNull);
      expect(body.data[0], equals(['1', 'John']));
      expect(body.data[1], equals(['2', 'Jane']));
    });

    test('validates row length matches schema', () {
      final rows = [
        [BigInt.from(1), 'John', 'Extra'],
      ];

      expect(
        () => JxCodec.encode(encoding: 1000, rows: rows, schema: schema),
        throwsFormatException,
      );
    });

    test('decodes compact positional rows', () {
      final body = JxBody(data: [
        ['1', 'John'],
        ['2', 'Jane'],
      ]);

      final rows = JxCodec.decode(encoding: 1000, body: body, schema: schema);

      expect(rows, hasLength(2));
      expect(rows[0][0], isA<BigInt>());
      expect(rows[0][0].toString(), equals('1'));
      expect(rows[0][1], equals('John'));
    });

    test('requires schema for decoding', () {
      final body = JxBody(data: [
        ['1', 'John']
      ]);

      expect(
        () => JxCodec.decode(encoding: 1000, body: body),
        throwsArgumentError,
      );
    });
  });

  group('JxCodec - 2000 encoding (compact with meta by ID)', () {
    final schema = JxSchema([
      JxField(i: 101, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 102, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
    ]);

    test('includes metadata with field ID and type ID', () {
      final rows = [
        [BigInt.from(1), 'John']
      ];

      final body = JxCodec.encode(encoding: 2000, rows: rows, schema: schema);

      expect(body.meta, hasLength(2));
      expect(body.meta![0], equals([101, 3]));
      expect(body.meta![1], equals([102, 10000]));
      expect(body.data[0], equals(['1', 'John']));
    });
  });

  group('JxCodec - 3000 encoding (compact with meta by code)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
    ]);

    test('includes metadata with field code and type name', () {
      final rows = [
        [BigInt.from(1), 'John']
      ];

      final body = JxCodec.encode(encoding: 3000, rows: rows, schema: schema);

      expect(body.meta, hasLength(2));
      expect(body.meta![0], equals(['id', 'INT64']));
      expect(body.meta![1], equals(['name', 'TEXT']));
      expect(body.data[0], equals(['1', 'John']));
    });

    test('rejects duplicate field codes', () {
      final badSchema = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
        JxField(i: 2, c: 'id', n: 'Name', typeId: 10000, typeName: 'TEXT'),
      ]);

      final rows = [
        [BigInt.from(1), 'John']
      ];

      expect(
        () => JxCodec.encode(encoding: 3000, rows: rows, schema: badSchema),
        throwsFormatException,
      );
    });
  });

  group('JxCodec - 4000 encoding (compact with meta by name)', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
      JxField(i: 2, c: 'name', n: 'Name', typeId: 10000, typeName: 'TEXT'),
    ]);

    test('includes metadata with field name and type name', () {
      final rows = [
        [BigInt.from(1), 'John']
      ];

      final body = JxCodec.encode(encoding: 4000, rows: rows, schema: schema);

      expect(body.meta, hasLength(2));
      expect(body.meta![0], equals(['ID', 'INT64']));
      expect(body.meta![1], equals(['Name', 'TEXT']));
      expect(body.data[0], equals(['1', 'John']));
    });
  });

  group('JxCodec - TIME handling', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'wake_time', n: 'Wake Time', typeId: 5, typeName: 'TIME'),
    ]);

    test('encodes TIME as HH:mm:ss.SSS (D=0)', () {
      final rows = [
        [32523456] // 09:02:03.456
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['wake_time'], equals('09:02:03.456'));
    });

    test('encodes TIME as milliseconds (D=8)', () {
      final rows = [
        [32523456]
      ];

      final body = JxCodec.encode(encoding: 8008, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['wake_time'], equals(32523456));
    });

    test('validates TIME range', () {
      final rows = [
        [86400000] // Out of range
      ];

      expect(
        () => JxCodec.encode(encoding: 8000, rows: rows, schema: schema),
        throwsFormatException,
      );
    });

    test('decodes TIME from HH:mm:ss.SSS', () {
      final body = JxBody(data: [
        {'wake_time': '09:02:03.456'}
      ]);

      final rows = JxCodec.decode(encoding: 8000, body: body, schema: schema);

      expect(rows[0][0], equals(32523456));
    });

    test('decodes TIME from milliseconds', () {
      final body = JxBody(data: [
        {'wake_time': 32523456}
      ]);

      final rows = JxCodec.decode(encoding: 8008, body: body, schema: schema);

      expect(rows[0][0], equals(32523456));
    });

    test('validates TIME format', () {
      final body = JxBody(data: [
        {'wake_time': '25:00:00.000'}
      ]);

      expect(
        () => JxCodec.decode(encoding: 8000, body: body, schema: schema),
        throwsFormatException,
      );
    });

    test('encodes midnight', () {
      final rows = [
        [0]
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['wake_time'], equals('00:00:00.000'));
    });

    test('encodes last millisecond before midnight', () {
      final rows = [
        [86399999]
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['wake_time'], equals('23:59:59.999'));
    });
  });

  group('JxCodec - NUMERIC exact values', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'price', n: 'Price', typeId: 21002, typeName: 'NUMERIC(10,2)'),
    ]);

    test('preserves exact NUMERIC as string (N=0)', () {
      final rows = [
        [Numeric('1234567890.12')]
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['price'], equals('1234567890.12'));
      expect(row['price'], isA<String>());
    });

    test('converts NUMERIC to number (N=1)', () {
      final rows = [
        [Numeric('1234.56')]
      ];

      final body = JxCodec.encode(encoding: 8100, rows: rows, schema: schema);

      // Check the JSON output has unquoted number
      final jsonString = body.encode();
      expect(jsonString, contains('1234.56'));
      expect(jsonString, isNot(contains('"1234.56"'))); // Not a string

      // Verify decoding works correctly
      final decoded = JxCodec.decode(
        encoding: 8100,
        body: JxBody.parse(jsonString),
        schema: schema,
      );
      expect(decoded[0][0], isA<Numeric>());
    });
  });

  group('JxCodec - INT64 exact values', () {
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 3, typeName: 'INT64'),
    ]);

    test('preserves exact INT64 as string (L=0)', () {
      final rows = [
        [BigInt.parse('9223372036854775807')]
      ];

      final body = JxCodec.encode(encoding: 8000, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['id'], equals('9223372036854775807'));
      expect(row['id'], isA<String>());
    });

    test('converts INT64 to integer (L=1)', () {
      final rows = [
        [BigInt.from(42)]
      ];

      final body = JxCodec.encode(encoding: 8010, rows: rows, schema: schema);

      final row = body.data[0] as Map;
      expect(row['id'], equals(42));
      expect(row['id'], isA<int>());
    });
  });
}
