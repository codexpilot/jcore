/// Physical column metadata (mx.columnx table)
class ColumnX {
  /// Column metadata ID
  final int i;

  /// Last edit timestamp
  final int d;

  /// Editor user ID
  final int e;

  /// Active status
  final int a;

  /// Domain ID reference
  final int dxi;

  /// Display name
  final String n;

  /// Code (unique within domain)
  final String c;

  /// Parent table ID
  final int t;

  /// Column type (TypeX Group 5: 200000-200012)
  /// 200000=User-defined, 200001=i, 200002=d, 200003=e, 200004=a, etc.
  final int ctx;

  /// Data type (TypeX Group 3: JCore types)
  final int dtx;

  /// Origin
  final int f;

  const ColumnX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.n,
    required this.c,
    required this.t,
    required this.ctx,
    required this.dtx,
    this.f = 0,
  });

  /// Column type role name
  String get columnTypeRole {
    switch (ctx) {
      case 200000:
        return 'user-defined';
      case 200001:
        return 'i (ID)';
      case 200002:
        return 'd (date)';
      case 200003:
        return 'e (editor)';
      case 200004:
        return 'a (active)';
      case 200005:
        return 'n (name)';
      case 200006:
        return 'f (foreign key)';
      case 200007:
        return 'c (code)';
      case 200008:
        return 's (status)';
      case 200009:
        return 'p (parent)';
      case 200010:
        return 'v (version)';
      case 200011:
        return 'o (order)';
      case 200012:
        return 'm (marker)';
      default:
        return 'unknown';
    }
  }

  /// Is this a system role column (not user-defined)?
  bool get isSystemRole => ctx != 200000;

  factory ColumnX.fromJson(Map<String, dynamic> json) {
    return ColumnX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      t: json['t'] as int,
      ctx: json['ctx'] as int,
      dtx: json['dtx'] as int,
      f: json['f'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'dxi': dxi,
    'n': n,
    'c': c,
    't': t,
    'ctx': ctx,
    'dtx': dtx,
    'f': f,
  };

  @override
  String toString() => 'ColumnX(i=$i, n=$n, c=$c, role=$columnTypeRole)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}
