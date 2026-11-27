/// JX schema metadata for field/column definitions.
library;

/// Field metadata for JX encoding/decoding.
///
/// Represents a single field/column with its identifier, code, name, and type.
class JxField {
  /// Field identifier (FieldX.i or ColumnX.i)
  final int i;

  /// Field code (FieldX.c or ColumnX.c)
  final String c;

  /// Field name (FieldX.n or ColumnX.n)
  final String n;

  /// Data type identifier (TypeX.i)
  final int typeId;

  /// Data type code (TypeX.c) - optional
  final String? typeCode;

  /// Data type name (TypeX.n)
  final String typeName;

  const JxField({
    required this.i,
    required this.c,
    required this.n,
    required this.typeId,
    this.typeCode,
    required this.typeName,
  });

  /// Create from FieldX and TypeX metadata
  factory JxField.fromMeta({
    required int fieldId,
    required String fieldCode,
    required String fieldName,
    required int typeId,
    String? typeCode,
    required String typeName,
  }) {
    return JxField(
      i: fieldId,
      c: fieldCode,
      n: fieldName,
      typeId: typeId,
      typeCode: typeCode,
      typeName: typeName,
    );
  }
}

/// Schema context for JX encoding/decoding.
///
/// Provides ordered field metadata required for compact encodings (J=1, 2, 3, 4).
class JxSchema {
  /// Immutable ordered list of fields matching row cell positions.
  final List<JxField> fields;

  JxSchema(List<JxField> fields) : fields = List.unmodifiable(fields);

  late final _idIndex = _buildIndex((field) => field.i);
  late final _codeIndex = _buildIndex((field) => field.c);
  late final _nameIndex = _buildIndex((field) => field.n);

  /// Number of fields in the schema
  int get fieldCount => fields.length;

  /// Find the offset for a metadata ID, or null if absent.
  ///
  /// Throws [ArgumentError] if the ID matches multiple fields.
  int? indexById(int id) => _findOffset(_idIndex, id, 'ID');

  /// Find the offset for an exact code, or null if absent.
  ///
  /// Throws [ArgumentError] if the code matches multiple fields.
  int? indexByCode(String code) => _findOffset(_codeIndex, code, 'code');

  /// Find the offset for an exact display name, or null if absent.
  ///
  /// Throws [ArgumentError] if the name matches multiple fields.
  int? indexByName(String name) => _findOffset(_nameIndex, name, 'name');

  /// Find the last offset for an exact display name, or null if absent.
  ///
  /// Used for the legacy behavior of named bracket access in JxRow.
  int? lastIndexByName(String name) => _nameIndex[name]?.offset;

  Map<K, _FieldPosition> _buildIndex<K>(K Function(JxField) keyFor) {
    final index = <K, _FieldPosition>{};
    for (final (offset, field) in fields.indexed) {
      final key = keyFor(field);
      index[key] = (offset: offset, isAmbiguous: index.containsKey(key));
    }
    return index;
  }

  int? _findOffset<K>(Map<K, _FieldPosition> index, K key, String keyKind) {
    final position = index[key];
    if (position != null && position.isAmbiguous) {
      throw ArgumentError('Ambiguous field $keyKind: $key');
    }
    return position?.offset;
  }

  /// Validate that field names are unique (required for J=4, J=9)
  void validateUniqueNames() {
    final names = <String>{};
    for (final field in fields) {
      if (!names.add(field.n)) {
        throw FormatException('Duplicate field name: ${field.n}');
      }
    }
  }

  /// Validate that field codes are unique (required for J=3, J=8, J=9)
  void validateUniqueCodes() {
    final codes = <String>{};
    for (final field in fields) {
      if (!codes.add(field.c)) {
        throw FormatException('Duplicate field code: ${field.c}');
      }
    }
  }
}

typedef _FieldPosition = ({int offset, bool isAmbiguous});
