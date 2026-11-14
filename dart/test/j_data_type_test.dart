import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('JDataType enum', () {
    test('has correct catalog IDs', () {
      expect(JDataType.numeric.id, equals(300000));
      expect(JDataType.boolean.id, equals(300001));
      expect(JDataType.int32.id, equals(300002));
      expect(JDataType.int64.id, equals(300003));
      expect(JDataType.datetime.id, equals(300004));
      expect(JDataType.time.id, equals(300005));
      expect(JDataType.uuid.id, equals(300006));
      expect(JDataType.text0z.id, equals(300007));
      expect(JDataType.text.id, equals(300008));
      expect(JDataType.jsonb.id, equals(300009));
    });

    test('has correct PostgreSQL types', () {
      expect(JDataType.numeric.postgresType, equals('numeric'));
      expect(JDataType.boolean.postgresType, equals('boolean'));
      expect(JDataType.int32.postgresType, equals('integer'));
      expect(JDataType.int64.postgresType, equals('bigint'));
      expect(JDataType.datetime.postgresType, equals('bigint'));
      expect(JDataType.time.postgresType, equals('bigint'));
      expect(JDataType.uuid.postgresType, equals('uuid'));
      expect(JDataType.text0z.postgresType, equals('text'));
      expect(JDataType.text.postgresType, equals('text'));
      expect(JDataType.jsonb.postgresType, equals('jsonb'));
    });

    test('fromId lookup works', () {
      expect(JDataType.fromId(300002), equals(JDataType.int32));
      expect(JDataType.fromId(300000), equals(JDataType.numeric));
      expect(JDataType.fromId(300009), equals(JDataType.jsonb));
      expect(JDataType.fromId(999999), isNull);
    });

    test('fromName lookup works', () {
      expect(JDataType.fromName('INT32'), equals(JDataType.int32));
      expect(JDataType.fromName('int32'), equals(JDataType.int32));
      expect(JDataType.fromName('NUMERIC'), equals(JDataType.numeric));
      expect(JDataType.fromName('invalid'), isNull);
    });

    test('fromPostgresType lookup works', () {
      expect(JDataType.fromPostgresType('integer'), equals(JDataType.int32));
      expect(JDataType.fromPostgresType('INTEGER'), equals(JDataType.int32));
      expect(JDataType.fromPostgresType('bigint'), equals(JDataType.int64));
      expect(JDataType.fromPostgresType('invalid'), isNull);
    });
  });
}
