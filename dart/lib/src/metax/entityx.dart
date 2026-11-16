/// Logical entity metadata (mx.entityx table)
class EntityX {
  /// Entity metadata ID
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

  /// Parent entity IDs
  final List<int> p;

  /// Code (unique)
  final String c;

  /// Entity type (TypeX Group 6: 300000-399999)
  final int et;

  /// Model state: draft | ready
  final String modelState;

  /// Origin
  final int f;

  const EntityX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.di,
    required this.n,
    this.p = const [],
    required this.c,
    this.et = 320001,
    this.modelState = 'draft',
    this.f = 0,
  });

  /// Entity type category
  EntityTypeCategory get category {
    if (et >= 300000 && et <= 300004) return EntityTypeCategory.operationOnly;
    if (et >= 310001 && et <= 310004) return EntityTypeCategory.storageMapped;
    if (et >= 320001 && et <= 320004) return EntityTypeCategory.entityFirst;
    return EntityTypeCategory.unknown;
  }

  /// Is entity ready for operations?
  bool get isReady => modelState == 'ready';

  factory EntityX.fromJson(Map<String, dynamic> json) {
    return EntityX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      di: json['di'] as int,
      n: json['n'] as String,
      p: (json['p'] as List<dynamic>?)?.cast<int>() ?? const [],
      c: json['c'] as String,
      et: json['et'] as int? ?? 320001,
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
    'et': et,
    'model_state': modelState,
    'f': f,
  };

  @override
  String toString() =>
      'EntityX(i=$i, n=$n, c=$c, category=$category, state=$modelState)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

enum EntityTypeCategory {
  operationOnly, // 300000-300004: No storage
  storageMapped, // 310001-310004: Direct table mapping
  entityFirst, // 320001-320004: Composed from multiple tables
  unknown,
}
