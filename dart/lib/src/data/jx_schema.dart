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
  /// Ordered list of fields matching row cell positions
  final List<JxField> fields;

  const JxSchema(this.fields);

  /// Number of fields in the schema
  int get fieldCount => fields.length;

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
