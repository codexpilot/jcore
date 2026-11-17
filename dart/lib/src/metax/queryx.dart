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
  final int di;

  /// Display name
  final String n;

  /// Code (operation identifier)
  final String c;

  /// Target kind: system | table | model
  final String targetKind;

  /// Table ID (when targetKind='table')
  final int? tableId;

  /// Model ID (when targetKind='model')
  final int? modelId;

  /// Query type (TypeX Group 8: 500000-520001)
  final int qt;

  /// Origin
  final int f;

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
    required this.di,
    required this.n,
    required this.c,
    this.targetKind = 'model',
    this.tableId,
    this.modelId,
    required this.qt,
    this.f = 0,
    this.inputFields,
    this.outputFields,
    this.operationRole,
  });

  /// Query type category
  QueryTypeCategory get category {
    if (qt >= 500000 && qt <= 500001) return QueryTypeCategory.system;
    if (qt >= 510000 && qt <= 510001) return QueryTypeCategory.table;
    if (qt >= 520000 && qt <= 520001) return QueryTypeCategory.model;
    return QueryTypeCategory.unknown;
  }

  /// Is this a Get operation?
  bool get isGet => qt % 2 == 0;

  /// Is this a Set operation?
  bool get isSet => qt % 2 == 1;

  factory QueryX.fromJson(Map<String, dynamic> json) {
    return QueryX(
      i: json['i'] as int,
      d: json['d'] as int,
      e: json['e'] as int,
      a: json['a'] as int,
      di: json['di'] as int,
      n: json['n'] as String,
      c: json['c'] as String,
      targetKind: json['target_kind'] as String? ?? 'model',
      tableId: json['table_id'] as int?,
      modelId: json['model_id'] as int?,
      qt: json['qt'] as int,
      f: json['f'] as int? ?? 0,
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
    'di': di,
    'n': n,
    'c': c,
    'target_kind': targetKind,
    if (tableId != null) 'table_id': tableId,
    if (modelId != null) 'model_id': modelId,
    'qt': qt,
    'f': f,
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
