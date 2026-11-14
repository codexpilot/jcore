/// Exact decimal value with scale-preserving arithmetic.
///
/// Values are stored as a [BigInt] coefficient and a decimal [scale], avoiding
/// binary floating-point arithmetic. Parsing and arithmetic preserve trailing
/// fractional zeros. Explicit conversion through [toNum] may round values.
final class Numeric implements Comparable<Numeric> {
  static const _maxExponentMagnitude = 100000;

  /// Cached powers of 10 for common scales.
  /// Reduces memory allocations and GC pressure in EMR/EHR/ERP systems
  /// processing millions of numeric values.
  static final _scalePowers = <int, BigInt>{
    0: BigInt.one,
    1: BigInt.from(10),
    2: BigInt.from(100),
    3: BigInt.from(1000),
    4: BigInt.from(10000),
  };

  /// Returns cached power of 10 for common scales, computes otherwise.
  static BigInt _getScalePower(int scale) {
    return _scalePowers[scale] ?? BigInt.from(10).pow(scale);
  }

  /// Parses an exact decimal string, preserving its fractional scale.
  factory Numeric(String value) => Numeric.parse(value);

  const Numeric._(this._scaled, this.scale);

  /// Parses a finite decimal string, including optional scientific notation.
  factory Numeric.parse(String value) {
    final match = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$')
        .firstMatch(value);
    if (match == null || match.end != value.length) {
      throw FormatException('Invalid decimal value: $value');
    }

    final whole = match.group(2)!;
    final fraction = match.group(3) ?? '';
    final digits = '$whole$fraction';
    if (digits.isEmpty) throw FormatException('Invalid decimal value: $value');

    final exponentText = match.group(4);
    final exponent = exponentText == null ? 0 : int.tryParse(exponentText);
    if (exponent == null || exponent.abs() > _maxExponentMagnitude) {
      throw FormatException('Decimal exponent is outside the supported range');
    }

    var coefficient = BigInt.parse(digits);
    if (match.group(1) == '-') coefficient = -coefficient;
    var scale = fraction.length - exponent;
    if (scale < 0) {
      coefficient *= _getScalePower(-scale);
      scale = 0;
    }
    return Numeric._(coefficient, scale);
  }

  /// Creates a value at a specified scale.
  ///
  /// Fractional digits beyond [scale] are truncated, matching the original
  /// AIX Numeric factory. Shorter fractions are padded with zeros.
  factory Numeric.fromString(String value, int scale) {
    if (scale < 0 || scale > _maxExponentMagnitude) {
      throw ArgumentError.value(scale, 'scale', 'must be between 0 and 100000');
    }
    final parsed = Numeric.parse(value);
    if (parsed.scale == scale) return parsed;
    if (parsed.scale < scale) {
      return Numeric._(
        parsed._scaled * _getScalePower(scale - parsed.scale),
        scale,
      );
    }
    return Numeric._(
      parsed._scaled ~/ _getScalePower(parsed.scale - scale),
      scale,
    );
  }

  /// Creates a decimal from an integer, finite number, or decimal string.
  factory Numeric.from(Object value) {
    if (value is Numeric) return value;
    if (value is String) return Numeric.parse(value);
    if (value is BigInt || value is int) return Numeric.parse(value.toString());
    if (value is double && !value.isFinite) {
      throw FormatException('Numeric values must be finite');
    }
    if (value is num) return Numeric.parse(value.toString());
    throw ArgumentError.value(value, 'value', 'must be a finite decimal');
  }

  /// Returns a parsed value, or null when [value] is not a supported decimal.
  static Numeric? tryParse(String value) {
    try {
      return Numeric.parse(value);
    } on FormatException {
      return null;
    }
  }

  /// Integer coefficient for this decimal value.
  final BigInt _scaled;

  /// Number of decimal places represented by [_scaled].
  final int scale;

