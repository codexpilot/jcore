/// Type group catalog (cox.typeg table)
class TypeG {
  /// Group ID
  final int i;

  /// Last edit timestamp (epoch milliseconds)
  final int d;

  /// Group name
  final String n;

  const TypeG({
    required this.i,
    required this.d,
    required this.n,
  });

  factory TypeG.fromJson(Map<String, dynamic> json) {
    return TypeG(
      i: json['i'] as int,
      d: json['d'] as int,
      n: json['n'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'n': n,
  };

  @override
  String toString() => 'TypeG(i=$i, n=$n)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeG && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}
