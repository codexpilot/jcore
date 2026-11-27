import 'dart:async';

import 'package:jcore/data.dart';
import 'package:jcore/fixtures.dart';
import 'package:test/test.dart';

void main() {
  final schema = JxSchema(const [
    JxField(
      i: 12,
      c: 'number',
      n: 'Invoice Number',
      typeId: 10000,
      typeName: 'String',
    ),
    JxField(
      i: 42,
      c: 'amount',
      n: 'Total Amount',
      typeId: 20000,
      typeName: 'Numeric',
    ),
  ]);

  test(
    'fetches and decodes one raw JX response using the ordered schema',
    () async {
      final service = _TestJxService((queryId, params) async {
        expect(queryId, 70);
        expect(params, {'limit': 2});
        return const JxQueryResponse(
          encoding: 1118,
          body: '{"data":[["INV-001",9007199254740993.01],["INV-002",null]]}',
        );
      });
      final db = DbContext(queryService: service);
      final table = await db.fetchTable(
        queryId: 70,
        schema: schema,
        params: {'limit': 2},
      );

      expect(table.schema, same(schema));
      expect(table.rowCount, 2);
      expect(table.byCode(0, 'number'), 'INV-001');
      expect(table.byId(0, 42), Numeric('9007199254740993.01'));
      expect(table.byName(1, 'Total Amount'), isNull);
      expect(service.calls, 1);
    },
  );

  test('rejects tabular fetches without an ordered result schema', () async {
    final service = _TestJxService(
      (_, _) async => throw StateError('unexpected'),
    );
    final db = DbContext(queryService: service);
    await expectLater(db.fetchTable(queryId: 70), throwsArgumentError);
    expect(service.calls, 0);
  });

  test('uses the active schema for a flat query projection', () async {
    final service = _TestJxService(
      (_, _) async =>
          const JxQueryResponse(encoding: 1018, body: '{"data":[]}'),
    );
    final db = DbContext(queryService: service);
    final model = SalesInvoiceModels.salesInvoice;
    db.activate(
      models: [model],
      schemas: {model.i: schema},
      projections: {
        70: JxResultProjection(modelId: model.i, version: '1', schema: schema),
      },
    );

    final table = await db.fetchTable(queryId: 70);
    expect(table.schema, same(schema));
    expect(table.rowCount, 0);
  });

  test('rejects an active projection with composed sections', () async {
    final service = _TestJxService(
      (_, _) async => throw StateError('unexpected'),
    );
    final db = DbContext(queryService: service);
    SalesInvoiceFixture.activate(db);

    await expectLater(
      db.fetchTable(queryId: SalesInvoiceFixture.fetchQueryId),
      throwsArgumentError,
    );
    expect(service.calls, 0);
  });

  test(
    'rejects a response that arrives after its context is cleared',
    () async {
      final response = Completer<JxQueryResponse>();
      final service = _TestJxService((_, _) => response.future);
      final db = DbContext(queryService: service);
      final pending = db.fetchTable(queryId: 70, schema: schema);
      final rejected = expectLater(pending, throwsStateError);

      db.clear();
      response.complete(
        const JxQueryResponse(encoding: 1018, body: '{"data":[]}'),
      );
      await rejected;
    },
  );

  test('retains the existing record service boundary', () async {
    final db = DbContext(queryService: InMemoryQueryService());
    SalesInvoiceFixture.activate(db);
    await expectLater(
      db.fetchTable(queryId: 70, schema: schema),
      throwsStateError,
    );
    expect(
      (await db.fetchRecord(
        modelId: SalesInvoiceModels.salesInvoiceId,
        recordId: 1,
      )).byCode('invoice_number'),
      'INV-2025-001',
    );
  });
}

class _TestJxService implements JxQueryService {
  _TestJxService(this.respond);

  final Future<JxQueryResponse> Function(int, Map<String, dynamic>) respond;
  int calls = 0;

  @override
  Future<JxQueryResponse> executeJxQuery(
    int queryId,
    Map<String, dynamic> params,
  ) {
    calls++;
    return respond(queryId, params);
  }
}
