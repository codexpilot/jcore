/// Sales Invoice fixtures for testing and fresh installations.
///
/// Provides sample Sales Invoice schema and data demonstrating:
/// - Composed model with sections (invoiceInfo, invoiceDetails, payments)
/// - One-level composition with non-composed child models
/// - Exact INT64 and NUMERIC preservation
/// - Mixed array access patterns
library;

import '../data/db_context.dart';
import '../data/jx_row.dart';
import '../data/jx_schema.dart';
import '../metax/modelx.dart';

/// Sales Invoice domain models for demonstration.
class SalesInvoiceModels {
  // Model IDs
  static const int salesInvoiceId = 500;
  static const int invoiceHeaderId = 501;
  static const int invoiceLineItemId = 502;
  static const int invoicePaymentId = 503;

  /// SalesInvoice composed model (mtx: 370000)
  static final ModelX salesInvoice = ModelX(
    i: salesInvoiceId,
    d: 1737590400000, // 2025-01-23
    e: 0,
    a: 1,
    dxi: 1,
    n: 'Sales Invoice',
    f: 0,
    ps: const [],
    txis: const [],
    mxis: const [invoiceHeaderId, invoiceLineItemId, invoicePaymentId],
    c: 'sale_invoice',
    mtx: 370000, // Composed model type
    fp: 0,
  );

  /// InvoiceHeader model (non-composed)
  static final ModelX invoiceHeader = ModelX(
    i: invoiceHeaderId,
    d: 1737590400000,
    e: 0,
    a: 1,
    dxi: 1,
    n: 'Invoice Header',
    f: 0,
    ps: const [salesInvoiceId],
    txis: const [],
    mxis: const [], // Non-composed
    c: 'invoice_header',
    mtx: 320000, // Model-claimed-table
    fp: 0,
  );

  /// InvoiceLineItem model (non-composed)
  static final ModelX invoiceLineItem = ModelX(
    i: invoiceLineItemId,
    d: 1737590400000,
    e: 0,
    a: 1,
    dxi: 1,
    n: 'Invoice Line Item',
    f: 0,
    ps: const [salesInvoiceId],
    txis: const [],
    mxis: const [], // Non-composed
    c: 'invoice_line_item',
    mtx: 320000,
    fp: 0,
  );

  /// InvoicePayment model (non-composed)
  static final ModelX invoicePayment = ModelX(
    i: invoicePaymentId,
    d: 1737590400000,
    e: 0,
    a: 1,
    dxi: 1,
    n: 'Invoice Payment',
    f: 0,
    ps: const [salesInvoiceId],
    txis: const [],
    mxis: const [], // Non-composed
    c: 'invoice_payment',
    mtx: 320000,
    fp: 0,
  );

  static List<ModelX> get all => [
        salesInvoice,
        invoiceHeader,
        invoiceLineItem,
        invoicePayment,
      ];
}

/// Sales Invoice schemas for testing.
class SalesInvoiceSchemas {
  /// Invoice header schema
  static final JxSchema invoiceHeader = JxSchema([
    JxField(
      i: 1,
      c: 'invoice_id',
      n: 'invoice_id',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 2,
      c: 'invoice_number',
      n: 'invoice_number',
      typeId: 300011,
      typeCode: 'string',
      typeName: 'String',
    ),
    JxField(
      i: 3,
      c: 'invoice_date',
      n: 'invoice_date',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 4,
      c: 'customer_name',
      n: 'customer_name',
      typeId: 300011,
      typeCode: 'string',
      typeName: 'String',
    ),
    JxField(
      i: 5,
      c: 'total_amount',
      n: 'total_amount',
      typeId: 300013,
      typeCode: 'numeric',
      typeName: 'Numeric',
    ),
  ]);

