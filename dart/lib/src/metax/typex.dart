/// Type catalog metadata (cox.typex table)
class TypeX {
  /// Type ID (primary key)
  final int i;

  /// Last edit timestamp (epoch milliseconds)
  final int d;

  /// Editor user ID
  final int e;

  /// Active status (0-3)
  final int a;

  /// Type name
  final String n;

  /// Group ID (references typeg)
  final int g;

  /// Key within group
  final int k;

  /// Code identifier (kebab-case)
  final String c;

  const TypeX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.n,
    required this.g,
    required this.k,
    required this.c,
  });

  /// Is this type active?
  bool get isActive => a >= 1;

  factory TypeX.fromJson(Map<String, dynamic> json) {
    return TypeX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      n: json['n'] as String,
      g: json['g'] as int,
      k: json['k'] as int,
      c: json['c'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'n': n,
    'g': g,
    'k': k,
    'c': c,
  };

  @override
  String toString() => 'TypeX(i=$i, n=$n, c=$c, g=$g)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}
