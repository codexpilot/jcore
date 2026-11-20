# jcore architecture

jcore is a shared, multi-language foundation. Its layers are intended to
depend on the data model below them:

```text
data   →  jux  →  jsync
     ↓
   metax (AIX MetaX models)
```

This repository currently implements **data in Dart** and **metax models in Dart and Go** through
`package:jcore/jcore.dart`. jux, jsync, other language implementations, and a
repository or package split remain planned. The public Dart package name stays
`jcore`.

## Layers

| Layer | Responsibility | Status in this repository |
| --- | --- | --- |
| data | Type IDs, `Numeric`, jsonc, and data validation | Implemented in Dart |
| metax | MetaX metadata models (DomainX, TableX, ModelX, etc.) | Implemented in Dart and Go |
| jux | Portable UI definitions, bindings, and generic Catalog references | Planned |
| jsync | Synchronization contracts, topology, and algorithms | Planned |

jux will build on data values and identifiers. jsync will build on data and
jux contracts. metax models use data types. Transport, rendering, and storage integrations remain outside
the portable contracts until those designs are specified.

## MetaX Taxonomy

JCore is the **source of truth** for AIX MetaX taxonomy. All AIX implementations must follow these definitions:

- **[ID Patterns](../taxonomy/ID-PATTERNS.md)** - Singular/plural ID naming conventions
- **[Type Patterns](../taxonomy/TYPE-PATTERNS.md)** - TypeX reference patterns (dtx, ttx, ctx, etc.)
- **[System Columns](../taxonomy/SYSTEM-COLUMNS.md)** - Standard column definitions
- **[Parent Rules](../taxonomy/PARENT-RULES.md)** - Self-referential p/ps constraints
- **[DomainX Special](../taxonomy/DOMAINX-SPECIAL.md)** - Provenance tracking columns

These rules ensure consistency across database schemas, API contracts, and code implementations.

## Source organization

The Dart package is organized under its language root:

- `dart/pubspec.yaml` keeps the package name `jcore`.
- `dart/lib/jcore.dart` is the package public entry point.
- `dart/lib/src/data/` contains the Dart implementation.
- `dart/test/` contains the Dart package tests.
- `example/` contains Dart examples.
- `docs/` contains shared, language-neutral contracts and plans.

Git consumers select `dart` as the package subdirectory; the package
name and `package:jcore/jcore.dart` import remain stable. When a second language
implementation is ready, give it a language-specific source root and native
tests. Keep data, jux, and jsync modules distinct within each implementation
and preserve their dependency order.

## Data type registry

The leading decimal digit identifies an ordered storage-size class. It is not
always a literal byte count.

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
| JSON | 80000 | |
| JSONB | 80001 | |

Parameterized IDs are:

- NUMERIC(p,s): `60000 + p * 100 + s`, with precision 1–99 and scale 0–p.
- TEXT(n): `70000 + n`, with length 1–9999.

The Dart entry points are `DataType`, `DataTypeRegistry`,
`DataTypeRegistry.encodeNumeric`, `DataTypeRegistry.decodeNumeric`,
`DataTypeRegistry.encodeText`, `DataTypeRegistry.decodeText`, and
`DataTypeRegistry.isValid`.

## Numeric and jsonc

`Numeric` stores a `BigInt` coefficient and decimal scale. Addition and
subtraction align operands to the greater scale; multiplication combines
scales. String formatting retains the result scale. Its explicit
`Numeric.fromString(value, scale)` factory pads shorter fractions and
truncates excess fractional digits to preserve the existing AIX behavior.

jsonc supports numeric-string modes for exact wire values. Supplying a
`Numeric` object causes jsonc to encode a decimal string in those modes and a
JSON number in plain-number modes. Plain-number output may lose decimal
precision in downstream runtimes.
