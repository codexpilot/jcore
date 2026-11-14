# JCore architecture

JCore is a shared, multi-language foundation. Its layers are intended to
depend on the data model below them:

```text
jdata  →  JUX  →  JSYNC
```

This repository currently implements **jdata in Dart** through
`package:jcore/jcore.dart`. JUX, JSYNC, other language implementations, and a
repository or package split remain planned. The public Dart package name stays
`jcore`.

## Layers

| Layer | Responsibility | Status in this repository |
| --- | --- | --- |
| jdata | Type IDs, `Numeric`, JSONC, and data validation | Implemented in Dart |
| JUX | Portable UI definitions, bindings, and generic Catalog references | Planned |
| JSYNC | Synchronization contracts, topology, and algorithms | Planned |

JUX will build on jdata values and identifiers. JSYNC will build on jdata and
JUX contracts. Transport, rendering, and storage integrations remain outside
the portable contracts until those designs are specified.

## Source organization

The Dart package is organized under its language root:

- `dart/pubspec.yaml` keeps the package name `jcore`.
- `dart/lib/jcore.dart` is the package public entry point.
- `dart/lib/src/jdata/` contains the Dart implementation.
- `dart/test/` contains the Dart package tests.
- `example/` contains Dart examples.
- `docs/` contains shared, language-neutral contracts and plans.

Git consumers select `dart` as the package subdirectory; the package
name and `package:jcore/jcore.dart` import remain stable. When a second language
implementation is ready, give it a language-specific source root and native
tests. Keep jdata, JUX, and JSYNC modules distinct within each implementation
and preserve their dependency order.

## Data type registry

The leading decimal digit identifies an ordered storage-size class. It is not
always a literal byte count; the existing AIX catalog uses class 3 for
four-byte values.

| Type | ID | Notes |
| --- | ---: | --- |
| BOOLEAN | 10000 | |
| SMALLINT / INT16 | 20000 | Signed range -32768 through 32767 |
| INT32 | 30000 | |
| INT64 | 40000 | |
| DATETIME | 40001 | |
| TIME | 40002 | |
| UUID | 50000 | |
| NUMERIC | 60000 | Unlimited |
| TEXT | 70000 | Unlimited |
| TEXT0Z | 80000 | |
| JSONB | 80001 | |

Parameterized IDs are:

- NUMERIC(p,s): `60000 + p * 100 + s`, with precision 1–99 and scale 0–p.
- TEXT(n): `70000 + n`, with length 1–9999.

The Dart entry points are `DataType`, `DataTypeRegistry`,
`DataTypeRegistry.encodeNumeric`, `DataTypeRegistry.decodeNumeric`,
`DataTypeRegistry.encodeText`, `DataTypeRegistry.decodeText`, and
`isValidDataType`.

## Numeric and JSONC

`Numeric` stores a `BigInt` coefficient and decimal scale. Addition and
subtraction align operands to the greater scale; multiplication combines
scales. String formatting retains the result scale. Its explicit
`Numeric.fromString(value, scale)` factory pads shorter fractions and
truncates excess fractional digits to preserve the existing AIX behavior.

JSONC supports numeric-string modes for exact wire values. Supplying a
`Numeric` object causes JSONC to encode a decimal string in those modes and a
JSON number in plain-number modes. Plain-number output may lose decimal
precision in downstream runtimes.

## Relationship to the existing Group 3 API

JCore still contains the existing AIX Group 3 API (`JDataType`,
`encodeNumericType`, and related functions). It is separate from the current
catalog.
There is no ID translation or stored-schema migration between the current and
existing catalogs in this work. Consumer adoption and any data migration need
their own design and
must not be inferred from the presence of the data type registry.

See [the registry adoption plan](../plan/data-type-registry-migration.md) for
the deferred consumer work.
