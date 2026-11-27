import 'package:jcore/data.dart';
import 'package:jcore/fixtures.dart';
import 'package:test/test.dart';

void main() {
  final partySchema = JxSchema([
    const JxField(
      i: 1,
      c: 'party_code',
      n: 'Party name',
      typeId: 300011,
      typeName: 'String',
    ),
  ]);
  final amountSchema = JxSchema([
    const JxField(
      i: 2,
      c: 'amount',
      n: 'Amount',
      typeId: 300013,
      typeName: 'Numeric',
    ),
  ]);
  final emptySchema = JxSchema([]);
  const exactAmount = '9007199254740993.01';

  test('decodes wire field codes and retains explicitly null values', () {
    final row = decodeRecord({
      'party_code': null,
      'Party name': 'Ignored display name',
    }, partySchema);
    expect(row['Party name'], isNull);
    expect(row.toMap(), {'party_code': null});
    expect(
      () => decodeRecord({'Party name': 'Missing code'}, partySchema),
      throwsFormatException,
    );
  });

  test('decodes nested sections using a separate schema per occurrence', () {
    final sections = [
      JxResultSection(
        key: 'billing',
        cardinality: JxSectionCardinality.one,
        schema: partySchema,
        identityCode: 'party_code',
        sections: [
          JxResultSection(
            key: 'invoices',
            cardinality: JxSectionCardinality.many,
            schema: amountSchema,
          ),
        ],
      ),
      JxResultSection(
        key: 'shipping',
        cardinality: JxSectionCardinality.one,
        schema: amountSchema,
      ),
    ];
    final projection = JxResultProjection(
      modelId: 20,
      version: 'revision-2',
      schema: emptySchema,
      sections: sections,
    );

    sections.clear();
    expect(projection.sectionIdentityCodes, {'billing': 'party_code'});
    final row = projection.decode({
      'billing': {
        'party_code': 'ACME',
        'invoices': [
          {'amount': exactAmount},
        ],
      },
      'shipping': {'amount': null},
    }) as JxComposedRow;
    final billing = row.getOne('billing') as JxComposedRow;
    expect(billing['Party name'], 'ACME');
    expect(billing.getMany('invoices').single['Amount'], exactAmount);
    expect(row.getOne('shipping')!.toMap(), {'amount': null});
  });

  test('distinguishes null and empty sections from malformed responses', () {
    final sections = [
      JxResultSection(
        key: 'header',
        cardinality: JxSectionCardinality.one,
        schema: partySchema,
      ),
      JxResultSection(
        key: 'items',
        cardinality: JxSectionCardinality.many,
        schema: amountSchema,
      ),
    ];
    final row = decodeRecord(
      {'header': null, 'items': []},
      emptySchema,
      sections: sections,
    ) as JxComposedRow;
    expect(row.getOne('header'), isNull);
    expect(row.getMany('items'), isEmpty);

    for (final malformed in [
      {'items': []},
      {'header': [], 'items': []},
      {'header': null, 'items': null},
      {
        'header': null,
        'items': [false],
      },
    ]) {
      expect(
        () => decodeRecord(malformed, emptySchema, sections: sections),
        throwsFormatException,
      );
    }
  });

  test('rejects section keys that duplicate projected field codes', () {
    expect(
      () => JxResultProjection(
        modelId: 20,
        version: '1',
        schema: partySchema,
        sections: [
          JxResultSection(
            key: 'party_code',
            cardinality: JxSectionCardinality.one,
            schema: emptySchema,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'invoice fixture emits object sections and rejects stale versions',
    () async {
      final service = InMemoryQueryService();
      final fetched = await service.executeQuery(
        SalesInvoiceFixture.fetchQueryId,
        {'i': 1},
      );
      expect(fetched['invoiceInfo'], isA<Map<String, Object?>>());
      final updated = await service.executeQuery(
        SalesInvoiceFixture.saveQueryId,
        {'i': 1, 'v': 1, 'customer_name': 'Updated customer'},
      );
      expect(updated['v'], 2);
      await expectLater(
        service.executeQuery(SalesInvoiceFixture.saveQueryId, {
          'i': 1,
          'v': 1,
          'customer_name': 'Stale edit',
        }),
        throwsStateError,
      );
      final reloaded = await service.executeQuery(
        SalesInvoiceFixture.fetchQueryId,
        {'i': 1},
      );
      expect(reloaded['customer_name'], 'Updated customer');
      expect(reloaded['v'], 2);
    },
  );
}
