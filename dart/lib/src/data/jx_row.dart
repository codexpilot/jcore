/// Row data structure with mixed array access.
///
/// Provides both index-based and name-based field access for JX row data.
/// Preserves exact INT64 and NUMERIC values without precision loss.
library;

import 'jx_schema.dart';

/// A single row of data with mixed access patterns.
///
/// Usage:
/// ```dart
/// final row = JxRow(
///   schema: schema,
///   cells: [1, 'John Doe', 1234567890123, '123.45'],
/// );
///
/// // Index access
/// print(row[0]); // 1
/// print(row[1]); // 'John Doe'
///
/// // Name access
/// print(row['id']); // 1
/// print(row['name']); // 'John Doe'
///
/// // Type-safe access
/// print(row.getInt('id')); // 1
/// print(row.getString('name')); // 'John Doe'
/// print(row.getInt64('timestamp')); // 1234567890123
/// print(row.getNumeric('amount')); // '123.45'
/// ```
class JxRow {
  /// Schema defining field order and names
  final JxSchema schema;

  /// Cell values in schema order
  final List<dynamic> cells;

  /// Cached name-to-index mapping
  late final Map<String, int> _nameIndex;

  JxRow({
    required this.schema,
    required this.cells,
  }) {
    if (cells.length != schema.fieldCount) {
      throw ArgumentError(
        'Cell count ${cells.length} does not match schema field count '
        '${schema.fieldCount}',
      );
    }
    _nameIndex = {
      for (var i = 0; i < schema.fields.length; i++) schema.fields[i].n: i
    };
  }

  /// Index-based access: row[0], row[1], etc.
  dynamic operator [](dynamic key) {
    if (key is int) {
      return cells[key];
    } else if (key is String) {
      final index = _nameIndex[key];
      if (index == null) {
        throw ArgumentError('Field name not found: $key');
      }
      return cells[index];
    } else {
      throw ArgumentError('Key must be int or String, got ${key.runtimeType}');
    }
  }

  /// Get value as int (safe for regular integers)
  int? getInt(String fieldName) {
    final value = this[fieldName];
    if (value == null) return null;
    return value as int;
  }

  /// Get value as String
  String? getString(String fieldName) {
    final value = this[fieldName];
    if (value == null) return null;
    return value as String;
  }

  /// Get value as bool
  bool? getBool(String fieldName) {
    final value = this[fieldName];
    if (value == null) return null;
    return value as bool;
  }

  /// Get exact INT64 value (preserved as int or String depending on magnitude)
  ///
  /// For values beyond Dart's safe integer range (2^53-1), the backend should
  /// encode them as strings. This method returns the value as-is.
  dynamic getInt64(String fieldName) {
    return this[fieldName];
  }

  /// Get exact NUMERIC/DECIMAL value (preserved as String)
  ///
  /// Numeric values requiring exact precision are encoded as strings to avoid
  /// floating-point precision loss. Use this for financial amounts, percentages,
  /// and other values where exact decimal representation is required.
  String? getNumeric(String fieldName) {
    final value = this[fieldName];
    if (value == null) return null;
    return value as String;
  }

  /// Get value at index
  dynamic getAt(int index) {
    return cells[index];
  }

  /// Check if field exists and is non-null
  bool hasValue(String fieldName) {
    return _nameIndex.containsKey(fieldName) && this[fieldName] != null;
  }

  /// Get all field names
  List<String> get fieldNames => schema.fields.map((f) => f.n).toList();

  /// Convert row to `Map<String, dynamic>`
  Map<String, dynamic> toMap() {
    return {
      for (var i = 0; i < schema.fields.length; i++)
        schema.fields[i].n: cells[i]
    };
  }

  @override
  String toString() => 'JxRow(${toMap()})';
}

/// Composed row with named sections.
///
/// Used for structured models like SalesInvoice with multiple related entities.
///
/// Usage:
/// ```dart
/// final invoice = JxComposedRow(
///   schema: invoiceSchema,
///   cells: [1, 'INV-001', '2024-01-15'],
///   sections: {
///     'invoiceInfo': JxOneSection(row: headerRow),
///     'invoiceDetails': JxManySection(rows: [item1, item2]),
///     'payments': JxManySection(rows: [payment1]),
///   },
/// );
///
/// // Access root fields
/// print(invoice['invoice_id']); // 1
///
/// // Access one section
/// final header = invoice.getOne('invoiceInfo');
/// print(header?['customer_name']); // 'Acme Corp'
///
/// // Access many section
/// final items = invoice.getMany('invoiceDetails');
/// for (final item in items) {
///   print(item['product_name']);
/// }
/// ```
class JxComposedRow extends JxRow {
  /// Named sections: 'one' sections contain a single child row or null,
  /// 'many' sections contain a list of rows or empty list.
  final Map<String, JxSection> sections;

  JxComposedRow({
    required super.schema,
    required super.cells,
    required this.sections,
  });

  /// Get a 'one' section (single child row or null)
  JxRow? getOne(String sectionKey) {
    final section = sections[sectionKey];
    if (section is JxOneSection) {
      return section.row;
    }
    throw ArgumentError('Section "$sectionKey" is not a one section');
  }

  /// Get a 'many' section (list of rows, possibly empty)
  List<JxRow> getMany(String sectionKey) {
    final section = sections[sectionKey];
    if (section is JxManySection) {
      return section.rows;
    }
    throw ArgumentError('Section "$sectionKey" is not a many section');
  }

  /// Check if section exists
  bool hasSection(String sectionKey) => sections.containsKey(sectionKey);

  /// Get all section keys
  List<String> get sectionKeys => sections.keys.toList();
}

/// Base class for sections
sealed class JxSection {
  const JxSection();
}

/// One section: contains a single child row or null
class JxOneSection extends JxSection {
  final JxRow? row;

  const JxOneSection({this.row});
}

/// Many section: contains a list of child rows (possibly empty)
class JxManySection extends JxSection {
  final List<JxRow> rows;

  const JxManySection({required this.rows});
}
