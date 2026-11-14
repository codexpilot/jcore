import 'numeric.dart';

/// Checks the decimal representation of a NUMERIC value without converting it
/// to a floating-point number. Returns a description of any validation error.
///
/// Sized values must fit exactly: insignificant fractional zeros are allowed,
/// but values requiring rounding are rejected. A double is checked using its
/// decimal representation; precision already lost in the double is not restored.
String? numericValueError(Object value, {int? precision, int? scale}) {
  if (value is! String &&
      value is! num &&
      value is! BigInt &&
      value is! Numeric) {
    return 'expected a decimal string or numeric value, got ${value.runtimeType}';
  }
  if (value is double && !value.isFinite) {
    return 'expected a finite numeric value';
  }

  final text = value.toString();
  final match = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$')
      .firstMatch(text);
  if (match == null || match.end != text.length) {
    return 'invalid decimal value: $text';
  }

  final whole = match.group(2)!;
  final fraction = match.group(3) ?? '';
  final digits = whole + fraction;
  if (digits.isEmpty) return 'invalid decimal value: $text';
  if (precision == null) return null;

  // The scale of a parameterized NUMERIC is always present.
  final allowedScale = scale!;
  final first = digits.indexOf(RegExp(r'[1-9]'));
  if (first == -1) return null; // Zero fits every supported NUMERIC(p, s).
  final last = digits.lastIndexOf(RegExp(r'[1-9]'));

  // Only the position relative to the digits and the maximum precision (99)
  // matters. Clamp large exponents rather than allocating a power of ten.
  final limit = digits.length + 100;
  final exponentText = match.group(4);
  final parsedExponent = exponentText == null ? 0 : int.tryParse(exponentText);
  final exponent = parsedExponent == null
      ? (exponentText!.startsWith('-') ? -limit : limit)
      : parsedExponent.clamp(-limit, limit);
  final decimalPosition = whole.length + exponent;
  final integerDigits = decimalPosition > first ? decimalPosition - first : 0;
  final fractionDigits = last + 1 > decimalPosition
      ? last + 1 - decimalPosition
      : 0;

  if (fractionDigits > allowedScale) {
    return 'value exceeds NUMERIC($precision,$allowedScale) scale';
  }
  if (integerDigits > precision - allowedScale) {
    return 'value exceeds NUMERIC($precision,$allowedScale) precision';
  }
  return null;
}
