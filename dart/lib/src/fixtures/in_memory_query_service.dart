/// In-memory QueryService implementation for fixtures and testing.
///
/// Provides a simple in-memory backend for sales invoice fixture data.
/// Supports get and save operations on the sample invoice.
library;

import '../data/query_service.dart';
import '../data/jx_row.dart';
import '../data/jx_schema.dart';
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
///   'v': 1,                    // Schema version
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
      case 5000: // Get invoice by ID
        return _getInvoice(params);
      case 5001: // Save invoice
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

    // Apply field updates
    final updatedCells = List<dynamic>.from(existing.cells);
    final schema = existing.schema;

    // Update root fields
    for (var i = 0; i < schema.fields.length; i++) {
      final fieldName = schema.fields[i].n;
      if (params.containsKey(fieldName)) {
        updatedCells[i] = params[fieldName];
      }
    }

    // Update sections
    final updatedSections = <String, JxSection>{};

    // Process invoiceInfo section (one)
    if (params.containsKey('invoiceInfo')) {
      final infoData = params['invoiceInfo'] as List;
      if (infoData.isNotEmpty) {
        final infoMap = infoData.first as Map<String, dynamic>;
        final infoRow = _mapToRow(infoMap, SalesInvoiceSchemas.invoiceHeader);
        updatedSections['invoiceInfo'] = JxOneSection(row: infoRow);
      } else {
        updatedSections['invoiceInfo'] = const JxOneSection(row: null);
      }
    } else {
      // Keep existing
      updatedSections['invoiceInfo'] = existing.sections['invoiceInfo']!;
    }

    // Process invoiceDetails section (many)
    // The payload contains the full list after removals and edits
    // _removed_invoiceDetails contains explicit removed IDs for validation
    if (params.containsKey('invoiceDetails')) {
      final detailsData = params['invoiceDetails'] as List;
      final detailRows = detailsData
          .map((d) => _mapToRow(d as Map<String, dynamic>, SalesInvoiceSchemas.lineItem))
          .toList();
      updatedSections['invoiceDetails'] = JxManySection(rows: detailRows);

      // Log removed IDs if present (for debugging/validation)
      if (params.containsKey('_removed_invoiceDetails')) {
        // In a real implementation, this would validate the removal was authorized
        // For fixture, we just accept the new state
      }
    } else {
      // Keep existing
      updatedSections['invoiceDetails'] = existing.sections['invoiceDetails']!;
    }

    // Process payments section (many)
    if (params.containsKey('payments')) {
      final paymentsData = params['payments'] as List;
      final paymentRows = paymentsData
          .map((p) => _mapToRow(p as Map<String, dynamic>, SalesInvoiceSchemas.payment))
          .toList();
      updatedSections['payments'] = JxManySection(rows: paymentRows);

      // Log removed IDs if present
      if (params.containsKey('_removed_payments')) {
        // Validation placeholder
      }
    } else {
      // Keep existing
      updatedSections['payments'] = existing.sections['payments']!;
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

  /// Convert Map to JxRow using schema.
  ///
  /// Wire JSON uses logical field codes (field.c).
  JxRow _mapToRow(Map<String, dynamic> map, JxSchema schema) {
    final cells = <dynamic>[];
    for (final field in schema.fields) {
      // Wire JSON uses field codes
      cells.add(map[field.c]);
    }
    return JxRow(schema: schema, cells: cells);
  }

  /// Serialize invoice to map format
  Map<String, dynamic> _serializeInvoice(JxComposedRow invoice) {
    final result = invoice.toMap();

    // Add sections
    result['invoiceInfo'] = [
      if (invoice.getOne('invoiceInfo') != null)
        invoice.getOne('invoiceInfo')!.toMap()
    ];

    result['invoiceDetails'] = invoice
        .getMany('invoiceDetails')
        .map((r) => r.toMap())
        .toList();

    result['payments'] = invoice
        .getMany('payments')
        .map((r) => r.toMap())
        .toList();

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
