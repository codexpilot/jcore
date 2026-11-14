import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('getPostgresType', () {
    test('maps base types to PostgreSQL names', () {
      expect(getPostgresType(300000), equals('numeric'));
      expect(getPostgresType(300001), equals('boolean'));
      expect(getPostgresType(300002), equals('integer'));
      expect(getPostgresType(300003), equals('bigint'));
      expect(
        getPostgresType(300004),
        equals('bigint'),
      ); // DATETIME stored as bigint
      expect(
        getPostgresType(300005),
        equals('bigint'),
      ); // TIME stored as bigint
      expect(getPostgresType(300006), equals('uuid'));
      expect(getPostgresType(300007), equals('text')); // TEXT0Z stored as text
      expect(getPostgresType(300008), equals('text'));
      expect(getPostgresType(300009), equals('jsonb'));
    });

    test('maps sized NUMERIC to PostgreSQL declarations', () {
      expect(getPostgresType(310020), equals('numeric(10,2)'));
      expect(getPostgresType(301000), equals('numeric(1,0)'));
      expect(getPostgresType(399990), equals('numeric(99,99)'));
      expect(getPostgresType(350370), equals('numeric(50,37)'));
    });

    test('maps sized TEXT to declarations', () {
      expect(getPostgresType(301008), equals('text(100)'));
      expect(getPostgresType(300018), equals('text(1)'));
      expect(getPostgresType(399998), equals('text(9999)'));
    });

    test('returns null for invalid types', () {
      expect(getPostgresType(999999), isNull);
      expect(getPostgresType(300010), isNull);
      expect(getPostgresType(310025), isNull); // invalid NUMERIC
    });
  });

  group('parseDataTypeId', () {
    test('parses base type names', () {
      expect(parseDataTypeId('integer'), equals(300002));
      expect(parseDataTypeId('bigint'), equals(300003));
      expect(parseDataTypeId('boolean'), equals(300001));
      expect(parseDataTypeId('numeric'), equals(300000));
      expect(parseDataTypeId('uuid'), equals(300006));
      expect(parseDataTypeId('jsonb'), equals(300009));
      // Note: 'text' maps to first match (300007 or 300008)
      final textId = parseDataTypeId('text');
      expect(textId == 300007 || textId == 300008, isTrue);
    });

    test('is case-insensitive', () {
      expect(parseDataTypeId('INTEGER'), equals(300002));
      expect(parseDataTypeId('Integer'), equals(300002));
      expect(parseDataTypeId('BIGINT'), equals(300003));
    });

    test('handles whitespace', () {
      expect(parseDataTypeId(' integer '), equals(300002));
      // Note: 'text' maps to first match (300007 or 300008)
      final textId = parseDataTypeId('\ttext\n');
      expect(textId == 300007 || textId == 300008, isTrue);
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
        JDataType.numeric, // numeric
        JDataType.boolean, // boolean
        JDataType.int32, // integer
        JDataType.uuid, // uuid
        JDataType.jsonb, // jsonb
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
      expect(getRequiredDataType(200008), equals(300002));
    });

    test('returns INT32 for version column', () {
      expect(getRequiredDataType(200010), equals(300002));
    });

    test('returns null for other column types', () {
      expect(getRequiredDataType(200001), isNull); // system_column_i
      expect(getRequiredDataType(200005), isNull); // system_column_n
      expect(getRequiredDataType(200000), isNull); // user_column
    });
  });

  group('isValidColumnDataType', () {
    test('validates status column requires INT32', () {
      expect(isValidColumnDataType(200008, 300002), isTrue); // status + INT32
      expect(isValidColumnDataType(200008, 300003), isFalse); // status + INT64
      expect(
        isValidColumnDataType(200008, 300000),
        isFalse,
      ); // status + NUMERIC
    });

    test('validates version column requires INT32', () {
      expect(isValidColumnDataType(200010, 300002), isTrue); // version + INT32
      expect(isValidColumnDataType(200010, 300003), isFalse); // version + INT64
      expect(
        isValidColumnDataType(200010, 300000),
        isFalse,
      ); // version + NUMERIC
    });

    test('validates other columns accept any valid data type', () {
      expect(isValidColumnDataType(200001, 300002), isTrue); // id + INT32
      expect(isValidColumnDataType(200001, 300003), isTrue); // id + INT64
      expect(isValidColumnDataType(200005, 300008), isTrue); // name + TEXT
      expect(isValidColumnDataType(200005, 301008), isTrue); // name + TEXT(100)
    });

    test('rejects invalid data types', () {
      expect(isValidColumnDataType(200005, 999999), isFalse);
      expect(isValidColumnDataType(200005, 310025), isFalse); // invalid NUMERIC
    });
  });
}
