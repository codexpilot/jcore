import 'package:jcore/jcore.dart';
import 'package:test/test.dart';

void main() {
  group('Numeric', () {
    test('preserves exact decimal scale and adds or subtracts exactly', () {
      final price = Numeric.fromString('12.34', 2);
      final adjustment = Numeric.fromString('0.6600', 4);
      expect(price.toDisplay(), '12.34');
      expect(Numeric.fromString('1.239', 2).toDisplay(), '1.23');
      expect((price + adjustment).toDisplay(), '13.0000');
      expect((price - adjustment).toDisplay(), '11.6800');
      expect(
        Numeric.parse('0.00000000000000000001').toString(),
        '0.00000000000000000001',
      );
    });

    test('multiplies and compares without floating-point rounding', () {
      final left = Numeric.fromString('12.34', 2);
      final right = Numeric.fromString('2.5000', 4);
      expect(left.multiplyBy(right).toDisplay(), '30.850000');
      expect((left * 100).toDisplay(), '1234.00');
      expect(Numeric.parse('1.20'), Numeric.parse('1.2'));
      expect(Numeric.parse('1.20').hashCode, Numeric.parse('1.2').hashCode);
      expect(Numeric.parse('-1.2') < Numeric.parse('0'), isTrue);
      expect(Numeric.parse('2.01') > Numeric.parse('2.001'), isTrue);
    });
  });
}
