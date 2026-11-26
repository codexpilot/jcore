/// Enhanced DbContext deserializer using MapX composition metadata.
///
/// Decodes composed rows using published section schema from effective QueryX
/// and resolves sections by published keys and cardinality from MapX.
///
/// Wire JSON uses logical field codes (field.c), while named row access
/// uses schema names (field.n).
library;

import 'package:jcore/metax.dart';
import 'jx_schema.dart';
import 'jx_row.dart';

/// Section metadata from MapX composition rules.
class SectionMetadata {
  final String key;
  final String cardinality; // 'one' or 'many'
  final int childModelId;

  SectionMetadata({
    required this.key,
    required this.cardinality,
    required this.childModelId,
  });
}

/// Deserialize composed row from API response.
///
/// Uses MapX metadata to resolve section keys and cardinality.
/// Preserves exact INT64 and NUMERIC values from backend.
JxRow deserializeComposedRow(
  Map<String, dynamic> result,
  ModelX model,
  JxSchema schema,
  Map<int, JxSchema> childSchemas,
  List<SectionMetadata> sections,
) {
  // Extract root cells (parent model fields)
  // Wire JSON uses logical field codes (field.c)
  final cells = <dynamic>[];
  for (final field in schema.fields) {
    cells.add(result[field.c]);
  }

  // If not composed, return simple row
  if (!model.isComposed || sections.isEmpty) {
    return JxRow(schema: schema, cells: cells);
  }

  // Build sections map
  final sectionMap = <String, JxSection>{};

  for (final section in sections) {
    final sectionKey = section.key;
    final childSchema = childSchemas[section.childModelId];

    if (childSchema == null) {
      throw ArgumentError(
        'Schema not found for child model ${section.childModelId}',
      );
    }

    final sectionData = result[sectionKey];

    if (section.cardinality == 'one') {
      // One section: expect object or null
      if (sectionData == null) {
        sectionMap[sectionKey] = const JxOneSection(row: null);
      } else if (sectionData is Map<String, dynamic>) {
        final row = _mapToRow(sectionData, childSchema);
        sectionMap[sectionKey] = JxOneSection(row: row);
      } else {
        throw ArgumentError(
          'Expected object or null for one section "$sectionKey", got ${sectionData.runtimeType}',
        );
      }
    } else if (section.cardinality == 'many') {
      // Many section: expect array (possibly empty)
      if (sectionData == null) {
        sectionMap[sectionKey] = const JxManySection(rows: []);
      } else if (sectionData is List) {
        final rows = sectionData
            .map((d) => _mapToRow(d as Map<String, dynamic>, childSchema))
            .toList();
        sectionMap[sectionKey] = JxManySection(rows: rows);
      } else {
        throw ArgumentError(
          'Expected array for many section "$sectionKey", got ${sectionData.runtimeType}',
        );
      }
    }
  }

  return JxComposedRow(
    schema: schema,
    cells: cells,
    sections: sectionMap,
  );
}

/// Convert Map to JxRow using schema.
///
/// Wire JSON uses logical field codes (field.c).
/// Preserves exact INT64 and NUMERIC values as received from backend.
JxRow _mapToRow(Map<String, dynamic> map, JxSchema schema) {
  final cells = <dynamic>[];
  for (final field in schema.fields) {
    // Wire JSON uses field codes - preserve exact values without conversion
    cells.add(map[field.c]);
  }
  return JxRow(schema: schema, cells: cells);
}
