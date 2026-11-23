import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('getPostgresType', () {
    test('maps base types to PostgreSQL names', () {
      expect(getPostgresType(0), equals('boolean'));
      expect(getPostgresType(1), equals('smallint'));
      expect(getPostgresType(2), equals('integer'));
      expect(getPostgresType(3), equals('bigint'));
      expect(
        getPostgresType(4),
        equals('bigint'),
      ); // DATETIME stored as bigint
      expect(
        getPostgresType(5),
        equals('bigint'),
      ); // TIME stored as bigint
      expect(getPostgresType(6), equals('uuid'));
      expect(getPostgresType(7), equals('jsonb'));
      expect(getPostgresType(10000), equals('text'));
      expect(getPostgresType(20000), equals('numeric'));
    });

    test('maps sized NUMERIC to PostgreSQL declarations', () {
      expect(getPostgresType(21002), equals('numeric(10,2)')); // 20000 + 10*100 + 2
      expect(getPostgresType(20100), equals('numeric(1,0)')); // 20000 + 1*100 + 0
      expect(getPostgresType(29999), equals('numeric(99,99)')); // 20000 + 99*100 + 99
      expect(getPostgresType(25037), equals('numeric(50,37)')); // 20000 + 50*100 + 37
    });

    test('maps sized TEXT to declarations', () {
      expect(getPostgresType(10100), equals('varchar(100)')); // 10000 + 100
      expect(getPostgresType(10001), equals('varchar(1)')); // 10000 + 1
      expect(getPostgresType(19999), equals('varchar(9999)')); // 10000 + 9999
    });

    test('returns null for invalid types', () {
      expect(getPostgresType(999999), isNull);
      expect(getPostgresType(55555), isNull);
      expect(getPostgresType(60025), isNull); // invalid NUMERIC (scale > precision)
    });
  });

  group('parseDataTypeId', () {
    test('parses base type names', () {
      expect(parseDataTypeId('integer'), equals(2));
      expect(parseDataTypeId('bigint'), equals(3));
      expect(parseDataTypeId('boolean'), equals(0));
      expect(parseDataTypeId('smallint'), equals(1));
      expect(parseDataTypeId('numeric'), equals(20000));
      expect(parseDataTypeId('uuid'), equals(6));
      expect(parseDataTypeId('jsonb'), equals(7));
      expect(parseDataTypeId('text'), equals(10000));
      expect(parseDataTypeId('CUID'), isNull);
    });

    test('is case-insensitive', () {
      expect(parseDataTypeId('INTEGER'), equals(2));
      expect(parseDataTypeId('Integer'), equals(2));
      expect(parseDataTypeId('BIGINT'), equals(3));
    });

    test('handles whitespace', () {
      expect(parseDataTypeId(' integer '), equals(2));
      expect(parseDataTypeId('\ttext\n'), equals(10000));
    });

    test('returns null for unknown types', () {
      expect(parseDataTypeId('invalid'), isNull);
      expect(parseDataTypeId('varchar'), isNull);
      expect(parseDataTypeId(''), isNull);
    });

    test('returns null for parameterized types', () {
      // Parser only handles base type names
      expect(parseDataTypeId('numeric(10,2)'), isNull);
      expect(parseDataTypeId('text(100)'), isNull);
    });

    test('round-trip with getPostgresType for base types', () {
      // Note: Multiple types can map to same PostgreSQL type (bigint, text)
      // So we only test unique mappings
      final uniqueTypes = [
        DataType.numeric, // numeric
        DataType.boolean, // boolean
        DataType.int32, // integer
        DataType.uuid, // uuid
        DataType.jsonb, // jsonb
      ];

      for (final type in uniqueTypes) {
        final pgType = type.postgresType;
        final parsedId = parseDataTypeId(pgType);
        expect(
          parsedId,
          equals(type.id),
          reason: 'Round-trip failed for ${type.name}: $pgType',
        );
      }
    });
  });

  group('getRequiredDataType', () {
    test('returns INT32 for status column', () {
      expect(getRequiredDataType(200402), equals(2));
    });

    test('returns INT32 for version column', () {
      expect(getRequiredDataType(200302), equals(2));
    });

    test('returns null for other column types', () {
      expect(getRequiredDataType(200011), isNull); // system_column_id
      expect(getRequiredDataType(200004), isNull); // system_column_name
      expect(getRequiredDataType(200000), isNull); // user_column
    });
  });

  group('isValidColumnDataType', () {
    test('validates status column requires INT32', () {
      expect(isValidColumnDataType(200402, 2), isTrue); // status + INT32
      expect(isValidColumnDataType(200402, 3), isFalse); // status + INT64
      expect(
        isValidColumnDataType(200402, 20000),
        isFalse,
      ); // status + NUMERIC
    });

    test('validates version column requires INT32', () {
      expect(isValidColumnDataType(200302, 2), isTrue); // version + INT32
      expect(isValidColumnDataType(200302, 3), isFalse); // version + INT64
      expect(
        isValidColumnDataType(200302, 20000),
        isFalse,
      ); // version + NUMERIC
    });

    test('validates other columns accept any valid data type', () {
      expect(isValidColumnDataType(200011, 2), isTrue); // id + INT32
      expect(isValidColumnDataType(200011, 3), isTrue); // id + INT64
      expect(isValidColumnDataType(200004, 10000), isTrue); // name + TEXT
      expect(isValidColumnDataType(200004, 10100), isTrue); // name + TEXT(100)
    });

    test('rejects invalid data types', () {
      expect(isValidColumnDataType(200004, 999999), isFalse);
      expect(isValidColumnDataType(200004, 20025), isFalse); // invalid NUMERIC (scale > precision)
    });
  });
}
