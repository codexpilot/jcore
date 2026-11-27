/// Decode object results using the schema published for each section path.
library;

import 'package:jcore/metax.dart';

import 'jx_row.dart';
import 'jx_schema.dart';

/// How many records a published result section can contain.
enum JxSectionCardinality { one, many }

/// The projection for a named occurrence of a section in a query result.
///
/// Each occurrence owns its schema, even when multiple sections select fields
/// from the same model. [identityCode] is the optional wire key for the
/// persisted child ID used when editing the section.
final class JxResultSection {
  JxResultSection({
    required this.key,
    required this.cardinality,
    required this.schema,
    Iterable<JxResultSection> sections = const [],
    this.identityCode,
  }) : sections = List.unmodifiable(sections) {
    if (key.isEmpty || key != key.trim()) {
      throw ArgumentError.value(key, 'key', 'Expected a nonempty, trimmed key');
    }
    _validateProjection(schema, this.sections);
    final idCode = identityCode;
    if (idCode != null && !schema.fields.any((field) => field.c == idCode)) {
      throw ArgumentError.value(
        idCode,
        'identityCode',
        'Section "$key" does not project that field code',
      );
    }
  }

  final String key;
  final JxSectionCardinality cardinality;
  final JxSchema schema;
  final List<JxResultSection> sections;
  final String? identityCode;
}

/// An immutable snapshot of the result published for one query version.
final class JxResultProjection {
  JxResultProjection({
    required this.modelId,
    required this.version,
    required this.schema,
    Iterable<JxResultSection> sections = const [],
  }) : sections = List.unmodifiable(sections) {
    if (version.trim().isEmpty) {
      throw ArgumentError.value(version, 'version', 'Expected a version');
    }
    _validateProjection(schema, this.sections);
  }

  final int modelId;
  final String version;
  final JxSchema schema;
  final List<JxResultSection> sections;

  /// Persisted child identity codes for the root sections of the result.
  late final Map<String, String> sectionIdentityCodes = Map.unmodifiable({
    for (final section in sections) section.key: ?section.identityCode,
  });

  /// Decode a record without changing the wire representation of its values.
  JxRow decode(Object? result) =>
      _decodeRow(result, schema, sections, r'$', requireAllKeys: true);
}

/// Decode a record whose wire keys are logical field codes.
///
/// All projected keys must be present. A nullable field or a [JxSectionCardinality.one]
/// section can be explicitly null. Extra keys are ignored so response metadata
/// stays separate from the projected columns.
JxRow decodeRecord(
  Object? result,
  JxSchema schema, {
  Iterable<JxResultSection> sections = const [],
}) {
  final projectedSections = sections.toList(growable: false);
  _validateProjection(schema, projectedSections);
  return _decodeRow(
    result,
    schema,
    projectedSections,
    r'$',
    requireAllKeys: true,
  );
}

void _validateProjection(JxSchema schema, List<JxResultSection> sections) {
  schema.validateUniqueCodes();
  if (sections.isEmpty) return;

  final keys = schema.fields.map((field) => field.c).toSet();
  for (final section in sections) {
    if (!keys.add(section.key)) {
      throw ArgumentError('Duplicate result key: "${section.key}"');
    }
  }
}

JxRow _decodeRow(
  Object? result,
  JxSchema schema,
  List<JxResultSection> sections,
  String path, {
  required bool requireAllKeys,
}) {
  if (result is! Map<String, Object?>) {
    throw FormatException('Expected an object at $path');
  }

  final cells = <Object?>[];
  for (final field in schema.fields) {
    final value = result[field.c];
    if (value == null && requireAllKeys && !result.containsKey(field.c)) {
      throw FormatException('Missing field "${field.c}" at $path');
    }
    cells.add(value);
  }
  if (sections.isEmpty) return JxRow(schema: schema, cells: cells);

  final decodedSections = <String, JxSection>{};
  for (final section in sections) {
    final sectionPath = '$path.${section.key}';
    final value = result[section.key];
    if (value == null && requireAllKeys && !result.containsKey(section.key)) {
      throw FormatException('Missing section at $sectionPath');
    }
    switch (section.cardinality) {
      case JxSectionCardinality.one:
        decodedSections[section.key] = JxOneSection(
          row: value == null
              ? null
              : _decodeRow(
                  value,
                  section.schema,
                  section.sections,
                  sectionPath,
                  requireAllKeys: requireAllKeys,
                ),
        );
      case JxSectionCardinality.many:
        if (!requireAllKeys && value == null) {
          decodedSections[section.key] = JxManySection(rows: []);
          continue;
        }
        if (value is! List) {
          throw FormatException('Expected an array at $sectionPath');
        }
        final rows = <JxRow>[];
        for (final child in value) {
          rows.add(
            _decodeRow(
              child,
              section.schema,
              section.sections,
              '$sectionPath[${rows.length}]',
              requireAllKeys: requireAllKeys,
            ),
          );
        }
        decodedSections[section.key] = JxManySection(rows: rows);
    }
  }
  return JxComposedRow(schema: schema, cells: cells, sections: decodedSections);
}

/// Model-ID keyed section metadata for the legacy decoder entry point.
class SectionMetadata {
  const SectionMetadata({
    required this.key,
    required this.cardinality,
    required this.childModelId,
  });

  final String key;
  final String cardinality;
  final int childModelId;
}

/// Decode a legacy response with one schema per child model.
///
/// Use [JxResultProjection] for published projections and nested sections.
JxRow deserializeComposedRow(
  Map<String, dynamic> result,
  ModelX model,
  JxSchema schema,
  Map<int, JxSchema> childSchemas,
  List<SectionMetadata> sections,
) {
  final projectedSections = <JxResultSection>[
    if (model.isComposed)
      for (final section in sections)
        JxResultSection(
          key: section.key,
          cardinality: JxSectionCardinality.values.byName(section.cardinality),
          schema:
              childSchemas[section.childModelId] ??
              (throw ArgumentError(
                'Schema not found for child model ${section.childModelId}',
              )),
        ),
  ];
  _validateProjection(schema, projectedSections);
  return _decodeRow(
    result,
    schema,
    projectedSections,
    r'$',
    requireAllKeys: false,
  );
}
