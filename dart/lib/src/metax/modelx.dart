/// Logical model metadata (mx.modelx table)
class ModelX {
  /// Model metadata ID
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

  /// Provenance: 0=native, >0=copied, <0=imported
  final int f;

  /// Parent model IDs
  final List<int> ps;

  /// System-managed preview: TableX IDs from MapX 971600
  final List<int> txis;

  /// Code (unique)
  final String c;

  /// Model type (TypeX Group 6: 300000-399999)
  /// Table-First only: 300000 (No Map), 310000 (Single Table), 330000 (Multiple Tables), 390000 (System)
  final int mtx;

  /// Optional recursive parent identifier; existence is not guaranteed.
  final int fp;

  const ModelX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.n,
    required this.f,
    this.ps = const [],
    this.txis = const [],
    required this.c,
    this.mtx = 300000,
    this.fp = 0,
  });

  /// Model type category (Table-First only)
  ModelTypeCategory get category {
    if (mtx == 300000) return ModelTypeCategory.noMap;
    if (mtx == 310000) return ModelTypeCategory.singleTable;
    if (mtx == 330000) return ModelTypeCategory.multipleTables;
    if (mtx == 390000) return ModelTypeCategory.system;
    return ModelTypeCategory.unknown;
  }

  factory ModelX.fromJson(Map<String, dynamic> json) {
    return ModelX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      n: json['n'] as String,
      f: json['f'] as int,
      ps: (json['ps'] as List<dynamic>?)?.cast<int>() ?? const [],
      txis: (json['txis'] as List<dynamic>?)?.cast<int>() ?? const [],
      c: json['c'] as String,
      mtx: json['mtx'] as int? ?? 300000,
      fp: json['fp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'dxi': dxi,
    'n': n,
    'f': f,
    'ps': ps,
    'txis': txis,
    'c': c,
    'mtx': mtx,
    'fp': fp,
  };

  @override
  String toString() =>
      'ModelX(i=$i, n=$n, c=$c, category=$category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

enum ModelTypeCategory {
  noMap, // 300000: No usable direct table link
  singleTable, // 310000: Links to one distinct table
  multipleTables, // 330000: Links to two or more distinct tables
  system, // 390000: System-managed mapping
  unknown,
}
