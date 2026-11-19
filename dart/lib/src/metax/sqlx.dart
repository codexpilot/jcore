/// SQL implementation metadata (mx.sqlx table)
class SqlX {
  /// SQL record ID
  final int i;

  /// Last edit timestamp
  final int d;

  /// Editor user ID
  final int e;

  /// Active status
  final int a;

  /// Domain ID
  final int dxi;

  /// Query ID (references queryx.i)
  final int qxi;

  /// Display name
  final String n;

  /// Code
  final String c;

  /// Database type (PostgreSQL, MySQL, etc.)
  final int dbt;

  /// SQL body (actual SQL text)
  final String s;

  /// Origin
  final int f;

  const SqlX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.qxi,
    required this.n,
    required this.c,
    required this.dbt,
    required this.s,
    this.f = 0,
  });

  factory SqlX.fromJson(Map<String, dynamic> json) {
    return SqlX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      qxi: json['qxi'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      dbt: json['dbt'] as int,
      s: json['s'] as String,
      f: json['f'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'dxi': dxi,
    'qxi': qxi,
    'n': n,
    'c': c,
    'dbt': dbt,
    's': s,
    'f': f,
  };

  @override
  String toString() => 'SqlX(i=$i, n=$n, qxi=$qxi, dbt=$dbt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}
