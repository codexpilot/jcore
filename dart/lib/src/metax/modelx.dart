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

  /// Code (unique)
  final String c;

  /// Model type (TypeX Group 6: 300000-399999)
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
    required this.c,
    this.mtx = 320001,
    this.fp = 0,
  });

  /// Model type category
  ModelTypeCategory get category {
    if (mtx >= 300000 && mtx <= 300004) return ModelTypeCategory.operationOnly;
    if (mtx >= 310001 && mtx <= 310004) return ModelTypeCategory.storageMapped;
    if (mtx >= 320001 && mtx <= 320004) return ModelTypeCategory.modelFirst;
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
      c: json['c'] as String,
      mtx: json['mtx'] as int? ?? 320001,
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
  operationOnly, // 300000-300004: No storage
  storageMapped, // 310001-310004: Direct table mapping
  modelFirst, // 320001-320004: Composed from multiple tables
  unknown,
}
