import 'package:jcore/data.dart';
import 'package:jcore/src/fixtures/sales_invoice_fixture.dart';
import 'package:jcore/src/fixtures/in_memory_query_service.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryQueryService queryService;

  setUp(() {
    // Reset context and query service
    DbContext.instance.clear();
    SalesInvoiceFixture.activate();

    queryService = InMemoryQueryService();
    DbContext.instance.setQueryService(queryService);
  });

  group('RecordX basic operations', () {
    test('creates editable record with model ID and record ID', () {
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
      );

      expect(record.modelId, equals(500));
      expect(record.recordId, equals(1));
      expect(record.schemaVersion, equals(1));
      expect(record.isDirty, isFalse);
    });

    test('tracks field edits', () {
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
      );

      record.setField('customer_name', 'New Customer');

      expect(record.isDirty, isTrue);
      expect(record.getField('customer_name'), equals('New Customer'));
    });

    test('exports to JSON with edited fields only', () {
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
      );

      record.setField('customer_name', 'New Customer');
      record.setField('total_amount', '5000.00');

      final json = record.toJson();

      expect(json['i'], equals(1));
      expect(json['v'], equals(1));
      expect(json['customer_name'], equals('New Customer'));
      expect(json['total_amount'], equals('5000.00'));
      expect(json.containsKey('invoice_number'), isFalse);
    });

    test('reset clears all edits', () {
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
      );

      record.setField('customer_name', 'New Customer');
      expect(record.isDirty, isTrue);

      record.reset();

      expect(record.isDirty, isFalse);
      expect(record.toJson().keys.length, equals(2)); // Only i and v
    });
  });

  group('RecordX section operations', () {
    test('tracks section row edits', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
        cachedRow: invoice,
      );

      // Update a line item
      record.setSectionRow('invoiceDetails', 0, {
        'line_id': 1,
        'product_name': 'Updated Widget',
        'quantity': 20,
        'unit_price': '80.00',
        'line_total': '1600.00',
      });

      expect(record.isDirty, isTrue);

      final details = record.getSectionRows('invoiceDetails');
      expect(details[0]['product_name'], equals('Updated Widget'));
      expect(details[0]['quantity'], equals(20));
    });

    test('adds new section row', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
        cachedRow: invoice,
      );

      // Add a new line item
      record.addSectionRow('invoiceDetails', {
        'line_id': 3,
        'product_name': 'New Product',
        'quantity': 7,
        'unit_price': '50.00',
        'line_total': '350.00',
      });

      final details = record.getSectionRows('invoiceDetails');
      expect(details.length, equals(3));
      expect(details[2]['product_name'], equals('New Product'));
    });

    test('removes section row', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
        cachedRow: invoice,
      );

      // Remove second line item
      record.removeSectionRow('invoiceDetails', 1);

      final details = record.getSectionRows('invoiceDetails');
      expect(details.length, equals(1));
      expect(details[0]['product_name'], equals('Widget Pro'));

      // Verify removed IDs tracked in toJson
      final json = record.toJson();
      expect(json['_removed_invoiceDetails'], equals([2]));
    });

    test('remove first row then edit remaining row targets correct row', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
        cachedRow: invoice,
      );

      // Remove first detail (line_id: 1, was at index 0)
      record.removeSectionRow('invoiceDetails', 0);

      // Edit what's now at index 0 (originally line_id: 2, was at index 1)
      record.setSectionRow('invoiceDetails', 0, {
        'line_id': 2,
        'product_name': 'Edited Gadget',
        'quantity': 10,
        'unit_price': '200.00',
        'line_total': '2000.00',
      });

      final json = record.toJson();

      // Should have one row: the edited line_id 2
      expect(json['invoiceDetails'].length, equals(1));
      expect(json['invoiceDetails'][0]['line_id'], equals(2));
      expect(json['invoiceDetails'][0]['product_name'], equals('Edited Gadget'));
      expect(json['invoiceDetails'][0]['quantity'], equals(10));

      // Should explicitly track removed ID
      expect(json['_removed_invoiceDetails'], equals([1]));
    });

    test('replaces entire section', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();
      final record = RecordX(
        modelId: 500,
        recordId: 1,
        schemaVersion: 1,
        cachedRow: invoice,
      );

      // Replace all line items
      record.setSectionRows('invoiceDetails', [
        {
          'line_id': 10,
          'product_name': 'Replacement Item',
          'quantity': 1,
          'unit_price': '1000.00',
          'line_total': '1000.00',
        }
      ]);

      final details = record.getSectionRows('invoiceDetails');
      expect(details.length, equals(1));
      expect(details[0]['product_name'], equals('Replacement Item'));
    });
  });

  group('DbContext integration', () {
    test('fetches and caches invoice record', () async {
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      expect(invoice, isNotNull);
      expect(invoice['invoice_id'], equals(1));
      expect(invoice['customer_name'], equals('Acme Corporation'));

      // Verify composed structure
      expect(invoice, isA<JxComposedRow>());
      final composed = invoice as JxComposedRow;
      expect(composed.sections.keys, containsAll(['invoiceInfo', 'invoiceDetails', 'payments']));
    });

    test('opens record for editing', () async {
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      final editable = DbContext.instance.openForEdit(
        invoice,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      expect(editable.modelId, equals(500));
      expect(editable.recordId, equals(1));
      expect(editable.cachedRow, same(invoice));
      expect(editable.isDirty, isFalse);
    });

    test('edits across sections save in one call', () async {
      // Load invoice
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Open for editing
      final editable = DbContext.instance.openForEdit(
        invoice,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Edit header field
      editable.setField('customer_name', 'Updated Corporation');
      editable.setField('total_amount', '2000.00');

      // Edit line item
      editable.setSectionRow('invoiceDetails', 0, {
        'line_id': 1,
        'product_name': 'Premium Widget',
        'quantity': 15,
        'unit_price': '90.00',
        'line_total': '1350.00',
      });

      // Add new payment
      editable.addSectionRow('payments', {
        'payment_id': 2,
        'payment_date': 1737763200000,
        'payment_method': 'Bank Transfer',
        'amount': '750.00',
      });

      // Save all changes in one call
      final saved = await DbContext.instance.saveChanges(editable);

      // Verify saved changes
      expect(saved['customer_name'], equals('Updated Corporation'));
      expect(saved['total_amount'], equals('2000.00'));

      // Verify section changes
      final savedComposed = saved as JxComposedRow;
      final details = savedComposed.getMany('invoiceDetails');
      expect(details[0]['product_name'], equals('Premium Widget'));
      expect(details[0]['quantity'], equals(15));

      final payments = savedComposed.getMany('payments');
      expect(payments.length, equals(2));
      expect(payments[1]['payment_method'], equals('Bank Transfer'));
    });

    test('failed save leaves cached invoice intact', () async {
      // Load invoice
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      final originalCustomer = invoice['customer_name'];
      final originalAmount = invoice['total_amount'];

      // Open for editing
      final editable = DbContext.instance.openForEdit(
        invoice,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Make edits
      editable.setField('customer_name', 'Failed Customer');
      editable.setField('total_amount', '9999.99');

      // Simulate failure
      queryService.simulateFailure(true);

      // Attempt save (should fail)
      expect(
        () => DbContext.instance.saveChanges(editable),
        throwsException,
      );

      // Verify editable record still has edits (for retry)
      expect(editable.isDirty, isTrue);
      expect(editable.getField('customer_name'), equals('Failed Customer'));

      // Verify cached invoice is unchanged
      expect(invoice['customer_name'], equals(originalCustomer));
      expect(invoice['total_amount'], equals(originalAmount));

      // Verify cache retrieval shows original data
      queryService.simulateFailure(false);
      final reloaded = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );
      expect(reloaded['customer_name'], equals(originalCustomer));
    });

    test('successful save updates cache', () async {
      // Load invoice
      final first = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      expect(first['customer_name'], equals('Acme Corporation'));

      // Open for editing
      final editable = DbContext.instance.openForEdit(
        first,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Edit and save
      editable.setField('customer_name', 'Cache Updated Corp');
      final saved = await DbContext.instance.saveChanges(editable);

      // Verify save returned updated data
      expect(saved['customer_name'], equals('Cache Updated Corp'));

      // Verify backend storage was updated
      final direct = queryService.getInvoiceDirect(1);
      expect(direct, isNotNull);
      expect(direct!['customer_name'], equals('Cache Updated Corp'));

      // Fetch again - should get updated data from backend
      final refetched = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );
      expect(refetched['customer_name'], equals('Cache Updated Corp'));
    });

    test('omitted fields in save mean no change', () async {
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      final originalNumber = invoice['invoice_number'];
      final originalDate = invoice['invoice_date'];

      final editable = DbContext.instance.openForEdit(
        invoice,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Only edit customer name
      editable.setField('customer_name', 'Partial Update Corp');

      final saved = await DbContext.instance.saveChanges(editable);

      // Unchanged fields remain
      expect(saved['invoice_number'], equals(originalNumber));
      expect(saved['invoice_date'], equals(originalDate));
      expect(saved['customer_name'], equals('Partial Update Corp'));
    });

    test('explicit null clears nullable field', () async {
      final invoice = await DbContext.instance.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      final editable = DbContext.instance.openForEdit(
        invoice,
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      );

      // Set field to null
      editable.setField('customer_name', null);

      final saved = await DbContext.instance.saveChanges(editable);

      expect(saved['customer_name'], isNull);
    });
  });

  group('InMemoryQueryService', () {
    test('returns sample invoice on get', () async {
      final result = await queryService.executeQuery(5000, {'i': 1});

      expect(result, isA<Map<String, dynamic>>());
      expect(result['invoice_number'], equals('INV-2025-001'));
      expect(result['customer_name'], equals('Acme Corporation'));
    });

    test('throws on unknown invoice ID', () {
      expect(
        () => queryService.executeQuery(5000, {'i': 999}),
        throwsException,
      );
    });

    test('throws on unknown query ID', () {
      expect(
        () => queryService.executeQuery(9999, {'i': 1}),
        throwsException,
      );
    });

    test('reset restores original fixture', () async {
      // Modify the invoice
      await queryService.executeQuery(5001, {
        'i': 1,
        'customer_name': 'Modified Corp',
      });

      // Verify modification
      var result = await queryService.executeQuery(5000, {'i': 1});
      expect(result['customer_name'], equals('Modified Corp'));

      // Reset
      queryService.reset();

      // Verify original data restored
      result = await queryService.executeQuery(5000, {'i': 1});
      expect(result['customer_name'], equals('Acme Corporation'));
    });
  });
}
