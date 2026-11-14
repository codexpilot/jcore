import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  String? validate(Object value, DataType type) =>
      JConverter.validateValue(value, type.id, 0, 'value');

  group('integer value validation', () {
    test('accepts INT32 endpoints and rejects values outside them', () {
      expect(validate(-2147483648, DataType.int32), isNull);
      expect(validate(2147483647, DataType.int32), isNull);
      expect(validate('-2147483649', DataType.int32), isNotNull);
      expect(validate(BigInt.parse('2147483648'), DataType.int32), isNotNull);
    });

    test('accepts INT64 endpoints and rejects values outside them', () {
      expect(validate('-9223372036854775808', DataType.int64), isNull);
      expect(
        validate(BigInt.parse('9223372036854775807'), DataType.int64),
        isNull,
      );
      expect(validate('-9223372036854775809', DataType.int64), isNotNull);
      expect(
        validate(BigInt.parse('9223372036854775808'), DataType.int64),
        isNotNull,
      );
    });

    test('accepts decimal integer forms and rejects non-integer values', () {
      expect(validate('+00042', DataType.int64), isNull);
      expect(validate(BigInt.from(-42), DataType.int64), isNull);
      for (final value in ['1.0', '1e2', '0xff', ' 1', '', 1.0, true]) {
        expect(validate(value, DataType.int64), isNotNull, reason: '$value');
      }
    });
  });
}
