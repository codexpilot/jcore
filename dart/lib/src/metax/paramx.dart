/// Query parameter metadata (mx.paramx table)
class ParamX {
  /// Parameter ID
  final int i;

  /// Last edit timestamp
  final int d;

  /// Editor user ID
  final int e;

  /// Active status
  final int a;

  /// Domain ID
  final int di;

  /// Query ID
  final int q;

  /// Display name
  final String n;

  /// Code (unique within query)
  final String c;

  /// Data type (TypeX Group 3)
  final int dt;

  /// Required flag
  final bool req;

  /// Origin
  final int f;

  const ParamX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.di,
    required this.q,
    required this.n,
    required this.c,
    required this.dt,
    this.req = false,
    this.f = 0,
  });

  factory ParamX.fromJson(Map<String, dynamic> json) {
    return ParamX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      di: json['di'] as int,
      q: json['q'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      dt: json['dt'] as int,
      req: json['req'] as bool? ?? false,
      f: json['f'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'di': di,
    'q': q,
    'n': n,
    'c': c,
    'dt': dt,
    'req': req,
    'f': f,
  };

  @override
  String toString() => 'ParamX(i=$i, n=$n, c=$c, req=$req)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}
