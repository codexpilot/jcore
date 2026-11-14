import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('getPostgresType', () {
    test('maps base types to PostgreSQL names', () {
      expect(getPostgresType(60000), equals('numeric'));
      expect(getPostgresType(10000), equals('boolean'));
      expect(getPostgresType(30000), equals('integer'));
      expect(getPostgresType(40000), equals('bigint'));
      expect(
        getPostgresType(40001),
        equals('bigint'),
      ); // DATETIME stored as bigint
      expect(
        getPostgresType(40002),
        equals('bigint'),
      ); // TIME stored as bigint
      expect(getPostgresType(50000), equals('uuid'));
      expect(getPostgresType(70000), equals('text'));
      expect(getPostgresType(80001), equals('jsonb'));
    });

    test('maps sized NUMERIC to PostgreSQL declarations', () {
      expect(getPostgresType(61002), equals('numeric(10,2)')); // 60000 + 10*100 + 2
      expect(getPostgresType(60100), equals('numeric(1,0)')); // 60000 + 1*100 + 0
      expect(getPostgresType(69999), equals('numeric(99,99)')); // 60000 + 99*100 + 99
      expect(getPostgresType(65037), equals('numeric(50,37)')); // 60000 + 50*100 + 37
    });

    test('maps sized TEXT to declarations', () {
      expect(getPostgresType(70100), equals('varchar(100)')); // 70000 + 100
      expect(getPostgresType(70001), equals('varchar(1)')); // 70000 + 1
      expect(getPostgresType(79999), equals('varchar(9999)')); // 70000 + 9999
    });

    test('returns null for invalid types', () {
      expect(getPostgresType(999999), isNull);
      expect(getPostgresType(55555), isNull);
      expect(getPostgresType(60025), isNull); // invalid NUMERIC (scale > precision)
    });
  });

  group('parseDataTypeId', () {
    test('parses base type names', () {
      expect(parseDataTypeId('integer'), equals(30000));
      expect(parseDataTypeId('bigint'), equals(40000));
      expect(parseDataTypeId('boolean'), equals(10000));
      expect(parseDataTypeId('numeric'), equals(60000));
      expect(parseDataTypeId('uuid'), equals(50000));
      expect(parseDataTypeId('jsonb'), equals(80001));
      final textId = parseDataTypeId('text');
      expect(textId, equals(70000));
      expect(parseDataTypeId('CUID'), isNull);
    });

    test('is case-insensitive', () {
      expect(parseDataTypeId('INTEGER'), equals(30000));
      expect(parseDataTypeId('Integer'), equals(30000));
      expect(parseDataTypeId('BIGINT'), equals(40000));
    });

    test('handles whitespace', () {
      expect(parseDataTypeId(' integer '), equals(30000));
      final textId = parseDataTypeId('\ttext\n');
      expect(textId, equals(70000));
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
      expect(getRequiredDataType(200008), equals(30000));
    });

    test('returns INT32 for version column', () {
      expect(getRequiredDataType(200010), equals(30000));
    });

    test('returns null for other column types', () {
      expect(getRequiredDataType(200001), isNull); // system_column_i
      expect(getRequiredDataType(200005), isNull); // system_column_n
      expect(getRequiredDataType(200000), isNull); // user_column
    });
  });

  group('isValidColumnDataType', () {
    test('validates status column requires INT32', () {
      expect(isValidColumnDataType(200008, 30000), isTrue); // status + INT32
      expect(isValidColumnDataType(200008, 40000), isFalse); // status + INT64
      expect(
        isValidColumnDataType(200008, 60000),
        isFalse,
      ); // status + NUMERIC
    });

    test('validates version column requires INT32', () {
      expect(isValidColumnDataType(200010, 30000), isTrue); // version + INT32
      expect(isValidColumnDataType(200010, 40000), isFalse); // version + INT64
      expect(
        isValidColumnDataType(200010, 60000),
        isFalse,
      ); // version + NUMERIC
    });

    test('validates other columns accept any valid data type', () {
      expect(isValidColumnDataType(200001, 30000), isTrue); // id + INT32
      expect(isValidColumnDataType(200001, 40000), isTrue); // id + INT64
      expect(isValidColumnDataType(200005, 70000), isTrue); // name + TEXT
      expect(isValidColumnDataType(200005, 70100), isTrue); // name + TEXT(100)
    });

    test('rejects invalid data types', () {
      expect(isValidColumnDataType(200005, 999999), isFalse);
      expect(isValidColumnDataType(200005, 60025), isFalse); // invalid NUMERIC
    });
  });
}
