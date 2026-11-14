import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('encodeNumericType', () {
    test('encodes unlimited NUMERIC', () {
      expect(encodeNumericType(), equals(300000));
    });

    test('encodes sized NUMERIC with precision and scale', () {
      expect(encodeNumericType(precision: 10, scale: 2), equals(310020));
      expect(encodeNumericType(precision: 1, scale: 0), equals(301000));
      expect(encodeNumericType(precision: 99, scale: 99), equals(399990));
      expect(encodeNumericType(precision: 50, scale: 37), equals(350370));
    });

    test('encodes NUMERIC with precision only (scale defaults to 0)', () {
      expect(encodeNumericType(precision: 5), equals(305000));
      expect(encodeNumericType(precision: 10), equals(310000));
    });

    test('produces IDs ending in 0', () {
      for (int p = 1; p <= 10; p++) {
        for (int s = 0; s <= p; s++) {
          final id = encodeNumericType(precision: p, scale: s);
          expect(id % 10, equals(0),
              reason: 'NUMERIC($p,$s) → $id should end in 0');
        }
      }
    });

    test('throws when scale specified without precision', () {
      expect(() => encodeNumericType(scale: 2), throwsArgumentError);
    });

    test('throws when precision out of range', () {
      expect(() => encodeNumericType(precision: 0), throwsArgumentError);
      expect(() => encodeNumericType(precision: 100), throwsArgumentError);
      expect(() => encodeNumericType(precision: -1), throwsArgumentError);
    });

    test('throws when scale out of range', () {
      expect(() => encodeNumericType(precision: 10, scale: -1), throwsArgumentError);
      expect(() => encodeNumericType(precision: 10, scale: 11), throwsArgumentError);
    });

    test('validates scale <= precision constraint', () {
      expect(() => encodeNumericType(precision: 5, scale: 6), throwsArgumentError);
      expect(() => encodeNumericType(precision: 1, scale: 2), throwsArgumentError);
    });
  });

  group('encodeTextType', () {
    test('encodes unlimited TEXT', () {
      expect(encodeTextType(), equals(300008));
    });

    test('encodes sized TEXT', () {
      expect(encodeTextType(length: 100), equals(301008));
      expect(encodeTextType(length: 1), equals(300018));
      expect(encodeTextType(length: 9999), equals(399998));
      expect(encodeTextType(length: 5000), equals(350008));
    });

    test('produces IDs ending in 8', () {
      for (int len = 1; len <= 100; len++) {
        final id = encodeTextType(length: len);
        expect(id % 10, equals(8), reason: 'TEXT($len) → $id should end in 8');
      }
    });

    test('throws when length out of range', () {
      expect(() => encodeTextType(length: 0), throwsArgumentError);
      expect(() => encodeTextType(length: 10000), throwsArgumentError);
      expect(() => encodeTextType(length: -1), throwsArgumentError);
    });
  });

  group('encoding produces valid IDs', () {
    test('encoded NUMERIC types are valid', () {
      expect(isValidDataType(encodeNumericType()), isTrue);
      expect(isValidDataType(encodeNumericType(precision: 10, scale: 2)), isTrue);
      expect(isValidDataType(encodeNumericType(precision: 1, scale: 0)), isTrue);
      expect(isValidDataType(encodeNumericType(precision: 99, scale: 99)), isTrue);
    });

    test('encoded TEXT types are valid', () {
      expect(isValidDataType(encodeTextType()), isTrue);
      expect(isValidDataType(encodeTextType(length: 100)), isTrue);
      expect(isValidDataType(encodeTextType(length: 1)), isTrue);
      expect(isValidDataType(encodeTextType(length: 9999)), isTrue);
    });
  });
}
