/// Logical field metadata (mx.fieldx table)
class FieldX {
  /// Field metadata ID
  final int i;

  /// Last edit timestamp
  final int d;

  /// Editor user ID
  final int e;

  /// Active status
  final int a;

  /// Domain ID
  final int dxi;

  /// Display name
  final String n;

  /// Parent entity ID
  final int ent;

  /// Parent column IDs (storage binding)
  final List<int> p;

  /// Column type (TypeX Group 5)
  final int ctx;

  /// Data type (TypeX Group 3)
  final int dtx;

  /// Code (unique)
  final String c;

  /// Field type (TypeX Group 7: 400000-400002)
  /// 400000=Bidirectional, 400001=Input-only, 400002=Output-only
  final int ftx;

  /// Origin
  final int f;

  const FieldX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.n,
    required this.ent,
    this.p = const [],
    required this.ctx,
    required this.dtx,
    required this.c,
    this.ftx = 400000,
    this.f = 0,
  });

  /// Field capabilities based on type
  FieldCapabilities get capabilities {
    switch (ftx) {
      case 400000:
        return FieldCapabilities.bidirectional;
      case 400001:
        return FieldCapabilities.inputOnly;
      case 400002:
        return FieldCapabilities.outputOnly;
      default:
        return FieldCapabilities.bidirectional;
    }
  }

  /// Can this field be used for input?
  bool get canInput => ftx == 400000 || ftx == 400001;

  /// Can this field be used for output?
  bool get canOutput => ftx == 400000 || ftx == 400002;

  factory FieldX.fromJson(Map<String, dynamic> json) {
    return FieldX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      n: json['n'] as String,
      ent: json['ent'] as int,
      p: (json['p'] as List<dynamic>?)?.cast<int>() ?? const [],
      ctx: json['ctx'] as int,
      dtx: json['dtx'] as int,
      c: json['c'] as String,
      ftx: json['ftx'] as int? ?? 400000,
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
    'ent': ent,
    'p': p,
    'ctx': ctx,
    'dtx': dtx,
    'c': c,
    'ftx': ftx,
    'f': f,
  };

  @override
  String toString() => 'FieldX(i=$i, n=$n, c=$c, capabilities=$capabilities)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

enum FieldCapabilities {
  bidirectional, // Can be used for input and output
  inputOnly, // Only for input (e.g., passwords)
  outputOnly, // Only for output (e.g., computed fields)
}
