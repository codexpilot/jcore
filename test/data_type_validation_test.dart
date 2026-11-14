import 'package:test/test.dart';
import 'package:jcore/jcore.dart';

void main() {
  group('isBaseDataType', () {
    test('recognizes all base types', () {
      for (int i = 300000; i <= 300009; i++) {
        expect(isBaseDataType(i), isTrue, reason: 'ID $i should be base type');
      }
    });

    test('rejects non-base types', () {
      expect(isBaseDataType(299999), isFalse);
      expect(isBaseDataType(300010), isFalse);
      expect(isBaseDataType(310020), isFalse);
      expect(isBaseDataType(0), isFalse);
    });
  });

  group('isValidNumericType', () {
    test('validates unlimited NUMERIC', () {
      expect(isValidNumericType(300000), isTrue);
    });

    test('validates sized NUMERIC types', () {
      expect(isValidNumericType(301000), isTrue); // NUMERIC(1,0)
      expect(isValidNumericType(310020), isTrue); // NUMERIC(10,2)
      expect(isValidNumericType(350370), isTrue); // NUMERIC(50,37)
      expect(isValidNumericType(399990), isTrue); // NUMERIC(99,99)
    });

    test('rejects NUMERIC not ending in 0', () {
      expect(isValidNumericType(310021), isFalse);
      expect(isValidNumericType(310025), isFalse);
      expect(isValidNumericType(310029), isFalse);
    });

    test('rejects NUMERIC with precision out of range', () {
      expect(isValidNumericType(300000 - 1000), isFalse); // precision -1
      expect(isValidNumericType(300000), isTrue); // unlimited (special)
      expect(isValidNumericType(400000), isFalse); // precision 100
    });

    test('rejects NUMERIC with scale > precision', () {
      expect(isValidNumericType(305060), isFalse); // NUMERIC(5,6) - invalid
      expect(isValidNumericType(301020), isFalse); // NUMERIC(1,2) - invalid
    });

    test('rejects non-NUMERIC types', () {
      expect(isValidNumericType(300002), isFalse); // INT32
      expect(isValidNumericType(300008), isFalse); // TEXT
      expect(isValidNumericType(301008), isFalse); // TEXT(100)
    });

    test('handles edge cases', () {
      expect(isValidNumericType(301000), isTrue); // NUMERIC(1,0) - min precision
      expect(isValidNumericType(301010), isTrue); // NUMERIC(1,1) - scale equals precision
      expect(isValidNumericType(399990), isTrue); // NUMERIC(99,99) - max precision
    });
  });

  group('isValidTextType', () {
    test('validates unlimited TEXT', () {
      expect(isValidTextType(300008), isTrue);
    });

    test('validates sized TEXT types', () {
      expect(isValidTextType(300018), isTrue); // TEXT(1)
      expect(isValidTextType(301008), isTrue); // TEXT(100)
      expect(isValidTextType(350008), isTrue); // TEXT(5000)
      expect(isValidTextType(399998), isTrue); // TEXT(9999)
    });

    test('rejects TEXT not ending in 8', () {
      expect(isValidTextType(301000), isFalse);
      expect(isValidTextType(301005), isFalse);
      expect(isValidTextType(301009), isFalse);
    });

    test('rejects TEXT with length out of range', () {
      expect(isValidTextType(300008 - 10), isFalse); // length -1
      expect(isValidTextType(300008), isTrue); // unlimited (special)
      expect(isValidTextType(400008), isFalse); // length 10000
    });

    test('rejects non-TEXT types', () {
      expect(isValidTextType(300002), isFalse); // INT32
      expect(isValidTextType(300000), isFalse); // NUMERIC
      expect(isValidTextType(310020), isFalse); // NUMERIC(10,2)
    });

    test('handles edge cases', () {
      expect(isValidTextType(300018), isTrue); // TEXT(1) - min length
      expect(isValidTextType(399998), isTrue); // TEXT(9999) - max length
    });
  });

  group('isValidDataType', () {
    test('validates all base types', () {
      for (final type in JDataType.values) {
        expect(isValidDataType(type.id), isTrue,
            reason: '${type.name} (${type.id}) should be valid');
      }
    });

    test('validates sized NUMERIC types', () {
      expect(isValidDataType(310020), isTrue); // NUMERIC(10,2)
      expect(isValidDataType(301000), isTrue); // NUMERIC(1,0)
      expect(isValidDataType(399990), isTrue); // NUMERIC(99,99)
    });

    test('validates sized TEXT types', () {
      expect(isValidDataType(301008), isTrue); // TEXT(100)
      expect(isValidDataType(300018), isTrue); // TEXT(1)
      expect(isValidDataType(399998), isTrue); // TEXT(9999)
    });

    test('rejects invalid type IDs', () {
      expect(isValidDataType(300010), isFalse); // invalid base
      expect(isValidDataType(310025), isFalse); // NUMERIC doesn't end in 0
      expect(isValidDataType(301005), isFalse); // TEXT doesn't end in 8
      expect(isValidDataType(400000), isFalse); // out of range
      expect(isValidDataType(299999), isFalse); // out of range
      expect(isValidDataType(0), isFalse);
      expect(isValidDataType(-1), isFalse);
    });

    test('comprehensive validation matrix', () {
      final valid = [
        300000, 300001, 300002, 300003, 300004, 300005, 300006, 300007,
        300008, 300009, // base
        301000, 310020, 350370, 399990, // NUMERIC
        300018, 301008, 350008, 399998, // TEXT
      ];

      final invalid = [
        299999, // below range
        300010, // invalid base
        310021, 310025, // NUMERIC bad endings
        301005, 301009, // TEXT bad endings
        399005, // NUMERIC scale > precision
        400000, 400008, // above range
      ];

      for (final id in valid) {
        expect(isValidDataType(id), isTrue, reason: '$id should be valid');
      }

      for (final id in invalid) {
        expect(isValidDataType(id), isFalse, reason: '$id should be invalid');
      }
    });
  });
}
