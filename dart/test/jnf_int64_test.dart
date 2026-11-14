import 'dart:convert';

import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  const schema = <String, int>{
    'id': 300003,
    'name': 300008,
    'small': 300002,
    'amount': 310020,
  };

  group('jnf INT64 conversion', () {
    for (final mode in [0, 3, 5]) {
      test('mode $mode reads INT64 strings as BigInt and round-trips', () {
        final input = jsonEncode({
          'jv': 1,
          'jid': 1,
          'jnf': mode,
          'schema': schema,
          'data': [
            ['9223372036854775807', '123', 42, '123.45'],
            ['-9223372036854775808', '9007199254740993', -42, '0.00'],
            ['9007199254740993', '0', 0, '1.20'],
          ],
        });
        final jsonc = JsonC.parse(input);
        final maps = JConverter.toMaps(jsonc);
        expect(maps[0]['id'], BigInt.parse('9223372036854775807'));
        expect(maps[1]['id'], BigInt.parse('-9223372036854775808'));
        expect(maps[2]['id'], BigInt.parse('9007199254740993'));
        expect(maps[0]['id'], isA<BigInt>());
        expect(maps[0]['name'], '123');
        expect(maps[0]['small'], 42);
        expect(maps[0]['amount'], '123.45');

        final encoded = jsonDecode(jsonc.encode()) as Map<String, dynamic>;
        final rows = encoded['data'] as List<dynamic>;
        expect((rows[0] as List)[0], '9223372036854775807');
        expect((rows[1] as List)[0], '-9223372036854775808');
        expect((rows[2] as List)[0], '9007199254740993');
        expect(
          JConverter.toMaps(JsonC.parse(jsonc.encode()))[2]['id'],
          BigInt.parse('9007199254740993'),
        );
      });
    }

    for (final mode in <int?>[1, 2, 4, null]) {
      test('mode ${mode ?? 'default'} leaves INT64 values as int', () {
        final input = <String, dynamic>{
          'jv': 1,
          'jid': 1,
          'schema': schema,
          'data': [
            [123, '123', 42, '123.45'],
          ],
        };
        if (mode != null) input['jnf'] = mode;
        final jsonc = JsonC.fromJson(input);
        final map = JConverter.toMaps(jsonc).single;
        expect(map['id'], isA<int>());
        expect(map['id'], 123);
        expect(map['name'], '123');
        expect(map['small'], 42);
        expect(map['amount'], '123.45');
        final encoded = jsonDecode(jsonc.encode()) as Map<String, dynamic>;
        expect(((encoded['data'] as List).single as List).first, 123);

        final stringInput = <String, dynamic>{
          'jv': 1,
          'jid': 1,
          'schema': {'id': 300003},
          'data': [
            ['123'],
          ],
        };
        if (mode != null) stringInput['jnf'] = mode;
        final numericString = JsonC.fromJson(stringInput);
        expect(numericString.data!.single.single, isA<int>());
      });
    }

    test('direct constructor maps INT64 values and does not mutate rows', () {
      final data = <List<dynamic>>[
        ['9007199254740993', '12', 42, '123.45'],
      ];
      final jsonc = JsonC(jv: 1, jid: 1, jnf: 3, schema: schema, data: data);
      final map = JConverter.toMaps(jsonc).single;
      expect(map['id'], BigInt.parse('9007199254740993'));
      expect(map['id'], isA<BigInt>());
      expect(data.single.first, '9007199254740993');
      expect(data.single[1], '12');
    });

    test('never treats unsafe raw numbers as exact BigInt input', () {
      const raw =
          '{"jv":1,"jid":1,"jnf":3,"schema":{"id":300003},'
          '"data":[[9007199254740992]]}';
      try {
        final jsonc = JsonC.parse(raw);
        expect(jsonc.data!.single.single, isNot(isA<BigInt>()));
        try {
          final id = JConverter.toMaps(jsonc).single['id'];
          expect(id, isNot(isA<BigInt>()));
        } on FormatException {
          // Rejecting a potentially imprecise value is safe too.
        } on ArgumentError {
          // Rejecting a potentially imprecise value is safe too.
        }
      } on FormatException {
        // Rejecting a potentially imprecise value is safe too.
      } on ArgumentError {
        // Rejecting a potentially imprecise value is safe too.
      }
    });

    test('encodes a directly constructed BigInt as a decimal string', () {
      final value = BigInt.parse('9223372036854775807');
      final data = <List<dynamic>>[
        [value],
      ];
      final jsonc = JsonC(
        jv: 1,
        jid: 1,
        jnf: 3,
        schema: {'id': 300003},
        data: data,
      );
      final encoded = jsonDecode(jsonc.encode()) as Map<String, dynamic>;
      expect(
        ((encoded['data'] as List).single as List).single,
        '9223372036854775807',
      );
      expect(data.single.single, same(value));
    });

    test('fromMaps applies the requested mode to integer values', () {
      final stringMode = JConverter.fromMaps(
        [
          {'id': 42},
        ],
        {'id': 300003},
        jv: 1,
        jid: 1,
        jnf: 3,
      );
      expect(stringMode.jnf, 3);
      expect(JConverter.toMaps(stringMode).single['id'], BigInt.from(42));
      expect(JConverter.toMaps(stringMode).single['id'], isA<BigInt>());

      final numberMode = JConverter.fromMaps(
        [
          {'id': BigInt.from(42)},
        ],
        {'id': 300003},
        jv: 1,
        jid: 1,
        jnf: 4,
      );
      expect(JConverter.toMaps(numberMode).single['id'], 42);
      expect(JConverter.toMaps(numberMode).single['id'], isA<int>());
    });

    test('fromMaps applies the selected mode', () {
      final value = BigInt.parse('9007199254740993');
      final result = JConverter.fromMaps(
        [
          {'id': value},
        ],
        {'id': 300003},
        jv: 1,
        jid: 1,
        jnf: 3,
      );
      expect(result.jnf, 3);
      expect(result.data!.single.single, value);
      expect(
        (jsonDecode(result.encode())['data'] as List).single.single,
        '9007199254740993',
      );

      final raw = JConverter.fromMaps(
        [
          {'id': BigInt.from(123)},
        ],
        {'id': 300003},
        jv: 1,
        jid: 1,
      );
      expect(raw.data!.single.single, isA<int>());
    });

    test(
      'preserves null and leaves mismatched rows available for validation',
      () {
        final jsonc = JsonC.fromJson({
          'jv': 1,
          'jid': 1,
          'jnf': 3,
          'schema': schema,
          'data': [
            [null, 'name', 1, '1.23'],
            ['12'],
          ],
        });
        expect(jsonc.data!.first.first, isNull);
        expect(JConverter.validate(jsonc), isNotEmpty);
      },
    );

    test('rejects malformed or out-of-range INT64 values', () {
      for (final value in ['not-int', '9223372036854775808']) {
        final jsonc = JsonC(
          jv: 1,
          jid: 1,
          jnf: 3,
          schema: {'id': 300003},
          data: [
            [value],
          ],
        );
        expect(JConverter.validate(jsonc), isNotEmpty, reason: value);
      }
    });

    test('data-only payload retains mode until merged with schema', () {
      final dataOnly = JsonC.fromJson({
        'jv': 1,
        'jid': 123,
        'jnf': 5,
        'data': [
          ['9007199254740993', 'name', 1, '1.23'],
        ],
      });
      expect(dataOnly.data!.single.first, '9007199254740993');
      final schemaOnly = JsonC(jv: 1, jid: 123, schema: schema);
      final merged = JConverter.merge(schemaOnly, dataOnly);
      expect(merged.jnf, 5);
      expect(
        JConverter.toMaps(merged).single['id'],
        BigInt.parse('9007199254740993'),
      );
      expect(JConverter.extractData(merged).jnf, 5);
    });

    test('JBase merge preserves the data-only jnf', () {
      final base = JBase.instance;
      base.clear();
      addTearDown(base.clear);
      base.register(JsonC(jv: 1, jid: 123, schema: schema));
      final merged = base.mergeWithSchema(
        JsonC(
          jv: 1,
          jid: 123,
          jnf: 3,
          data: [
            ['9007199254740993', 'name', 1, '1.23'],
          ],
        ),
      );
      expect(merged.jnf, 3);
      expect(
        JConverter.toMaps(merged).single['id'],
        BigInt.parse('9007199254740993'),
      );
    });
  });
}
