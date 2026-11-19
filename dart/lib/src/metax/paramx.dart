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
  final int dxi;

  /// Provenance: 0=native, >0=copied, <0=imported
  final int f;

  /// Query ID (references queryx.i)
  final int qxi;

  /// Display name
  final String n;

  /// Code (unique within query)
  final String c;

  /// Data type (TypeX Group 3)
  final int dtx;

  /// Required flag
  final bool req;

  /// Optional recursive parent identifier; existence is not guaranteed.
  final int fp;

  const ParamX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.f,
    required this.qxi,
    required this.n,
    required this.c,
    required this.dtx,
    this.req = false,
    this.fp = 0,
  });

  factory ParamX.fromJson(Map<String, dynamic> json) {
    return ParamX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      f: json['f'] as int,
      qxi: json['qxi'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      dtx: json['dtx'] as int,
      req: json['req'] as bool? ?? false,
      fp: json['fp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'dxi': dxi,
    'f': f,
    'qxi': qxi,
    'n': n,
    'c': c,
    'dtx': dtx,
    'req': req,
    'fp': fp,
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
