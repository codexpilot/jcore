# jcore Package - AIX Data Type System

A Dart package providing AIX data type catalog constants, encoding/decoding functions, and validation matching the PostgreSQL implementation.

## Features

- **Type-safe enum** for AIX base data types (300000-300009)
- **Encoding functions** for NUMERIC and TEXT types with parameters
- **Decoding functions** to extract precision, scale, and length from type IDs
- **Validation functions** matching PostgreSQL `valid_data_type()` logic
- **PostgreSQL mapping** for DDL type generation

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jcore:
    path: ../jcore
```

## Usage

### Base Types

```dart
import 'package:jcore/jcore.dart';

// Access base types
final intType = JDataType.int32;
print(intType.id); // 300002
print(intType.postgresType); // 'integer'

// Lookup by catalog ID
final type = JDataType.fromId(300002); // JDataType.int32

// Lookup by PostgreSQL type name
final pgType = JDataType.fromPostgresType('integer'); // JDataType.int32
```

### NUMERIC Types

```dart
// Encode NUMERIC types
final unlimitedNumeric = encodeNumericType(); // 300000
final decimal = encodeNumericType(precision: 10, scale: 2); // 310020

// Decode NUMERIC types
final params = decodeNumericType(310020);
print('${params?.precision}, ${params?.scale}'); // '10, 2'

// Validate
print(isValidNumericType(310020)); // true
print(isValidNumericType(310025)); // false - doesn't end in 0
```

### TEXT Types

```dart
// Encode TEXT types
final unlimitedText = encodeTextType(); // 300008
final varchar = encodeTextType(length: 100); // 301008

// Decode TEXT types
final length = decodeTextType(301008); // 100

// Validate
print(isValidTextType(301008)); // true
print(isValidTextType(301005)); // false - doesn't end in 8
```

### PostgreSQL Mapping

```dart
// Get PostgreSQL DDL type
print(getPostgresType(300002)); // 'integer'
print(getPostgresType(310020)); // 'numeric(10,2)'
print(getPostgresType(301008)); // 'text(100)'

// Parse PostgreSQL type name
print(parseDataTypeId('integer')); // 300002
print(parseDataTypeId('numeric')); // 300000
```

### Validation

```dart
// Validate any data type ID
print(isValidDataType(300002)); // true - INT32
print(isValidDataType(310020)); // true - NUMERIC(10,2)
print(isValidDataType(301008)); // true - TEXT(100)
print(isValidDataType(999999)); // false

// Column type constraints
print(isValidColumnDataType(200008, 300002)); // true - status requires INT32
print(isValidColumnDataType(200008, 300003)); // false - status cannot use INT64
```

## Implementation Details

This package exactly matches the PostgreSQL validation functions in `db/validation.sql`:

- `valid_data_type()` → `isValidDataType()`
- `valid_numeric_type()` → `isValidNumericType()`
- `valid_text_type()` → `isValidTextType()`

### Encoding Format

- **NUMERIC**: `300000 + (precision × 1000) + (scale × 10)`
- **TEXT**: `300008 + (length × 10)`

### Constraints

- NUMERIC precision: 1-99
- NUMERIC scale: 0-precision
- TEXT length: 1-9999
- Status (200008) and Version (200010) columns require INT32 (300002)

### Numeric value validation

`JConverter.validateValue` checks values as well as the type ID. INT32 and
INT64 are limited to their signed 32-bit and 64-bit ranges. For exact large
integers and decimals, pass a decimal string or a Dart `BigInt`; `double`
values may already have lost precision before validation. This validation
does not itself convert values for JSON.

For `NUMERIC(p,s)`, validation is strict: the value must fit without rounding
in at most `p - s` integer digits and `s` fractional digits. Insignificant
leading integer zeros and trailing fractional zeros do not count. For example,
`999.990` fits `NUMERIC(5,2)`, but `999.991` and `1000` do not. Unconstrained
NUMERIC has no catalog precision or scale limit. Non-finite values are not
accepted.

These are value-validation rules, separate from the type-ID functions above.
PostgreSQL normally rounds excess fractional digits when assigning to a
`numeric(p,s)` column and checks overflow after rounding. To preserve the
strict rule there, validate the original value before that assignment, so that
rounding does not hide excess fractional digits.

For a finite, unconstrained PostgreSQL `numeric` value `v`, the strict fit rule
for `NUMERIC(p,s)` can be expressed as
`v = trunc(v, s) AND abs(v) < power(10::numeric, p - s)`. Apply the catalog
limits on `p` and `s` separately and reject non-finite values first.

### INT64 and `jnf`

With a schema, `JsonC.fromJson` and `JsonC.parse` read INT64 (type ID 300003)
as Dart `BigInt` in string modes 0, 3, and 5. `JsonC.encode` writes those
values as decimal strings. Modes 1, 2, and 4 use Dart `int` and are **not
web-safe for INT64**; the default is 2.
`JConverter.toMaps` also normalizes directly constructed `JsonC` instances.
`JConverter.fromMaps` accepts an optional `jnf` argument.

Data-only payloads retain their raw values until a schema is supplied through
`JConverter.merge`, `JBase.mergeWithSchema`, or `normalizeInt64(schema: ...)`.
String-mode INT64 numbers outside the JavaScript safe integer range must be
provided as strings or `BigInt`: a number may already have lost precision.
Number modes cannot guarantee web-safe integers beyond that range. This
conversion applies only to INT64; NUMERIC string handling is unchanged.

For PostgreSQL-generated responses forwarded by a pass-through API, see the
[response flow and SQL example](JNF_ENCODING_SPEC.md#postgresql-responses-through-a-pass-through-api).

## Version policy

Versions use `x.y.z`:

- For a new data type or conversion policy, increment `x` and reset `y` and
  `z` to zero.
- Otherwise, when a change introduces a Dart file or a class, increment `y`
  and reset `z` to zero.
- For other changes, increment `z`.

If a release includes changes from more than one category, use the highest
applicable increment.

## Testing

```bash
dart test
dart analyze
```

All tests pass with 100% coverage of the data type system.

## License

Part of the AIX project.
