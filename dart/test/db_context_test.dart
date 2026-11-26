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
        JxField(
          i: 1,
          c: 'id',
          n: 'id',
          typeId: 300007,
          typeName: 'Integer',
        ),
      ]);

      DbContext.instance.activate(
        models: [model1],
        schemas: {1: schema1},
      );

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
        () => DbContext.instance.activate(
          models: [model1],
          schemas: {},
        ),
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
    test('isComposed returns true when mxis is not empty', () {
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

      expect(model.isComposed, isTrue);
    });

    test('isComposed returns false when mxis is empty', () {
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

      expect(model.isComposed, isFalse);
    });

    test('isComposedType returns true for mtx 370000', () {
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

      expect(model.isComposedType, isTrue);
    });

    test('isComposedType returns false for other mtx', () {
      final model = ModelX(
        i: 1,
        d: 0,
        e: 0,
        a: 1,
        dxi: 1,
        n: 'Invoice',
        f: 0,
        c: 'INV',
        mtx: 320000,
      );

      expect(model.isComposedType, isFalse);
    });
  });
}
