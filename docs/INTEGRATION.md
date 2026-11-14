# JCore integration

The Dart package root is dart. The package name stays jcore, so
applications continue to use import 'package:jcore/jcore.dart'.

JData, including the data type registry, Numeric, JSONC, and validation,
is implemented in Dart. JUX, JSYNC, and other language implementations remain
planned.

## Add the Dart package

For a local checkout beside an application:

~~~yaml
dependencies:
  jcore:
    path: ../jcore/dart
~~~

For a Git dependency:

~~~yaml
dependencies:
  jcore:
    git:
      url: https://github.com/codexpilot/jcore.git
      ref: main
      path: dart
~~~

The Git dependency path requires a repository revision at the selected ref
that contains dart/pubspec.yaml.

## Use the data type registry

~~~dart
import 'package:jcore/jcore.dart';

final smallintId = DataType.smallint.id; // 20000
final numericId = DataTypeRegistry.encodeNumeric(precision: 10, scale: 2); // 61002
final textId = DataTypeRegistry.encodeText(length: 100); // 70100

assert(DataTypeRegistry.isValid(smallintId));
assert(DataTypeRegistry.postgresType(numericId) == 'numeric(10,2)');
assert(DataTypeRegistry.postgresType(textId) == 'varchar(100)');
~~~

`DataType` represents the base types in the current catalog. Its first decimal
digit identifies an ordered storage-size class, not always a literal byte
count. Parameterized IDs use 60000 + precision * 100 + scale for NUMERIC and
70000 + length for TEXT. SMALLINT accepts values from -32768 through 32767.

The existing AIX Group 3 APIs remain available separately. JCore does not
translate Group 3 IDs to current catalog IDs or migrate persisted schemas.

## Develop and verify JCore

From the repository root:

~~~bash
cd dart
dart test
dart analyze --fatal-infos
~~~

The full package layout and module status are documented in the
[architecture overview](architecture/README.md). The consumer adoption
plan is in [data-type-registry-migration.md](plan/data-type-registry-migration.md).
