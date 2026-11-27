/// In-memory QueryService implementation for fixtures and testing.
///
/// Provides a simple in-memory backend for sales invoice fixture data.
/// Supports get and save operations on the sample invoice.
library;

import '../data/composed_row_decoder.dart';
import '../data/jx_row.dart';
import '../data/jx_schema.dart';
import '../data/query_service.dart';
import 'sales_invoice_fixture.dart';

/// In-memory query service for Sales Invoice fixture.
///
/// Query IDs:
/// - 5000: Get invoice by ID
/// - 5001: Save invoice (insert or update)
///
/// Save payload format:
/// ```dart
/// {
///   'i': 1,                    // Record ID
///   'v': 1,                    // Expected record version
///   'customer_name': 'Updated', // Edited fields (omitted = no change, null = clear)
///   'invoiceDetails': [...],   // Updated section rows
///   '_removed_invoiceDetails': [1, 2],  // Explicit removed row IDs
///   'payments': [...],
///   '_removed_payments': [3],
/// }
/// ```
///
/// Usage:
/// ```dart
/// final service = InMemoryQueryService();
/// DbContext.instance.setQueryService(service);
///
/// // Load invoice
/// final result = await service.executeQuery(5000, {'i': 1});
///
/// // Save invoice
/// final saved = await service.executeQuery(5001, {
///   'i': 1,
///   'v': 1,
///   'customer_name': 'Updated Customer',
///   'invoiceDetails': [...],
///   '_removed_invoiceDetails': [1],
/// });
/// ```
class InMemoryQueryService implements QueryService {
  /// In-memory storage for invoices (keyed by invoice_id)
  final Map<int, JxComposedRow> _invoices = {};

  /// Failure simulation flag for testing
  bool _shouldFail = false;

  InMemoryQueryService() {
    // Initialize with sample invoice
    _invoices[1] = SalesInvoiceFixture.createSampleInvoice();
  }

  /// Enable failure simulation for testing error handling
  void simulateFailure(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    if (_shouldFail) {
      throw Exception('Simulated query failure');
    }

    switch (queryId) {
      case SalesInvoiceFixture.fetchQueryId:
        return _getInvoice(params);
      case SalesInvoiceFixture.saveQueryId:
        return _saveInvoice(params);
      default:
        throw Exception('Unknown query ID: $queryId');
    }
  }

  /// Get invoice by ID
  dynamic _getInvoice(Map<String, dynamic> params) {
    final id = params['i'] as int?;
    if (id == null) {
      throw ArgumentError('Missing invoice ID (i)');
    }

    final invoice = _invoices[id];
    if (invoice == null) {
      throw Exception('Invoice not found: $id');
    }

    return _serializeInvoice(invoice);
  }

  /// Save invoice (insert or update)
  dynamic _saveInvoice(Map<String, dynamic> params) {
    final id = params['i'] as int? ?? 0;

    if (id == 0) {
      // Insert new invoice (not implemented in fixture)
      throw Exception('Insert not supported in fixture');
    }

    // Update existing invoice
    final existing = _invoices[id];
    if (existing == null) {
      throw Exception('Invoice not found: $id');
    }

    final currentVersion = existing['v'] as int;
    if (params.containsKey('v') && params['v'] != currentVersion) {
      throw StateError('Invoice $id record version changed');
    }

    final schema = existing.schema;
    final updatedCells = List.of(existing.cells);
    for (var i = 0; i < schema.fields.length; i++) {
      final code = schema.fields[i].c;
      if (code == 'v') {
        updatedCells[i] = currentVersion + 1;
      } else if (params.containsKey(code)) {
        updatedCells[i] = params[code];
      }
    }

    final updatedSections = Map.of(existing.sections);
    for (final section in SalesInvoiceFixture.projection.sections) {
      if (params.containsKey(section.key)) {
        updatedSections[section.key] = _decodeSectionEdit(
          params[section.key],
          section,
        );
      }
    }

    // Create updated invoice
    final updated = JxComposedRow(
      schema: schema,
      cells: updatedCells,
      sections: updatedSections,
    );

    // Store updated invoice
    _invoices[id] = updated;

    return _serializeInvoice(updated);
  }

  JxSection _decodeSectionEdit(Object? value, JxResultSection section) {
    if (value is! List) {
      throw ArgumentError('Expected an array for "${section.key}" edits');
    }
    if (section.cardinality == JxSectionCardinality.one) {
      if (value.length > 1) {
        throw ArgumentError('Expected at most one row for "${section.key}"');
      }
      return JxOneSection(
        row: value.isEmpty
            ? null
            : _decodeEditRow(value.single, section.schema),
      );
    }
    return JxManySection(
      rows: [for (final row in value) _decodeEditRow(row, section.schema)],
    );
  }

  JxRow _decodeEditRow(Object? value, JxSchema schema) {
    if (value is! Map<String, Object?>) {
      throw ArgumentError('Expected a section edit object');
    }
    return JxRow(
      schema: schema,
      cells: [for (final field in schema.fields) value[field.c]],
    );
  }

  Map<String, dynamic> _serializeInvoice(JxComposedRow invoice) {
    final result = invoice.toMap();
    for (final entry in invoice.sections.entries) {
      result[entry.key] = switch (entry.value) {
        JxOneSection(:final row) => row?.toMap(),
        JxManySection(:final rows) => [for (final row in rows) row.toMap()],
      };
    }
    return result;
  }

  /// Get invoice directly (for testing)
  JxComposedRow? getInvoiceDirect(int id) => _invoices[id];

  /// Clear all data (for testing)
  void clear() {
    _invoices.clear();
  }

  /// Reset to initial state (for testing)
  void reset() {
    _invoices.clear();
    _invoices[1] = SalesInvoiceFixture.createSampleInvoice();
  }
}
