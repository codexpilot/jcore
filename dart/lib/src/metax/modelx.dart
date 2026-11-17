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

  /// Domain ID
  final int di;

  /// Display name
  final String n;

  /// Parent model IDs
  final List<int> p;

  /// Code (unique)
  final String c;

  /// Model type (TypeX Group 6: 300000-399999)
  final int mt;

  /// Model state: draft | ready
  final String modelState;

  /// Origin
  final int f;

  const ModelX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.di,
    required this.n,
    this.p = const [],
    required this.c,
    this.mt = 320001,
    this.modelState = 'draft',
    this.f = 0,
  });

  /// Model type category
  ModelTypeCategory get category {
    if (mt >= 300000 && mt <= 300004) return ModelTypeCategory.operationOnly;
    if (mt >= 310001 && mt <= 310004) return ModelTypeCategory.storageMapped;
    if (mt >= 320001 && mt <= 320004) return ModelTypeCategory.modelFirst;
    return ModelTypeCategory.unknown;
  }

  /// Is model ready for operations?
  bool get isReady => modelState == 'ready';

  factory ModelX.fromJson(Map<String, dynamic> json) {
    return ModelX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      di: json['di'] as int,
      n: json['n'] as String,
      p: (json['p'] as List<dynamic>?)?.cast<int>() ?? const [],
      c: json['c'] as String,
      mt: json['mt'] as int? ?? 320001,
      modelState: json['model_state'] as String? ?? 'draft',
      f: json['f'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'i': i,
    'd': d,
    'e': e,
    'a': a,
    'di': di,
    'n': n,
    'p': p,
    'c': c,
    'mt': mt,
    'model_state': modelState,
    'f': f,
  };

  @override
  String toString() =>
      'ModelX(i=$i, n=$n, c=$c, category=$category, state=$modelState)';

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
