import 'dart:convert';

import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JNLD Codec - Encoding 1118 (J=1, N=1, L=1, D=8)', () {
    // Encoding 1118: compact positional, raw NUMERIC, raw INT64, epoch milliseconds
    final schema = JxSchema([
      JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      JxField(i: 2, c: 'amount', n: 'Amount', typeId: 61903, typeName: 'NUMERIC(19,3)'),
      JxField(i: 3, c: 'observed_at', n: 'Observed At', typeId: 40001, typeName: 'DATETIME'),
    ]);

    test('end-to-end wire format with exact NUMERIC precision', () {
      // Start with exact values
      final rows = [
        [
          BigInt.parse('9223372036854775807'), // Max INT64
          Numeric('9007199254740993.125'), // Exact NUMERIC(19,3)
          1704067200123, // DATETIME as epoch ms
        ],
      ];

      // Encode to body
      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema,
      );

      // Encode to JSON wire format
      final jsonString = body.encode();

      // Verify JSON structure
      expect(jsonString, contains('"data"'));
      expect(jsonString, contains('9223372036854775807'));
      expect(jsonString, contains('9007199254740993.125'));
      expect(jsonString, contains('1704067200123'));

      // Verify exact JSON format (NUMERIC is unquoted)
      expect(jsonString, contains('[[9223372036854775807,9007199254740993.125,1704067200123]]'));

      // Decode using precision-preserving method
      final decodedRows = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema,
      );

      // Verify decoded values
      expect(decodedRows, hasLength(1));
      expect(decodedRows[0], hasLength(3));

      // INT64 exact
      expect(decodedRows[0][0], isA<int>());
      expect(decodedRows[0][0], equals(BigInt.parse('9223372036854775807').toInt()));

      // NUMERIC exact
      expect(decodedRows[0][1], isA<Numeric>());
      expect(decodedRows[0][1].toString(), equals('9007199254740993.125'));

      // DATETIME exact
      expect(decodedRows[0][2], isA<int>());
      expect(decodedRows[0][2], equals(1704067200123));

      // Re-encode and verify stability
      final reEncoded = JxCodec.encode(
        encoding: 1118,
        rows: decodedRows,
        schema: schema,
      );
      final reEncodedJson = reEncoded.encode();

      // Re-encoded JSON should match original
      expect(reEncodedJson, equals(jsonString));
    });

    test('preserves trailing zeros in NUMERIC', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'price', n: 'Price', typeId: 61002, typeName: 'NUMERIC(10,2)'),
      ]);

      final rows = [
        [Numeric('100.00')], // Trailing zeros
        [Numeric('50.10')], // One trailing zero
        [Numeric('25.01')], // No trailing zeros
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();

      // Verify trailing zeros are preserved
      expect(jsonString, contains('100.00'));
      expect(jsonString, contains('50.10'));
      expect(jsonString, contains('25.01'));

      // Decode and verify
      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      expect(decoded[0][0].toString(), equals('100.00'));
      expect(decoded[1][0].toString(), equals('50.10'));
      expect(decoded[2][0].toString(), equals('25.01'));
    });

    test('handles base NUMERIC (60000)', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'value', n: 'Value', typeId: 60000, typeName: 'NUMERIC'),
      ]);

      final rows = [
        [Numeric('123456789012345678901234567890.123456789')],
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();

      // Verify exact decimal is preserved
      expect(jsonString, contains('123456789012345678901234567890.123456789'));

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      expect(decoded[0][0].toString(), equals('123456789012345678901234567890.123456789'));
    });

    test('handles scale-zero NUMERIC', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'count', n: 'Count', typeId: 61000, typeName: 'NUMERIC(10,0)'),
      ]);

      final rows = [
        [Numeric('1234567890')],
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();

      // Should be valid JSON number without decimal point
      expect(jsonString, contains('1234567890'));
      expect(jsonString, isNot(contains('1234567890.')));

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      // Verify exact value (Numeric.toString() adds trailing dot for scale=0)
      expect(decoded[0][0], isA<Numeric>());
      expect(decoded[0][0].scale, equals(0));
      expect(decoded[0][0].toBigInt(), equals(BigInt.parse('1234567890')));
    });

    test('validates INT64 range - max boundary', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      ]);

      final rows = [
        [BigInt.parse('9223372036854775807')], // Max INT64
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      expect(body.data[0][0], equals(BigInt.parse('9223372036854775807').toInt()));
    });

    test('validates INT64 range - min boundary', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      ]);

      final rows = [
        [BigInt.parse('-9223372036854775808')], // Min INT64
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      expect(body.data[0][0], equals(BigInt.parse('-9223372036854775808').toInt()));
    });

    test('rejects INT64 overflow - positive', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      ]);

      final rows = [
        [BigInt.parse('9223372036854775808')], // Max + 1
      ];

      expect(
        () => JxCodec.encode(encoding: 1118, rows: rows, schema: schema2),
        throwsRangeError,
      );
    });

    test('rejects INT64 overflow - negative', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      ]);

      final rows = [
        [BigInt.parse('-9223372036854775809')], // Min - 1
      ];

      expect(
        () => JxCodec.encode(encoding: 1118, rows: rows, schema: schema2),
        throwsRangeError,
      );
    });

    test('validates compact row width - too many cells', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
      ]);

      final jsonString = '{"data":[[1,2]]}'; // Two cells, schema expects one

      expect(
        () => JxCodec.decodeFromJsonString(
          encoding: 1118,
          jsonString: jsonString,
          schema: schema2,
        ),
        throwsFormatException,
      );
    });

    test('validates compact row width - too few cells', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
        JxField(i: 2, c: 'name', n: 'Name', typeId: 70000, typeName: 'TEXT'),
      ]);

      final jsonString = '{"data":[[1]]}'; // One cell, schema expects two

      expect(
        () => JxCodec.decodeFromJsonString(
          encoding: 1118,
          jsonString: jsonString,
          schema: schema2,
        ),
        throwsFormatException,
      );
    });

    test('allows empty result with correct data structure', () {
      final jsonString = '{"data":[]}';

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema,
      );

      expect(decoded, isEmpty);
    });

    test('handles parameterized NUMERIC outside 61xxx range', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'value', n: 'Value', typeId: 60201, typeName: 'NUMERIC(2,1)'),
      ]);

      final rows = [
        [Numeric('9.5')],
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();
      expect(jsonString, contains('9.5'));

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      expect(decoded[0][0].toString(), equals('9.5'));
    });

    test('preserves NUMERIC precision for large values', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'balance', n: 'Balance', typeId: 61903, typeName: 'NUMERIC(19,3)'),
      ]);

      // Value that loses precision in double
      final rows = [
        [Numeric('9007199254740992.500')],
        [Numeric('9007199254740993.125')],
        [Numeric('9007199254740994.750')],
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      expect(decoded[0][0].toString(), equals('9007199254740992.500'));
      expect(decoded[1][0].toString(), equals('9007199254740993.125'));
      expect(decoded[2][0].toString(), equals('9007199254740994.750'));
    });

    test('handles mixed types correctly', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'id', n: 'ID', typeId: 40000, typeName: 'INT64'),
        JxField(i: 2, c: 'name', n: 'Name', typeId: 70000, typeName: 'TEXT'),
        JxField(i: 3, c: 'amount', n: 'Amount', typeId: 61002, typeName: 'NUMERIC(10,2)'),
        JxField(i: 4, c: 'active', n: 'Active', typeId: 10000, typeName: 'BOOLEAN'),
      ]);

      final rows = [
        [BigInt.from(42), 'Product A', Numeric('99.95'), true],
        [BigInt.from(43), 'Product B', Numeric('149.99'), false],
      ];

      final body = JxCodec.encode(
        encoding: 1118,
        rows: rows,
        schema: schema2,
      );

      final jsonString = body.encode();

      final decoded = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: jsonString,
        schema: schema2,
      );

      expect(decoded[0][0], equals(42));
      expect(decoded[0][1], equals('Product A'));
      expect(decoded[0][2].toString(), equals('99.95'));
      expect(decoded[0][3], equals(true));

      expect(decoded[1][0], equals(43));
      expect(decoded[1][1], equals('Product B'));
      expect(decoded[1][2].toString(), equals('149.99'));
      expect(decoded[1][3], equals(false));
    });

    test('uses compact cell positions across nulls and digits in text', () {
      final mixedSchema = JxSchema([
        JxField(
          i: 1,
          c: 'active',
          n: 'Active',
          typeId: 10000,
          typeName: 'BOOLEAN',
        ),
        JxField(i: 2, c: 'code', n: 'Code', typeId: 70000, typeName: 'TEXT'),
        JxField(
          i: 3,
          c: 'amount',
          n: 'Amount',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
        JxField(i: 4, c: 'tail', n: 'Tail', typeId: 40000, typeName: 'INT64'),
      ]);

      final rows = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: '{"data":[[null,"x9z8p6",100.00,7],[true,"plain",9007199254740993.125,8]]}',
        schema: mixedSchema,
      );

      expect(rows[0], [null, 'x9z8p6', Numeric('100.00'), 7]);
      expect(rows[1], [true, 'plain', Numeric('9007199254740993.125'), 8]);
      expect((rows[0][2] as Numeric).scale, 2);
    });

    test('keeps compact NUMERIC after JSON-looking text and nested JSONB', () {
      final mixedSchema = JxSchema([
        JxField(i: 1, c: 'note', n: 'Note', typeId: 70000, typeName: 'TEXT'),
        JxField(
          i: 2,
          c: 'detail',
          n: 'Detail',
          typeId: 80001,
          typeName: 'JSONB',
        ),
        JxField(
          i: 3,
          c: 'amount',
          n: 'Amount',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
      ]);

      final rows = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: r'''{"data":[
          ["[9, \"data\"]",{"items":[1,{"amount":2}]},50.10],
          ["[3,4]",[{"amount":900},[5,6]],9007199254740993.125]
        ]}''',
        schema: mixedSchema,
      );

      expect(rows[0], [
        '[9, "data"]',
        {
          'items': [
            1,
            {'amount': 2},
          ],
        },
        Numeric('50.10'),
      ]);
      expect(rows[1], [
        '[3,4]',
        [
          {'amount': 900},
          [5, 6],
        ],
        Numeric('9007199254740993.125'),
      ]);
      expect((rows[0][2] as Numeric).scale, 2);
    });

    test('matches full-object NUMERIC by decoded top-level key', () {
      const escapedKey = 'net["a"].*';
      final objectSchema = JxSchema([
        JxField(
          i: 1,
          c: 'detail',
          n: 'Detail',
          typeId: 80001,
          typeName: 'JSONB',
        ),
        JxField(
          i: 2,
          c: escapedKey,
          n: 'Net',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
        JxField(
          i: 3,
          c: 'amount',
          n: 'Amount',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
      ]);

      final rows = JxCodec.decodeFromJsonString(
        encoding: 8108,
        jsonString: r'''{"data":[{
          "detail":{"net[\"a\"].*":17,"amount":13},
          "amount":100.00,
          "net[\"a\"].*":9007199254740993.125
        }]}''',
        schema: objectSchema,
      );

      expect(rows.single, [
        {escapedKey: 17, 'amount': 13},
        Numeric('9007199254740993.125'),
        Numeric('100.00'),
      ]);
      expect((rows.single[2] as Numeric).scale, 2);
    });

    test('rejects malformed raw NUMERIC tokens', () {
      final amountSchema = JxSchema([
        JxField(
          i: 1,
          c: 'amount',
          n: 'Amount',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
      ]);

      for (final value in ['01', '1.2.3', 'NaN', '+1', '1e', '12.']) {
        expect(
          () => JxCodec.encode(
            encoding: 1118,
            rows: [
              [value],
            ],
            schema: amountSchema,
          ).encode(),
          throwsFormatException,
          reason: value,
        );
        expect(
          () => JxCodec.decodeFromJsonString(
            encoding: 1118,
            jsonString: '{"data":[[$value]]}',
            schema: amountSchema,
          ),
          throwsFormatException,
          reason: value,
        );
      }
    });

    test('escapes nested JSON map keys when writing raw NUMERIC', () {
      const key = 'quote"backslash\\newline\n';
      final mixedSchema = JxSchema([
        JxField(
          i: 1,
          c: 'detail',
          n: 'Detail',
          typeId: 80001,
          typeName: 'JSONB',
        ),
        JxField(
          i: 2,
          c: 'amount',
          n: 'Amount',
          typeId: 60000,
          typeName: 'NUMERIC',
        ),
      ]);

      final json = JxCodec.encode(
        encoding: 1118,
        rows: [
          [
            {key: 'value'},
            Numeric('50.10'),
          ],
        ],
        schema: mixedSchema,
      ).encode();

      expect(jsonDecode(json), {
        'data': [
          [
            {key: 'value'},
            50.1,
          ],
        ],
      });
      expect(json, contains(',50.10]]'));
    });

    test('round-trip stability for all edge cases', () {
      final schema2 = JxSchema([
        JxField(i: 1, c: 'int_max', n: 'Int Max', typeId: 40000, typeName: 'INT64'),
        JxField(i: 2, c: 'int_min', n: 'Int Min', typeId: 40000, typeName: 'INT64'),
        JxField(i: 3, c: 'num_precise', n: 'Num Precise', typeId: 61903, typeName: 'NUMERIC(19,3)'),
        JxField(i: 4, c: 'num_trailing', n: 'Num Trailing', typeId: 61002, typeName: 'NUMERIC(10,2)'),
        JxField(i: 5, c: 'timestamp', n: 'Timestamp', typeId: 40001, typeName: 'DATETIME'),
      ]);

      final rows = [
        [
          BigInt.parse('9223372036854775807'),
          BigInt.parse('-9223372036854775808'),
          Numeric('9007199254740993.125'),
          Numeric('100.00'),
          1704067200123,
        ],
      ];

      // First encode
      final body1 = JxCodec.encode(encoding: 1118, rows: rows, schema: schema2);
      final json1 = body1.encode();

      // First decode
      final decoded1 = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: json1,
        schema: schema2,
      );

      // Second encode
      final body2 = JxCodec.encode(encoding: 1118, rows: decoded1, schema: schema2);
      final json2 = body2.encode();

      // Second decode
      final decoded2 = JxCodec.decodeFromJsonString(
        encoding: 1118,
        jsonString: json2,
        schema: schema2,
      );

      // All values should be stable across multiple round-trips
      expect(json1, equals(json2));
      expect(decoded1[0][0], equals(decoded2[0][0]));
      expect(decoded1[0][1], equals(decoded2[0][1]));
      expect(decoded1[0][2].toString(), equals(decoded2[0][2].toString()));
      expect(decoded1[0][3].toString(), equals(decoded2[0][3].toString()));
      expect(decoded1[0][4], equals(decoded2[0][4]));
    });
  });
}
