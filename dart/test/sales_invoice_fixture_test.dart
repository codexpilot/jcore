import 'package:jcore/data.dart';
import 'package:jcore/src/fixtures/sales_invoice_fixture.dart';
import 'package:test/test.dart';

void main() {
  group('SalesInvoiceModels', () {
    test('salesInvoice is composed model type', () {
      final model = SalesInvoiceModels.salesInvoice;
      expect(model.mtx, equals(370000));
      expect(model.isComposed, isTrue);
      expect(model.isComposed, isTrue);
      expect(model.mxis.length, equals(3));
    });

    test('child models are non-composed', () {
      expect(SalesInvoiceModels.invoiceHeader.mxis, isEmpty);
      expect(SalesInvoiceModels.invoiceLineItem.mxis, isEmpty);
      expect(SalesInvoiceModels.invoicePayment.mxis, isEmpty);
    });

    test('child models have correct parent', () {
      expect(
        SalesInvoiceModels.invoiceHeader.ps,
        contains(SalesInvoiceModels.salesInvoiceId),
      );
      expect(
        SalesInvoiceModels.invoiceLineItem.ps,
        contains(SalesInvoiceModels.salesInvoiceId),
      );
      expect(
        SalesInvoiceModels.invoicePayment.ps,
        contains(SalesInvoiceModels.salesInvoiceId),
      );
    });
  });

  group('SalesInvoiceFixture', () {
    test('creates sample invoice with all sections', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();

      // Check root fields
      expect(invoice['invoice_id'], equals(1));
      expect(invoice['invoice_number'], equals('INV-2025-001'));
      expect(invoice['customer_name'], equals('Acme Corporation'));
      expect(invoice['total_amount'], equals('1250.50'));

      // Check invoiceInfo section (one)
      final info = invoice.getOne('invoiceInfo');
      expect(info, isNotNull);
      expect(info!['customer_name'], equals('Acme Corporation'));

      // Check invoiceDetails section (many)
      final details = invoice.getMany('invoiceDetails');
      expect(details.length, equals(2));
      expect(details[0]['product_name'], equals('Widget Pro'));
      expect(details[0]['unit_price'], equals('75.00'));
      expect(details[1]['product_name'], equals('Gadget Deluxe'));
      expect(details[1]['unit_price'], equals('100.10'));

      // Check payments section (many)
      final payments = invoice.getMany('payments');
      expect(payments.length, equals(1));
      expect(payments[0]['payment_method'], equals('Credit Card'));
      expect(payments[0]['amount'], equals('1250.50'));
    });

    test('preserves exact numeric values', () {
      final invoice = SalesInvoiceFixture.createSampleInvoice();

      // Total amount should be exact string
      expect(invoice.getNumeric('total_amount'), equals('1250.50'));

      // Line item amounts should be exact strings
      final details = invoice.getMany('invoiceDetails');
      expect(details[0].getNumeric('unit_price'), equals('75.00'));
      expect(details[0].getNumeric('line_total'), equals('750.00'));
      expect(details[1].getNumeric('unit_price'), equals('100.10'));
      expect(details[1].getNumeric('line_total'), equals('500.50'));
    });

    test('activate loads models into DbContext', () {
      DbContext.instance.clear();

      SalesInvoiceFixture.activate();

      // Check models are loaded
      final invoice = DbContext.instance.models.byId(500);
      expect(invoice, isNotNull);
      expect(invoice!.c, equals('sale_invoice'));

      // Check schemas are loaded
      final schema = DbContext.instance.schemas.byModelId(501);
      expect(schema, isNotNull);
      expect(schema!.fields.length, equals(5));
    });
  });
}
