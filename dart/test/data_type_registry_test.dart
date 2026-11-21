import 'dart:convert';

import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  group('data type registry', () {
    test('uses the assigned IDs and resolves SMALLINT aliases', () {
      expect(DataType.boolean.id, 10000);
      expect(DataType.smallint.id, 20000);
      expect(DataType.int16, DataType.smallint);
      expect(DataType.int32.id, 30000);
      expect(DataType.int64.id, 40000);
      expect(DataType.datetime.id, 40001);
      expect(DataType.time.id, 40002);
      expect(DataType.uuid.id, 50000);
      expect(DataType.numeric.id, 60000);
      expect(DataType.text.id, 70000);
      expect(DataType.json.id, 80000);
      expect(DataType.jsonb.id, 80001);
      expect(DataType.fromId(70032), isNull);
      expect(DataType.fromName('CUID'), isNull);
      expect(DataTypeRegistry.fromName('int16'), DataType.smallint);
      expect(DataTypeRegistry.fromName('SMALLINT'), DataType.smallint);
      expect(DataType.fromPostgresType('int2'), DataType.smallint);
    });

    test('encodes and decodes NUMERIC precision and scale', () {
      expect(DataTypeRegistry.encodeNumeric(), 60000);
      expect(DataTypeRegistry.encodeNumeric(precision: 10, scale: 2), 61002);
      expect(DataTypeRegistry.encodeNumeric(precision: 1, scale: 0), 60100);
      expect(DataTypeRegistry.encodeNumeric(precision: 99, scale: 99), 69999);
      expect(DataTypeRegistry.decodeNumeric(61002), (precision: 10, scale: 2));
      expect(DataTypeRegistry.decodeNumeric(60000), (
        precision: null,
        scale: null,
      ));
      expect(DataTypeRegistry.isValidNumeric(69999), isTrue);
      expect(DataTypeRegistry.isValidNumeric(60506), isFalse);
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
      expect(DataTypeRegistry.encodeText(), 70000);
      expect(DataTypeRegistry.encodeText(length: 1), 70001);
      expect(DataTypeRegistry.encodeText(length: 100), 70100);
      expect(DataTypeRegistry.encodeText(length: 9999), 79999);
      expect(DataTypeRegistry.decodeText(70100), 100);
      expect(DataTypeRegistry.decodeText(70000), isNull);
      expect(DataTypeRegistry.isValidText(79999), isTrue);
      expect(
        () => DataTypeRegistry.encodeText(length: 10000),
        throwsArgumentError,
      );
    });

    test('validates catalog IDs and maps registered types', () {
      expect(DataTypeRegistry.isValid(10000), isTrue);
      expect(DataTypeRegistry.isValid(61002), isTrue);
      expect(DataTypeRegistry.isValid(70100), isTrue);
      expect(DataTypeRegistry.isValid(60001), isFalse);
      expect(DataTypeRegistry.isValid(80002), isFalse);
      expect(DataTypeRegistry.contains(80000), isTrue);
      expect(DataTypeRegistry.contains(80001), isTrue);
      expect(getPostgresType(30000), 'integer');
      expect(getPostgresType(61002), 'numeric(10,2)');
      expect(getPostgresType(70100), 'varchar(100)');
      expect(parseRegisteredDataTypeId('smallint'), 20000);
      expect(parseRegisteredDataTypeId('int16'), 20000);
    });

    test('enforces signed SMALLINT boundaries', () {
      expect(JConverter.validateValue(-32768, 20000, 0, 'value'), isNull);
      expect(JConverter.validateValue(32767, 20000, 0, 'value'), isNull);
      expect(JConverter.validateValue(-32769, 20000, 0, 'value'), isNotNull);
      expect(JConverter.validateValue(32768, 20000, 0, 'value'), isNotNull);
      expect(JConverter.validateSchema({'value': 20000}), isEmpty);
    });

    test('round-trips registered Numeric and INT64 in JSONC number modes', () {
      final amount = Numeric.fromString('123.40', 2);
      final stringMode = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 1,
        encoding: 4,
        schema: {'amount': 60502},
        data: [
          <dynamic>[amount],
        ],
      );
      final stringJson =
          jsonDecode(stringMode.encode()) as Map<String, dynamic>;
      expect((stringJson['data'] as List).single.single, '123.40');

      final numberMode = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 1,
        encoding: 2,
        schema: {'amount': 60502},
        data: [
          <dynamic>[amount],
        ],
      );
      final numberJson =
          jsonDecode(numberMode.encode()) as Map<String, dynamic>;
      expect((numberJson['data'] as List).single.single, 123.4);

      final largeId = BigInt.parse('9223372036854775807');
      final int64Jsonc = JsonC(
        dataSchemaVersion: 1,
        resultSchemaId: 1,
        encoding: 3,
        schema: {'id': 40000},
        data: [
          <dynamic>[largeId],
        ],
      );
      final idJson = jsonDecode(int64Jsonc.encode()) as Map<String, dynamic>;
      expect((idJson['data'] as List).single.single, '9223372036854775807');
    });
  });
}
