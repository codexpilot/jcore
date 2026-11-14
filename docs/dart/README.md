# jcore for Dart

This package implements the jcore jdata layer in Dart. The repository package
root is dart; its package name remains jcore, and applications
continue to import package:jcore/jcore.dart.

jdata provides the data type registry, exact Numeric values, jsonc,
and data validation. jux, jsync, and implementations in other languages are
planned. They do not have placeholder packages or APIs here.

## Data type registry

The first decimal digit identifies an ordered storage-size class, not
necessarily a literal byte count.

| Type | ID | Notes |
| --- | ---: | --- |
| BOOLEAN | 10000 | |
| SMALLINT / INT16 | 20000 | Signed range: -32768 to 32767 |
| INT32 | 30000 | |
| INT64 | 40000 | |
| DATETIME | 40001 | |
| TIME | 40002 | |
| UUID | 50000 | |
| NUMERIC | 60000 | Unlimited precision and scale |
| TEXT | 70000 | Unlimited length |
| JSON | 80000 | |
| JSONB | 80001 | |

Parameterized IDs:

- NUMERIC(p,s): 60000 + p * 100 + s, where precision is 1–99 and scale is
  0–precision.
- TEXT(n): 70000 + n, where length is 1–9999.

~~~dart
import 'package:jcore/jcore.dart';

final smallint = DataType.fromName('INT16'); // DataType.smallint
final decimalId = DataTypeRegistry.encodeNumeric(precision: 10, scale: 2); // 61002
final titleId = DataTypeRegistry.encodeText(length: 100); // 70100

print(DataTypeRegistry.isValid(decimalId)); // true
print(DataTypeRegistry.postgresType(decimalId)); // numeric(10,2)
~~~

The registry API includes `DataType`, `DataTypeRegistry`, numeric and text ID
encoders and decoders, validity checks, and PostgreSQL type mapping.

## Numeric and jsonc

Numeric stores a BigInt coefficient and decimal scale. It supports exact
addition, subtraction, multiplication, and comparison. Its explicit
Numeric.fromString(value, scale) constructor preserves the requested scale;
it pads shorter fractional parts and truncates excess digits to retain the
existing AIX behavior.

When a Numeric is encoded by jsonc, numeric-string modes emit a decimal
string. Plain-number modes emit a JSON number, which downstream runtimes may
round. Choose a numeric-string mode when the decimal value must remain exact
on the wire.

## Install

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

The Git dependency path is usable once the repository revision containing
this package layout is available at the selected ref.

## Verify

Run from this directory:

~~~bash
dart test
dart analyze --fatal-infos
~~~

See the [architecture overview](../architecture/README.md) for the
planned jdata, jux, and jsync boundaries.
