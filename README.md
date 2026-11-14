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

## Testing

```bash
dart test
dart analyze
```

All tests pass with 100% coverage of the data type system.

## License

Part of the AIX project.