  /// Whether this value has no fractional part.
  bool get isInteger =>
      scale == 0 || _scaled % _getScalePower(scale) == BigInt.zero;

  /// Returns the signed scaled integer used by this value.
  BigInt get scaledValue => _scaled;

  /// Returns this value as an integer, throwing if it has a fractional part.
  BigInt toBigInt() {
    if (!isInteger) throw StateError('A fractional Numeric is not an integer');
    return _scaled ~/ _getScalePower(scale);
  }

  Numeric _expandToScale(int newScale) {
    if (newScale <= scale) return this;
    return Numeric._(_scaled * _getScalePower(newScale - scale), newScale);
  }

  /// Adds two values using the greater operand scale.
  Numeric operator +(Numeric other) {
    final resultScale = scale > other.scale ? scale : other.scale;
    final left = _expandToScale(resultScale);
    final right = other._expandToScale(resultScale);
    return Numeric._(left._scaled + right._scaled, resultScale);
  }

  /// Subtracts [other] using the greater operand scale.
  Numeric operator -(Numeric other) {
    final resultScale = scale > other.scale ? scale : other.scale;
    final left = _expandToScale(resultScale);
    final right = other._expandToScale(resultScale);
    return Numeric._(left._scaled - right._scaled, resultScale);
  }

  /// Multiplies two decimal values, adding their scales.
  Numeric multiplyBy(Numeric other) =>
      Numeric._(_scaled * other._scaled, scale + other.scale);

  /// Multiplies by an integer or another [Numeric].
  Numeric operator *(Object other) {
    if (other is Numeric) return multiplyBy(other);
    if (other is int || other is BigInt) {
      return Numeric._(_scaled * BigInt.parse(other.toString()), scale);
    }
    if (other is num) return multiplyBy(Numeric.from(other));
    throw ArgumentError.value(other, 'other', 'must be numeric');
  }

  /// Returns the negated value.
  Numeric operator -() => Numeric._(-_scaled, scale);

  /// Returns the absolute value, retaining the decimal scale.
  Numeric abs() => Numeric._(_scaled.abs(), scale);

  /// Converts to a Dart JSON-number-compatible value.
  ///
  /// Values outside native integer or double precision may be rounded. Use a
  /// JSONC string-number mode to preserve the exact decimal representation.
  num toNum() {
    final parsed = num.tryParse(toString());
    if (parsed == null || parsed is double && !parsed.isFinite) {
      throw FormatException(
        'Numeric value cannot be represented as a JSON number',
      );
    }
    return parsed;
  }

  /// Decimal representation with exactly [scale] fractional digits.
  String toDisplay() {
    final negative = _scaled.isNegative;
    var digits = _scaled.abs().toString();
    while (digits.length <= scale) {
      digits = '0$digits';
    }
    final decimalPosition = digits.length - scale;
    final integerPart = digits.substring(0, decimalPosition);
    final fractionPart = digits.substring(decimalPosition);
    final result = '$integerPart.$fractionPart';
    return negative ? '-$result' : result;
  }

  @override
  String toString() => toDisplay();

  @override
  int compareTo(Numeric other) {
    final resultScale = scale > other.scale ? scale : other.scale;
    final left = _expandToScale(resultScale)._scaled;
    final right = other._expandToScale(resultScale)._scaled;
    return left.compareTo(right);
  }

  @override
  bool operator ==(Object other) => other is Numeric && compareTo(other) == 0;

  @override
  int get hashCode {
    var value = _scaled;
    var valueScale = scale;
    while (valueScale > 0 && value % BigInt.from(10) == BigInt.zero) {
      value ~/= BigInt.from(10);
      valueScale--;
    }
    return Object.hash(value, valueScale);
  }

  bool operator <(Numeric other) => compareTo(other) < 0;
  bool operator <=(Numeric other) => compareTo(other) <= 0;
  bool operator >(Numeric other) => compareTo(other) > 0;
  bool operator >=(Numeric other) => compareTo(other) >= 0;
}
