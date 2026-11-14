# jcore - AIX Data Type System

## Overview

`jcore` is the shared Dart package providing core AIX data type definitions, validation, and encoding/decoding functionality. It serves as the **single source of truth** for AIX type system across all Flutter projects in the AIX ecosystem.

## Package Status

✅ **Implementation Complete**  
✅ **69/69 Tests Passing**  
✅ **Zero Analysis Issues**  
✅ **PostgreSQL Compatible**

## Repository

- **GitHub**: https://github.com/codexpilot/jcore
- **Local**: `/Users/Shared/dev/git/jcore/`

## Integration with AIX Projects

### Using jcore in Your Projects

Add to your `pubspec.yaml`:

```yaml
dependencies:
  jcore:
    git:
      url: https://github.com/codexpilot/jcore.git
      ref: main  # or specific tag/commit
```

Or for local development:

```yaml
dependencies:
  jcore:
    path: ../jcore  # relative path from your project
```

### Projects That Should Use jcore

1. **contextstudio** - Type dropdowns, metadata validation
2. **dataset** - Runtime field type handling
3. **aixhub** - Metadata validation before DB insertion
4. **apihub** - API schema generation
5. Any other Flutter/Dart project needing AIX types

## What's Included

### Core Components

#### 1. JDataType Enum (10 base types)
```dart
import 'package:jcore/jcore.dart';

JDataType.numeric   // 300000 - Unlimited precision decimal
JDataType.boolean   // 300001 - True/false
JDataType.int32     // 300002 - 4-byte integer
JDataType.int64     // 300003 - 8-byte integer
JDataType.datetime  // 300004 - Epoch milliseconds UTC
JDataType.time      // 300005 - Time storage
JDataType.uuid      // 300006 - UUID
JDataType.text0z    // 300007 - Base-36 CUID
JDataType.text      // 300008 - Unlimited text
JDataType.jsonb     // 300009 - Binary JSON
```

#### 2. Encoding Functions
```dart
// NUMERIC(10,2) → 310020
encodeNumericType(precision: 10, scale: 2);

// TEXT(100) → 301008
encodeTextType(length: 100);
```

#### 3. Decoding Functions
```dart
// 310020 → (precision: 10, scale: 2)
decodeNumericType(310020);

// 301008 → 100
decodeTextType(301008);
```

#### 4. Validation Functions
```dart
isValidDataType(310020);        // true
isValidNumericType(310020);     // true
isValidTextType(301008);        // true
isBaseDataType(300002);         // true
```

#### 5. PostgreSQL Mapping
```dart
getPostgresType(310020);        // 'numeric(10,2)'
parseDataTypeId('integer');     // 300002
```

#### 6. Column Constraints
```dart
getRequiredDataType(200008);    // 300002 (status requires INT32)
isValidColumnDataType(200008, 300002);  // true
```

## Usage Examples

### In contextstudio (UI)

```dart
import 'package:jcore/jcore.dart';

// Type dropdown
class DataTypeDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      items: JDataType.values.map((type) {
        return DropdownMenuItem(
          value: type.id,
          child: Text(type.name),
        );
      }).toList(),
      onChanged: (typeId) {
        // Handle selection
      },
    );
  }
}

// Validation
bool validateColumn(int columnType, int dataType) {
  if (!isValidDataType(dataType)) {
    showError('Invalid data type');
    return false;
  }
  
  if (!isValidColumnDataType(columnType, dataType)) {
    showError('Column type constraint violation');
    return false;
  }
  
  return true;
}
```

### In dataset (Runtime)

```dart
import 'package:jcore/jcore.dart';

class FieldDefinition {
  final int dataTypeId;
  
  String get postgresType => getPostgresType(dataTypeId) ?? 'unknown';
  
  bool validate(dynamic value) {
    // Use type metadata for runtime validation
    if (!isValidDataType(dataTypeId)) {
      return false;
    }
    
    // Additional runtime checks based on decoded params
    if (isValidNumericType(dataTypeId)) {
      final params = decodeNumericType(dataTypeId);
      // Validate numeric value against precision/scale
    }
    
    return true;
  }
}
```

### In aixhub (Backend)

