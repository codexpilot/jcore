import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  String? validate(Object value, int precision, int scale) =>
      JConverter.validateValue(
        value,
        DataTypeRegistry.encodeNumeric(precision: precision, scale: scale),
        0,
        'amount',
      );

  group('NUMERIC value validation', () {
    test('enforces integer and fractional capacity without rounding', () {
      expect(validate('999.99', 5, 2), isNull);
      expect(validate('-999.99', 5, 2), isNull);
      expect(validate('1000.00', 5, 2), isNotNull);
      expect(validate('999.991', 5, 2), isNotNull);
      expect(validate('1.234', 5, 2), isNotNull);
      expect(validate('00001.2300', 5, 2), isNull);
      expect(validate(12.34, 5, 2), isNull);
    });

    test('handles precision equal to scale and zeros', () {
      expect(validate('0.99999', 5, 5), isNull);
      expect(validate('1.00000', 5, 5), isNotNull);
      expect(validate('0.000001', 5, 5), isNotNull);
      expect(validate('000.000000', 1, 1), isNull);
      expect(validate('-0.0000', 1, 0), isNull);
    });

    test('preserves 99-digit strings and supports BigInt', () {
      final max = '9' * 99;
      expect(validate(max, 99, 0), isNull);
      expect(validate(BigInt.parse(max), 99, 0), isNull);
      expect(validate('1$max', 99, 0), isNotNull);
      expect(validate('0.${'9' * 99}', 99, 99), isNull);
      expect(validate('0.${'0' * 99}1', 99, 99), isNotNull);
    });

    test('handles scientific notation and bounded extreme exponents', () {
      expect(validate('1.23e2', 5, 2), isNull);
      expect(validate('123e-2', 5, 2), isNull);
      expect(validate(1e-7, 7, 7), isNull);
      expect(validate('1e100000000000000000000000000', 99, 0), isNotNull);
      expect(validate('1e-100000000000000000000000000', 99, 99), isNotNull);
      expect(validate('0e100000000000000000000000000', 1, 0), isNull);
    });

    test('rejects malformed and non-finite values', () {
      for (final value in [
        '',
        '.',
        'abc',
        '1.2.3',
        ' 1',
        '1\n',
        '1e',
        double.nan,
        double.infinity,
        double.negativeInfinity,
        true,
      ]) {
        expect(validate(value, 5, 2), isNotNull, reason: '$value');
        expect(JConverter.validateValue(value, 60000, 0, 'amount'), isNotNull);
      }
    });

    test('unconstrained NUMERIC accepts exact decimal strings', () {
      expect(
        JConverter.validateValue(
          '12345678901234567890.123456789',
          60000,
          0,
          'amount',
        ),
        isNull,
      );
      expect(JConverter.validateValue('NaN', 60000, 0, 'amount'), isNotNull);
    });
  });
}
