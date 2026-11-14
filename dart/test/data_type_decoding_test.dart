import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('decodeNumericType', () {
    test('decodes unlimited NUMERIC', () {
      final result = decodeNumericType(300000);
      expect(result, isNotNull);
      expect(result!.precision, isNull);
      expect(result.scale, isNull);
    });

    test('decodes sized NUMERIC', () {
      var result = decodeNumericType(310020);
      expect(result, isNotNull);
      expect(result!.precision, equals(10));
      expect(result.scale, equals(2));

      result = decodeNumericType(301000);
      expect(result, isNotNull);
      expect(result!.precision, equals(1));
      expect(result.scale, equals(0));

      result = decodeNumericType(399990);
      expect(result, isNotNull);
      expect(result!.precision, equals(99));
      expect(result.scale, equals(99));

      result = decodeNumericType(350370);
      expect(result, isNotNull);
      expect(result!.precision, equals(50));
      expect(result.scale, equals(37));
    });

    test('returns null for non-NUMERIC types', () {
      expect(decodeNumericType(300002), isNull); // INT32
      expect(decodeNumericType(300008), isNull); // TEXT
      expect(decodeNumericType(301008), isNull); // TEXT(100)
      expect(decodeNumericType(999999), isNull); // invalid
    });

    test('returns null for invalid NUMERIC IDs', () {
      expect(decodeNumericType(310025), isNull); // doesn't end in 0
      expect(decodeNumericType(305060), isNull); // scale > precision
    });

    test('round-trip encoding/decoding', () {
      // Unlimited
      var encoded = encodeNumericType();
      var decoded = decodeNumericType(encoded);
      expect(decoded, isNotNull);
      expect(decoded!.precision, isNull);
      expect(decoded.scale, isNull);

      // With parameters
      final testCases = [
        (precision: 10, scale: 2),
        (precision: 1, scale: 0),
        (precision: 99, scale: 99),
        (precision: 50, scale: 37),
        (precision: 5, scale: 5),
      ];

      for (final params in testCases) {
        encoded = encodeNumericType(
          precision: params.precision,
          scale: params.scale,
        );
        decoded = decodeNumericType(encoded);
        expect(
          decoded,
          isNotNull,
          reason: 'NUMERIC(${params.precision},${params.scale}) should decode',
        );
        expect(decoded!.precision, equals(params.precision));
        expect(decoded.scale, equals(params.scale));
      }
    });
  });

  group('decodeTextType', () {
    test('returns null for unlimited TEXT', () {
      expect(decodeTextType(300008), isNull);
    });

    test('decodes sized TEXT', () {
      expect(decodeTextType(301008), equals(100));
      expect(decodeTextType(300018), equals(1));
      expect(decodeTextType(399998), equals(9999));
      expect(decodeTextType(350008), equals(5000));
    });

    test('returns null for non-TEXT types', () {
      expect(decodeTextType(300002), isNull); // INT32
      expect(decodeTextType(300000), isNull); // NUMERIC
      expect(decodeTextType(310020), isNull); // NUMERIC(10,2)
      expect(decodeTextType(999999), isNull); // invalid
    });

    test('returns null for invalid TEXT IDs', () {
      expect(decodeTextType(301005), isNull); // doesn't end in 8
      expect(decodeTextType(400008), isNull); // out of range
    });

    test('round-trip encoding/decoding', () {
      // Unlimited
      var encoded = encodeTextType();
      var decoded = decodeTextType(encoded);
      expect(decoded, isNull); // unlimited returns null

      // With length
      final testLengths = [1, 10, 100, 1000, 5000, 9999];

      for (final length in testLengths) {
        encoded = encodeTextType(length: length);
        decoded = decodeTextType(encoded);
        expect(
          decoded,
          equals(length),
          reason: 'TEXT($length) should decode correctly',
        );
      }
    });
  });

  group('decoding edge cases', () {
    test('handles boundary values', () {
      // NUMERIC boundaries
      expect(decodeNumericType(301000), isNotNull); // min precision
      expect(decodeNumericType(399990), isNotNull); // max precision/scale

      // TEXT boundaries
      expect(decodeTextType(300018), equals(1)); // min length
      expect(decodeTextType(399998), equals(9999)); // max length
    });

    test('consistent with validation', () {
      // Every valid type should either decode or be a base type
      final testIds = [
        300000, 300001, 300002, 300008, // base types
        310020, 301000, 399990, // NUMERIC
        301008, 300018, 399998, // TEXT
      ];

      for (final id in testIds) {
        expect(
          isValidDataType(id),
          isTrue,
          reason: 'Test ID $id should be valid',
        );

        final isBase = isBaseDataType(id);
        final numericResult = decodeNumericType(id);
        final textResult = decodeTextType(id);

        // Should decode as something or be a base type
        expect(
          isBase || numericResult != null || textResult != null,
          isTrue,
          reason: 'ID $id should be decodable or base type',
        );
      }
    });
  });
}