```dart
import 'package:jcore/jcore.dart';

String generateColumnDDL(int dataTypeId, String columnName) {
  final pgType = getPostgresType(dataTypeId);
  if (pgType == null) {
    throw Exception('Invalid data type: $dataTypeId');
  }
  
  return '$columnName $pgType';
}

// Example: generateColumnDDL(310020, 'price')
// Returns: "price numeric(10,2)"
```

## Development Workflow

### Local Development

1. Clone jcore separately:
```bash
cd /Users/Shared/dev/git
git clone https://github.com/codexpilot/jcore.git
```

2. Use path dependency in your project:
```yaml
dependencies:
  jcore:
    path: ../jcore
```

3. Make changes to jcore, test, then commit

### Publishing Changes

```bash
cd /Users/Shared/dev/git/jcore

# Run tests
dart test

# Run analysis
dart analyze

# Commit changes
git add .
git commit -m "feat: add new feature"
git push origin main

# Tag release (optional)
git tag v1.0.0
git push origin v1.0.0
```

### Using in Production

Update your projects to specific version:
```yaml
dependencies:
  jcore:
    git:
      url: https://github.com/codexpilot/jcore.git
      ref: v1.0.0  # Use tagged version
```

## File Structure

```
jcore/
├── lib/
│   ├── jcore.dart                      # Public API exports
│   └── src/
│       ├── j_data_type.dart            # Base type enum (300000-300009)
│       ├── data_type_validation.dart   # PostgreSQL-compatible validation
│       ├── data_type_encoding.dart     # NUMERIC/TEXT encoding
│       ├── data_type_decoding.dart     # Type ID decoding
│       ├── data_type_mapping.dart      # PostgreSQL mapping
│       └── jcore_base.dart             # Base utilities
├── test/
│   ├── j_data_type_test.dart           # 5 tests
│   ├── data_type_validation_test.dart  # 18 tests
│   ├── data_type_encoding_test.dart    # 11 tests
│   ├── data_type_decoding_test.dart    # 8 tests
│   └── data_type_mapping_test.dart     # 13 tests
├── example/
│   └── jcore_example.dart
├── README.md
├── CHANGELOG.md
└── pubspec.yaml
```

## Technical Details

### Type ID Encoding

- **NUMERIC**: `300000 + (precision × 1000) + (scale × 10)`
  - Example: NUMERIC(10,2) = 300000 + 10000 + 20 = 310020
  
- **TEXT**: `300008 + (length × 10)`
  - Example: TEXT(100) = 300008 + 1000 = 301008

### Constraints

- NUMERIC precision: 1-99 (total digits)
- NUMERIC scale: 0-precision (digits after decimal)
- TEXT length: 1-9999 characters
- Status column (200008) requires INT32 (300002)
- Version column (200010) requires INT32 (300002)

### PostgreSQL Compatibility

Matches `db/validation.sql` exactly:
- Lines 183-203: `valid_numeric_type()` → `isValidNumericType()`
- Lines 205-215: `valid_text_type()` → `isValidTextType()`
- Lines 217-223: `valid_data_type()` → `isValidDataType()`

## Important Notes

### What jcore Does

✅ Defines type metadata (catalog IDs, constraints)  
✅ Validates type definitions  
✅ Encodes/decodes type parameters  
✅ Maps to PostgreSQL DDL types

### What jcore Does NOT Do

❌ Handle actual numeric values (use Decimal package)  
❌ Database operations (use postgres package)  
❌ ORM functionality (separate layer)  
❌ UI widgets (implement in each app)

## Testing

```bash
cd /Users/Shared/dev/git/jcore

# Run all tests
dart test

# Run specific test file
dart test test/data_type_validation_test.dart

# Run with coverage
dart test --coverage

# Analysis
dart analyze
```

All 69 tests should pass with zero issues.

## Support

For questions or issues:
1. Check this documentation
2. Review test files for usage examples
3. Consult `db/validation.sql` for PostgreSQL reference
4. Open issue on GitHub repository

## Version History

- **v1.0.0** (2024-11-14) - Initial release with complete AIX data type system

---

**Maintained by**: AIX Development Team  
**Repository**: https://github.com/codexpilot/jcore  
**License**: Part of AIX project
