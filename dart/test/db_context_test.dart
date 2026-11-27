import 'dart:async';

import 'package:jcore/data.dart';
import 'package:jcore/metax.dart';
import 'package:test/test.dart';

void main() {
  group('DbContext', () {
    setUp(() {
      DbContext.instance.clear();
    });

    test('activate validates and activates models and schemas', () {
      final model1 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );

      final schema1 = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(models: [model1], schemas: {1: schema1});

      expect(DbContext.instance.models.byId(1), equals(model1));
      expect(DbContext.instance.schemas.byModelId(1), equals(schema1));
    });

    test('activate rejects duplicate model IDs', () {
      final model1 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );
      final model2 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Order',
        f: 0,
        c: 'ORDER',
      );

      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      expect(
        () => DbContext.instance.activate(
          models: [model1, model2],
          schemas: {1: schema},
        ),
        throwsArgumentError,
      );
    });

    test('activate rejects duplicate model codes', () {
      final model1 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );
      final model2 = ModelX(
        i: 2,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Order',
        f: 0,
        c: 'CUST',
      );

      final schema1 = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);
      final schema2 = JxSchema([
        JxField(i: 2, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      expect(
        () => DbContext.instance.activate(
          models: [model1, model2],
          schemas: {1: schema1, 2: schema2},
        ),
        throwsArgumentError,
      );
    });

    test('activate rejects missing schemas', () {
      final model1 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );

      expect(
        () => DbContext.instance.activate(models: [model1], schemas: {}),
        throwsArgumentError,
      );
    });

    test('clear removes all registries', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(models: [model], schemas: {1: schema});
      DbContext.instance.clear();

      expect(DbContext.instance.models.byId(1), isNull);
      expect(DbContext.instance.schemas.byModelId(1), isNull);
    });
  });

  group('Scoped record operations', () {
    test('two contexts isolate rows, drafts, and services', () async {
      final firstService = _TestService((_, _) async => {'cost': '1.00'});
      final secondService = _TestService((_, _) async => {'cost': '2.00'});
      final first = _activateContext(firstService);
      final second = _activateContext(secondService);

      final row = await first.fetchRecord(modelId: 1, recordId: 51);
      final draft = first.openForEdit(row, modelId: 1);
      expect(draft.recordId, 51);
      expect(() => second.openForEdit(row, modelId: 1), throwsStateError);
      await expectLater(second.saveChanges(draft), throwsStateError);
      expect(secondService.calls, 0);
      expect(
        (await second.fetchRecord(modelId: 1, recordId: 51)).byCode('cost'),
        '2.00',
      );
    });

    test('rejects a response that completes after scope is cleared', () async {
      final pending = Completer<Object?>();
      final context = _activateContext(_TestService((_, _) => pending.future));
      final fetch = context.fetchRecord(modelId: 1, recordId: 51);
      final rejected = expectLater(fetch, throwsStateError);
      context.clear();
      context.setQueryService(_TestService((_, _) async => {'cost': '2.00'}));
      _activateMetadata(context);
      pending.complete({'cost': '1.00'});
      await rejected;
      expect(
        (await context.fetchRecord(modelId: 1, recordId: 51)).byCode('cost'),
        '2.00',
      );
    });

    test('rejects a save result after query service changes', () async {
      final pending = Completer<Object?>();
      final context = _activateContext(
        _TestService((queryId, _) {
          if (queryId == 5000) return Future.value({'cost': '1.00'});
          return pending.future;
        }),
      );
      final row = await context.fetchRecord(modelId: 1, recordId: 51);
      final draft = context.openForEdit(row, modelId: 1);
      final rejected = expectLater(
        context.saveChanges(draft),
        throwsStateError,
      );
      final replacement = _TestService((_, _) async => {'cost': '2.00'});
      context.setQueryService(replacement);
      pending.complete({'cost': '1.00'});
      await rejected;
      await expectLater(context.saveChanges(draft), throwsStateError);
      expect(replacement.calls, 0);
    });

    test('decodes by wire code and saves the loaded record version', () async {
      final context = _activateContext(
        _TestService((queryId, params) async {
          if (queryId == 5000) return {'cost': '9007199254740993.01', 'v': 8};
          expect(params, {'i': 51, 'v': 8, 'cost': null});
          return {'cost': null, 'v': 9};
        }),
      );

      final row = await context.fetchRecord(modelId: 1, recordId: 51);
      expect(row.byName('Total Cost'), '9007199254740993.01');
      expect(
        () => context.openForEdit(row, modelId: 1, recordId: 52),
        throwsArgumentError,
      );
      final draft = context.openForEdit(row, modelId: 1);
      draft.setField('Total Cost', null);
      final saved = await context.saveChanges(draft);
      expect(saved.byCode('cost'), isNull);
      expect(context.openForEdit(saved, modelId: 1).recordVersion, 9);
    });

    test(
      'rejects standalone drafts that lose the loaded ID or version',
      () async {
        final service = _TestService((_, _) async => {'cost': '1.00', 'v': 8});
        final context = _activateContext(service);
        final row = await context.fetchRecord(modelId: 1, recordId: 51);

        await expectLater(
          context.saveChanges(
            RecordX(
              modelId: 1,
              schemaVersion: 1,
              recordVersion: 8,
              cachedRow: row,
            ),
          ),
          throwsArgumentError,
        );
        await expectLater(
          context.saveChanges(
            RecordX(
              modelId: 1,
              recordId: 51,
              schemaVersion: 1,
              recordVersion: 1,
              cachedRow: row,
            ),
          ),
          throwsArgumentError,
        );
        expect(service.calls, 1);
      },
    );

    test('selects separate result projections for the same model', () async {
      final service = _TestService(
        (queryId, _) async =>
            queryId == 1 ? {'cost': '1.00'} : {'name': 'Order'},
      );
      final context = DbContext(queryService: service);
      _activateMetadata(
        context,
        projections: {
          1: JxResultProjection(modelId: 1, version: 'v1', schema: _costSchema),
          2: JxResultProjection(
            modelId: 1,
            version: 'v2',
            schema: JxSchema(const [
              JxField(
                i: 2,
                c: 'name',
                n: 'Order Name',
                typeId: 300011,
                typeName: 'Text',
              ),
            ]),
          ),
        },
      );

      final cost = await context.fetchRecord(
        modelId: 1,
        recordId: 51,
        queryId: 1,
      );
      final name = await context.fetchRecord(
        modelId: 1,
        recordId: 51,
        queryId: 2,
      );
      expect(cost.byCode('cost'), '1.00');
      expect(name.byCode('cost'), isNull);
      expect(name.byName('Order Name'), 'Order');
    });

    test('binds a new draft and reads its server-assigned identity', () async {
      final service = _TestService((_, params) async {
        expect(params, {'i': 0, 'cost': '3.00'});
        return {'i': 99, 'cost': '3.00', 'v': 1};
      });
      final context = _activateContext(service);
      final staleDraft = context.openForCreate(modelId: 1);
      _activateMetadata(context);
      await expectLater(context.saveChanges(staleDraft), throwsStateError);
      expect(service.calls, 0);

      final draft = context.openForCreate(modelId: 1)..setField('cost', '3.00');
      final row = await context.saveChanges(draft);
      final update = context.openForEdit(row, modelId: 1);
      expect(update.recordId, 99);
      expect(update.recordVersion, 1);
    });
  });

  group('ModelRegistry', () {
    test('byId returns model by ID', () {
      final model = ModelX(
        i: 123,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Test',
        f: 0,
        c: 'TEST',
      );
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(models: [model], schemas: {123: schema});

      expect(DbContext.instance.models.byId(123), equals(model));
      expect(DbContext.instance.models.byId(999), isNull);
    });

    test('byName returns model by name', () {
      final model = ModelX(
        i: 123,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(models: [model], schemas: {123: schema});

      expect(DbContext.instance.models.byName('Customer'), equals(model));
      expect(DbContext.instance.models.byName('Unknown'), isNull);
    });

    test('byName throws on ambiguous names', () {
      final model1 = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST1',
      );
      final model2 = ModelX(
        i: 2,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST2',
      );
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(
        models: [model1, model2],
        schemas: {1: schema, 2: schema},
      );

      expect(
        () => DbContext.instance.models.byName('Customer'),
        throwsArgumentError,
      );
    });

    test('byCode returns model by code', () {
      final model = ModelX(
        i: 123,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Customer',
        f: 0,
        c: 'CUST',
      );
      final schema = JxSchema([
        JxField(i: 1, c: 'id', n: 'id', typeId: 300007, typeName: 'Integer'),
      ]);

      DbContext.instance.activate(models: [model], schemas: {123: schema});

      expect(DbContext.instance.models.byCode('CUST'), equals(model));
      expect(DbContext.instance.models.byCode('UNKNOWN'), isNull);
    });
  });

  group('ModelX composition', () {
    test('hasChildren returns true when mxis is not empty', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Invoice',
        f: 0,
        c: 'INV',
        mxis: [10, 20, 30],
      );

      expect(model.hasChildren, isTrue);
    });

    test('hasChildren returns false when mxis is empty', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Invoice',
        f: 0,
        c: 'INV',
      );

      expect(model.hasChildren, isFalse);
    });

    test('isComposed returns true for mtx 370000', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Invoice',
        f: 0,
        c: 'INV',
        mtx: 370000,
      );

      expect(model.isComposed, isTrue);
    });

    test('isComposed returns false for other mtx', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Invoice',
        f: 0,
        c: 'INV',
        mtx: 310000, // Single Table Mapped (non-composed)
      );

      expect(model.isComposed, isFalse);
    });
  });
}

final _costSchema = JxSchema(const [
  JxField(
    i: 1,
    c: 'cost',
    n: 'Total Cost',
    typeId: 300013,
    typeName: 'Numeric',
  ),
]);

DbContext _activateContext(QueryService service) =>
    DbContext(queryService: service)
      ..activate(models: [_testModel], schemas: {1: _costSchema});

void _activateMetadata(
  DbContext context, {
  Map<int, JxResultProjection> projections = const {},
}) {
  context.activate(
    models: [_testModel],
    schemas: {1: _costSchema},
    projections: projections,
  );
}

final _testModel = ModelX(
  i: 1,
  d: 0,
  e: 0,
  a: 1,
  dxi: 1,
  n: 'Order',
  f: 0,
  c: 'order',
);

class _TestService implements QueryService {
  _TestService(this.respond);

  final Future<Object?> Function(int, Map<String, dynamic>) respond;
  int calls = 0;

  @override
  Future<Object?> executeQuery(int queryId, Map<String, dynamic> params) {
    calls++;
    return respond(queryId, params);
  }
}
