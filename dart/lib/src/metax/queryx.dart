/// Query operation metadata (mx.queryx table)
class QueryX {
  /// Query ID
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

  /// Provenance: 0=native, >0=copied, <0=imported
  final int f;

  /// Code (operation identifier)
  final String c;

  /// Target kind: system | table | model
  final String targetKind;

  /// Table ID (when targetKind='table')
  final int? tableId;

  /// Model ID (when targetKind='model')
  final int? modelId;

  /// Query type (TypeX Group 8: 500000-520001)
  final int qtx;

  /// Optional recursive parent identifier; existence is not guaranteed.
  final int fp;

  /// Input field IDs (P1 extension)
  final List<int>? inputFields;

  /// Output field IDs (P1 extension)
  final List<int>? outputFields;

  /// Operation role (P1 extension)
  final String? operationRole;

  const QueryX({
    required this.i,
    required this.d,
    required this.e,
    required this.a,
    required this.dxi,
    required this.n,
    required this.f,
    required this.c,
    this.targetKind = 'model',
    this.tableId,
    this.modelId,
    required this.qtx,
    this.fp = 0,
    this.inputFields,
    this.outputFields,
    this.operationRole,
  });

  /// Query type category
  QueryTypeCategory get category {
    if (qtx >= 500000 && qtx <= 500001) return QueryTypeCategory.system;
    if (qtx >= 510000 && qtx <= 510001) return QueryTypeCategory.table;
    if (qtx >= 520000 && qtx <= 520001) return QueryTypeCategory.model;
    return QueryTypeCategory.unknown;
  }

  /// Is this a Get operation?
  bool get isGet => qtx % 2 == 0;

  /// Is this a Set operation?
  bool get isSet => qtx % 2 == 1;

  factory QueryX.fromJson(Map<String, dynamic> json) {
    return QueryX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      dxi: json['dxi'] as int,
      n: json['n'] as String,
      f: json['f'] as int,
      c: json['c'] as String,
      targetKind: json['target_kind'] as String? ?? 'model',
      tableId: json['table_id'] as int?,
      modelId: json['model_id'] as int?,
      qtx: json['qtx'] as int,
      fp: json['fp'] as int? ?? 0,
      inputFields: (json['input_fields'] as List<dynamic>?)?.cast<int>(),
      outputFields: (json['output_fields'] as List<dynamic>?)?.cast<int>(),
      operationRole: json['operation_role'] as String?,
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
    'c': c,
    'target_kind': targetKind,
    if (tableId != null) 'table_id': tableId,
    if (modelId != null) 'model_id': modelId,
    'qtx': qtx,
    'fp': fp,
    if (inputFields != null) 'input_fields': inputFields,
    if (outputFields != null) 'output_fields': outputFields,
    if (operationRole != null) 'operation_role': operationRole,
  };

  @override
  String toString() => 'QueryX(i=$i, n=$n, c=$c, category=$category)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryX && runtimeType == other.runtimeType && i == other.i;

  @override
  int get hashCode => i.hashCode;
}

enum QueryTypeCategory {
  system, // 500000-500001
  table, // 510000-510001
  model, // 520000-520001
  unknown,
}
