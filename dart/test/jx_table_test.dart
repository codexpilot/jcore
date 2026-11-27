import 'package:jcore/data.dart';
import 'package:test/test.dart';

const identifier = JxField(
  i: 301,
  c: 'record_id',
  n: 'Record ID',
  typeId: 3,
  typeName: 'INT64',
);

const amount = JxField(
  i: 920,
  c: 'total_amount',
  n: 'Total Amount',
  typeId: 20000,
  typeName: 'NUMERIC',
);

const label = JxField(
  i: 502,
  c: 'label',
  n: 'Display Label',
  typeId: 10000,
  typeName: 'TEXT',
);

void main() {
  test('uses one schema to resolve positional cells and metadata keys', () {
    final schema = JxSchema([label, amount]);
    final table = JxTable.fromJson(
      body: '{"data":[["first","100.00"],[null,"250.750"]]}',
      encoding: 1000,
      schema: schema,
    );

    expect(table.schema, same(schema));
    expect(table.rowCount, 2);
    expect(table.rows, [
      ['first', Numeric('100.00')],
      [null, Numeric('250.750')],
    ]);
    expect(table.cellAt(0, 0), 'first');
    expect(table.byId(1, 920), Numeric('250.750'));
    expect(table.byCode(0, 'total_amount'), Numeric('100.00'));
    expect(table.byName(0, 'Display Label'), 'first');
    expect(table.byName(1, 'Display Label'), isNull);
    expect(table.byId(0, 1), isNull);
    expect(table.byCode(0, 'TOTAL_AMOUNT'), isNull);
    expect(table.byName(0, 'label'), isNull);
    expect(() => table.cellAt(2, 0), throwsRangeError);
    expect(() => table.cellAt(0, 2), throwsRangeError);
    expect(() => table.byId(2, 1), throwsRangeError);
  });

  test('preserves raw NUMERIC scale and exact INT64 in compact rows', () {
    final table = JxTable.fromJson(
      body: '{"data":[[9223372036854775807,9007199254740993.1250]]}',
      encoding: 1118,
      schema: JxSchema([identifier, amount]),
    );

    expect(table.cellAt(0, 0).toString(), '9223372036854775807');
    final value = table.cellAt(0, 1) as Numeric;
    expect(value.toString(), '9007199254740993.1250');
    expect(value.scale, 4);
  });

  test('orders a code-keyed object by schema and preserves exact numbers', () {
    final table = JxTable.fromJson(
      body:
          '{"data":[{"total_amount":9007199254740993.1250,'
          '"record_id":-9223372036854775808}]}',
      encoding: 8118,
      schema: JxSchema([identifier, amount]),
    );

    expect(table.rows.single[0].toString(), '-9223372036854775808');
    expect(table.rows.single[1].toString(), '9007199254740993.1250');
  });

  test('exposes read-only outer and inner row views', () {
    final table = JxTable.fromJson(
      body: '{"data":[["first"],["second"]]}',
      encoding: 1000,
      schema: JxSchema([label]),
    );

    expect(() => table.rows.add(['third']), throwsUnsupportedError);
    expect(() => table.rows[0] = ['changed'], throwsUnsupportedError);
    expect(() => table.rows[0].clear(), throwsUnsupportedError);
    expect(() => table.rows[0][0] = 'changed', throwsUnsupportedError);
    expect(table.cellAt(0, 0), 'first');
  });

  test('rejects ambiguous metadata keys', () {
    final table = JxTable.fromJson(
      body: '{"data":[["first","second"]]}',
      encoding: 1000,
      schema: JxSchema([label, label]),
    );

    expect(() => table.byId(0, 502), throwsArgumentError);
    expect(() => table.byCode(0, 'label'), throwsArgumentError);
    expect(() => table.byName(0, 'Display Label'), throwsArgumentError);
    expect(table.cellAt(0, 1), 'second');
  });

  test('handles an empty result', () {
    final table = JxTable.fromJson(
      body: '{"data":[]}',
      encoding: 1000,
      schema: JxSchema([label]),
    );

    expect(table.rowCount, 0);
    expect(table.rows, isEmpty);
    expect(() => table.rows.clear(), throwsUnsupportedError);
  });

  test('indexes rows across a large compact result', () {
    const count = 4096;
    final data = List.generate(count, (i) => '["row-$i"]').join(',');
    final table = JxTable.fromJson(
      body: '{"data":[$data]}',
      encoding: 1000,
      schema: JxSchema([label]),
    );

    expect(table.rowCount, count);
    expect(table.rows[1024].single, 'row-1024');
    expect(table.byCode(count - 1, label.c), 'row-4095');
  });

  test('rejects malformed response envelopes and rows', () {
    const compact = 1000;
    const compactWithMeta = 2000;
    const object = 8000;
    final schema = JxSchema([label]);
    const cases = <(int, String)>[
      (compact, '[]'),
      (compact, '{}'),
      (compact, '{"data":{}}'),
      (compact, '{"data":[{"label":"first"}]}'),
      (compact, '{"data":[["first","second"]]}'),
      (compactWithMeta, '{"meta":[null],"data":[]}'),
      (object, '{"data":[["first"]]}'),
    ];

    for (final (encoding, body) in cases) {
      expect(
        () => JxTable.fromJson(body: body, encoding: encoding, schema: schema),
        throwsFormatException,
        reason: body,
      );
    }
  });
}
