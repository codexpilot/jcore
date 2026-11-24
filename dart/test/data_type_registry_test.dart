import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  group('data type registry', () {
    test('uses the assigned IDs and resolves SMALLINT aliases', () {
      expect(DataType.boolean.id, 0);
      expect(DataType.smallint.id, 1);
      expect(DataType.int16, DataType.smallint);
      expect(DataType.int32.id, 2);
      expect(DataType.int64.id, 3);
      expect(DataType.datetime.id, 4);
      expect(DataType.time.id, 5);
      expect(DataType.uuid.id, 6);
      expect(DataType.jsonb.id, 7);
      expect(DataType.numeric.id, 20000);
      expect(DataType.text.id, 10000);
      expect(DataType.fromId(10032), isNull);
      expect(DataType.fromName('CUID'), isNull);
      expect(DataTypeRegistry.fromName('int16'), DataType.smallint);
      expect(DataTypeRegistry.fromName('SMALLINT'), DataType.smallint);
      expect(DataType.fromPostgresType('int2'), DataType.smallint);
    });

    test('encodes and decodes NUMERIC precision and scale', () {
      expect(DataTypeRegistry.encodeNumeric(), 20000);
      expect(DataTypeRegistry.encodeNumeric(precision: 10, scale: 2), 21002);
      expect(DataTypeRegistry.encodeNumeric(precision: 1, scale: 0), 20100);
      expect(DataTypeRegistry.encodeNumeric(precision: 99, scale: 99), 29999);
      expect(DataTypeRegistry.decodeNumeric(21002), (precision: 10, scale: 2));
      expect(DataTypeRegistry.decodeNumeric(20000), (
        precision: null,
        scale: null,
      ));
      expect(DataTypeRegistry.isValidNumeric(29999), isTrue);
      expect(DataTypeRegistry.isValidNumeric(20506), isFalse);
      expect(
        () => DataTypeRegistry.encodeNumeric(precision: 100),
        throwsArgumentError,
      );
      expect(
        () => DataTypeRegistry.encodeNumeric(precision: 5, scale: 6),
        throwsArgumentError,
      );
    });

    test('encodes and decodes TEXT lengths', () {
      expect(DataTypeRegistry.encodeText(), 10000);
      expect(DataTypeRegistry.encodeText(length: 1), 10001);
      expect(DataTypeRegistry.encodeText(length: 100), 10100);
      expect(DataTypeRegistry.encodeText(length: 9999), 19999);
      expect(DataTypeRegistry.decodeText(10100), 100);
      expect(DataTypeRegistry.decodeText(10000), isNull);
      expect(DataTypeRegistry.isValidText(19999), isTrue);
      expect(
        () => DataTypeRegistry.encodeText(length: 10000),
        throwsArgumentError,
      );
    });

    test('validates catalog IDs and maps registered types', () {
      expect(DataTypeRegistry.isValid(10000), isTrue);
      expect(DataTypeRegistry.isValid(21002), isTrue);
      expect(DataTypeRegistry.isValid(10100), isTrue);
      expect(DataTypeRegistry.isValid(20001), isFalse);
      expect(DataTypeRegistry.isValid(80002), isFalse);
      expect(DataTypeRegistry.contains(7), isTrue);
      expect(DataTypeRegistry.contains(8), isTrue); // BINARY type added
      expect(DataTypeRegistry.contains(9), isFalse); // Type 9 doesn't exist
      expect(getPostgresType(2), 'integer');
      expect(getPostgresType(8), 'bytea'); // BINARY → bytea
      expect(getPostgresType(21002), 'numeric(10,2)');
      expect(getPostgresType(10100), 'varchar(100)');
      expect(parseRegisteredDataTypeId('smallint'), 1);
      expect(parseRegisteredDataTypeId('int16'), 1);
      expect(parseRegisteredDataTypeId('BINARY'), 8); // BINARY type lookup
    });
  });
}