  /// Line item schema
  static final JxSchema lineItem = JxSchema([
    JxField(
      i: 10,
      c: 'line_id',
      n: 'line_id',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 11,
      c: 'product_name',
      n: 'product_name',
      typeId: 300011,
      typeCode: 'string',
      typeName: 'String',
    ),
    JxField(
      i: 12,
      c: 'quantity',
      n: 'quantity',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 13,
      c: 'unit_price',
      n: 'unit_price',
      typeId: 300013,
      typeCode: 'numeric',
      typeName: 'Numeric',
    ),
    JxField(
      i: 14,
      c: 'line_total',
      n: 'line_total',
      typeId: 300013,
      typeCode: 'numeric',
      typeName: 'Numeric',
    ),
  ]);

  /// Payment schema
  static final JxSchema payment = JxSchema([
    JxField(
      i: 20,
      c: 'payment_id',
      n: 'payment_id',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 21,
      c: 'payment_date',
      n: 'payment_date',
      typeId: 300007,
      typeCode: 'int',
      typeName: 'Integer',
    ),
    JxField(
      i: 22,
      c: 'payment_method',
      n: 'payment_method',
      typeId: 300011,
      typeCode: 'string',
      typeName: 'String',
    ),
    JxField(
      i: 23,
      c: 'amount',
      n: 'amount',
      typeId: 300013,
      typeCode: 'numeric',
      typeName: 'Numeric',
    ),
  ]);

  static Map<int, JxSchema> get all => {
        SalesInvoiceModels.salesInvoiceId: invoiceHeader, // Composed model uses header schema for root
        SalesInvoiceModels.invoiceHeaderId: invoiceHeader,
        SalesInvoiceModels.invoiceLineItemId: lineItem,
        SalesInvoiceModels.invoicePaymentId: payment,
      };
}

/// Sample Sales Invoice data.
class SalesInvoiceFixture {
  /// Create a sample sales invoice with all sections.
  ///
  /// Demonstrates:
  /// - invoiceInfo: one section (single header row)
  /// - invoiceDetails: many section (multiple line items)
  /// - payments: many section (multiple payment records)
  static JxComposedRow createSampleInvoice() {
    // Header data (root level)
    final headerSchema = SalesInvoiceSchemas.invoiceHeader;
    final headerCells = [
      1, // invoice_id
      'INV-2025-001', // invoice_number
      1737590400000, // invoice_date (2025-01-23 as epoch ms)
      'Acme Corporation', // customer_name
      '1250.50', // total_amount (exact NUMERIC as string)
    ];

    // Invoice info section (one)
    final infoRow = JxRow(
      schema: headerSchema,
      cells: headerCells,
    );

    // Invoice details section (many)
    final lineItemSchema = SalesInvoiceSchemas.lineItem;
    final lineItems = [
      JxRow(
        schema: lineItemSchema,
        cells: [
          1, // line_id
          'Widget Pro', // product_name
          10, // quantity
          '75.00', // unit_price (exact NUMERIC)
          '750.00', // line_total
        ],
      ),
      JxRow(
        schema: lineItemSchema,
        cells: [
          2,
          'Gadget Deluxe',
          5,
          '100.10', // exact NUMERIC with cents
          '500.50',
        ],
      ),
    ];

    // Payments section (many)
    final paymentSchema = SalesInvoiceSchemas.payment;
    final payments = [
      JxRow(
        schema: paymentSchema,
        cells: [
          1, // payment_id
          1737676800000, // payment_date (2025-01-24)
          'Credit Card', // payment_method
          '1250.50', // amount (exact match to total)
        ],
      ),
    ];

    // Compose the invoice
    return JxComposedRow(
      schema: headerSchema,
      cells: headerCells,
      sections: {
        'invoiceInfo': JxOneSection(row: infoRow),
        'invoiceDetails': JxManySection(rows: lineItems),
        'payments': JxManySection(rows: payments),
      },
    );
  }

  /// Activate sample models and schemas in DbContext.
  static void activate() {
    DbContext.instance.activate(
      models: SalesInvoiceModels.all,
      schemas: SalesInvoiceSchemas.all,
    );
  }
}
