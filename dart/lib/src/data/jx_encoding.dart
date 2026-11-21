/// JX encoding configuration for query result transport.
library;

/// JX encoding configuration parsed from a four-digit code.
///
/// Default encoding is 8000:
/// - J=8: Full JSON objects keyed by field code
/// - N=0: NUMERIC as decimal strings
/// - L=0: INT64 as integer strings
/// - D=0: DATETIME in ISO UTC format with Z
class JxEncoding {
  /// JSON structure mode
  final int j;

  /// NUMERIC encoding mode
  final int n;

  /// INT64 encoding mode
  final int l;

  /// Date/time encoding mode
  final int d;

  const JxEncoding({
    required this.j,
    required this.n,
    required this.l,
    required this.d,
  });

  /// Parse a four-digit JX encoding value
  factory JxEncoding.parse(int encoding) {
    if (encoding < 0 || encoding > 9999) {
      throw FormatException('Encoding must be 0-9999, got: $encoding');
    }

    final j = encoding ~/ 1000;
    final n = (encoding % 1000) ~/ 100;
    final l = (encoding % 100) ~/ 10;
    final d = encoding % 10;

    // Validate J
    if (j != 1 && j != 2 && j != 3 && j != 4 && j != 8 && j != 9) {
      throw FormatException('Invalid J=$j (valid: 1, 2, 3, 4, 8, 9)');
    }

    // Validate N
    if (n != 0 && n != 1) {
      throw FormatException('Invalid N=$n (valid: 0, 1)');
    }

    // Validate L
    if (l != 0 && l != 1) {
      throw FormatException('Invalid L=$l (valid: 0, 1)');
    }

    // Validate D
    if (d != 0 && d != 1 && d != 2 && d != 8) {
      throw FormatException('Invalid D=$d (valid: 0, 1, 2, 8)');
    }

    return JxEncoding(j: j, n: n, l: l, d: d);
  }

  /// Convert back to four-digit encoding value
  int toInt() => j * 1000 + n * 100 + l * 10 + d;

  /// Whether this uses compact positional rows (J=1, 2, 3, 4)
  bool get isCompact => j >= 1 && j <= 4;

  /// Whether this uses full JSON objects (J=8, 9)
  bool get isFullObjects => j == 8 || j == 9;

  /// Whether metadata is included (J=2, 3, 4)
  bool get hasMetadata => j == 2 || j == 3 || j == 4;

  /// Whether NUMERIC values are encoded as strings
  bool get numericAsString => n == 0;

  /// Whether INT64 values are encoded as strings
  bool get int64AsString => l == 0;

  @override
  String toString() => 'JxEncoding(${toInt()}: J=$j, N=$n, L=$l, D=$d)';
}
