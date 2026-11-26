import 'package:jcore/data.dart';
import 'package:test/test.dart';

void main() {
  group('JxRow', () {
    late JxSchema schema;

    setUp(() {
      schema = JxSchema([
        JxField(
          i: 1,
          c: 'id',
          n: 'id',
          typeId: 300007,
          typeName: 'Integer',
        ),
        JxField(
          i: 2,
          c: 'name',
          n: 'name',
          typeId: 300011,
          typeName: 'String',
        ),
        JxField(
          i: 3,
          c: 'amount',
          n: 'amount',
          typeId: 300013,
          typeName: 'Numeric',
        ),
      ]);
    });

    test('creates row with matching cell count', () {
      final row = JxRow(schema: schema, cells: [1, 'Test', '123.45']);
      expect(row.cells.length, equals(3));
    });

    test('rejects mismatched cell count', () {
      expect(
        () => JxRow(schema: schema, cells: [1, 'Test']),
        throwsArgumentError,
      );
    });

    test('index access returns cell value', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(row[0], equals(123));
      expect(row[1], equals('John'));
      expect(row[2], equals('456.78'));
    });

    test('name access returns cell value', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(row['id'], equals(123));
      expect(row['name'], equals('John'));
      expect(row['amount'], equals('456.78'));
    });

    test('name access throws on invalid field', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(() => row['invalid'], throwsArgumentError);
    });

    test('getInt returns int value', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(row.getInt('id'), equals(123));
    });

    test('getString returns string value', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(row.getString('name'), equals('John'));
    });

    test('getNumeric returns exact numeric string', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      expect(row.getNumeric('amount'), equals('456.78'));
    });

    test('getInt64 preserves exact INT64 values', () {
      final row = JxRow(schema: schema, cells: [1234567890123, 'Test', '0']);
      expect(row.getInt64('id'), equals(1234567890123));
    });

    test('hasValue checks field existence', () {
      final row = JxRow(schema: schema, cells: [123, 'John', null]);
      expect(row.hasValue('id'), isTrue);
      expect(row.hasValue('name'), isTrue);
      expect(row.hasValue('amount'), isFalse);
      expect(row.hasValue('invalid'), isFalse);
    });

    test('toMap converts row to map', () {
      final row = JxRow(schema: schema, cells: [123, 'John', '456.78']);
      final map = row.toMap();
      expect(map['id'], equals(123));
      expect(map['name'], equals('John'));
      expect(map['amount'], equals('456.78'));
    });
  });

  group('JxComposedRow', () {
    test('getOne returns single child row', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      final headerRow = JxRow(schema: schema, cells: [1]);

      final composed = JxComposedRow(
        schema: schema,
        cells: [1],
        sections: {
          'header': JxOneSection(row: headerRow),
        },
      );

      final retrieved = composed.getOne('header');
      expect(retrieved, equals(headerRow));
    });

    test('getMany returns list of child rows', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      final row1 = JxRow(schema: schema, cells: [1]);
      final row2 = JxRow(schema: schema, cells: [2]);

      final composed = JxComposedRow(
        schema: schema,
        cells: [100],
        sections: {
          'items': JxManySection(rows: [row1, row2]),
        },
      );

      final items = composed.getMany('items');
      expect(items.length, equals(2));
      expect(items[0], equals(row1));
      expect(items[1], equals(row2));
    });

    test('getOne throws on many section', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      final composed = JxComposedRow(
        schema: schema,
        cells: [1],
        sections: {
          'items': JxManySection(rows: []),
        },
      );

      expect(() => composed.getOne('items'), throwsArgumentError);
    });

    test('getMany throws on one section', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      final composed = JxComposedRow(
        schema: schema,
        cells: [1],
        sections: {
          'header': JxOneSection(row: null),
        },
      );

      expect(() => composed.getMany('header'), throwsArgumentError);
    });

    test('hasSection checks section existence', () {
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      final composed = JxComposedRow(
        schema: schema,
        cells: [1],
        sections: {
          'header': JxOneSection(row: null),
        },
      );

      expect(composed.hasSection('header'), isTrue);
      expect(composed.hasSection('missing'), isFalse);
    });
  });
}
