import 'package:test/test.dart';
import 'package:jcore/metax.dart';

void main() {
  group('DomainX', () {
    test('type detection - framework', () {
      final domain = DomainX(
        i: -500,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Framework',
        c: 'framework',
        p: -1,
      );

      expect(domain.type, DomainType.framework);
    });

    test('type detection - template', () {
      final domain = DomainX(
        i: -1001,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Template',
        c: 'template',
        p: -1001,
      );

      expect(domain.type, DomainType.template);
      expect(domain.isRoot, true);
    });

    test('type detection - solution', () {
      final domain = DomainX(
        i: 1,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Solution',
        c: 'solution',
        p: 1,
      );

      expect(domain.type, DomainType.solution);
      expect(domain.isRoot, true);
    });

    test('isRoot check', () {
      final root = DomainX(
        i: -1,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Root',
        c: 'root',
        p: -1, // Self-parent
      );

      final nonRoot = DomainX(
        i: 100,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Child',
        c: 'child',
        p: 1, // Different parent
      );

      expect(root.isRoot, true);
      expect(nonRoot.isRoot, false);
    });

    test('JSON serialization', () {
      final domain = DomainX(
        i: 1,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Test',
        c: 'test',
        p: -1,
        ids: [1, 2, 3],
        cds: [4, 5, 6],
        sc: 3,
        tc: 3,
        ry: -1,
        cc: 3,
      );

      final json = domain.toJson();
      final decoded = DomainX.fromJson(json);

      expect(decoded.i, domain.i);
      expect(decoded.n, domain.n);
      expect(decoded.c, domain.c);
      expect(decoded.type, domain.type);
    });

    test('max calculations', () {
      final domain = DomainX(
        i: 1,
        d: 1700000000000,
        e: 1,
        a: 1,
        n: 'Test',
        c: 'test',
        p: 1,
        sc: 3,
        tc: 2,
        cc: 4,
      );

      expect(domain.maxServers, 999); // 10^3 - 1
      expect(domain.maxTerminals, 99); // 10^2 - 1
      expect(domain.maxSerialPerMs, 9999); // 10^4 - 1
    });
  });

  group('TableX', () {
    test('table type decoding', () {
      final table = TableX(
        i: 1,
        d: 1700000000000,
        e: 1,
        a: 1,
        dxi: 1,
        n: 'Test Table',
        f: 0,
        ttx: 100014, // Private, Log Off, Auto Increment, BIGINT
        c: 'test_table',
      );

      final decoded = table.tableType;
      expect(decoded.sync, 0); // Private
      expect(decoded.log, 0); // Off
      expect(decoded.algorithm, 1); // Auto Increment
      expect(decoded.format, 4); // BIGINT
    });

    test('unique foreign-parent serialization', () {
      final table = TableX(
        i: 1,
        d: 1700000000000,
        e: 1,
        a: 1,
        dxi: 1,
        n: 'Table',
        f: 0,
        c: 'table',
        fp: 100,
      );

      final decoded = TableX.fromJson(table.toJson());
      expect(decoded.fp, 100);
      expect(decoded.toJson()['fp'], 100);
    });
  });
}
