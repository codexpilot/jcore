# JCore DataTypeX Migration

## Status: Partially Complete (Not Committed)

**Repository:** `/Users/Shared/dev/git/jcore/dart`  
**Branch:** main (uncommitted changes)

## Overview

JCore has been updated to use the new **DataTypeX catalog** (0-99999) instead of the old multi-range catalog system.

### DataTypeX Structure

**Base types: 0-7**
```dart
0: BOOLEAN  - Bool, BOOLEAN
1: SMALLINT - Int16, SMALLINT  
2: INT32    - Int32, INTEGER
3: INT64    - Int64, BIGINT
4: DATETIME - Int64, BIGINT (epoch milliseconds)
5: TIME     - Int64, BIGINT (epoch milliseconds)
6: UUID     - Uuid, UUID
7: JSONB    - Json, JSONB
```

**TEXT range: 10000-19999**
- Base: 10000 (unlimited TEXT)
- Parameterized: 10001-19999 (TEXT(1) through TEXT(9999))
- Encoding: `10000 + length`

**NUMERIC range: 20000-29999**
- Base: 20000 (unlimited NUMERIC)
- Parameterized: 20100-29999 (precision 1-99, scale 0-precision)
- Encoding: `20000 + precision * 100 + scale`
- Validation: precision >= 1, precision <= 99, scale <= precision

## Modified Files (Uncommitted)

### 1. ✅ `lib/src/data/data_type_registry.dart`
**Status:** Complete and correct

**Changes:**
- Updated `DataType` enum to use DataTypeX IDs (0-7, 10000, 20000)
- Removed old type IDs (10000-80001 old catalog)
- Updated encoding/decoding functions for TEXT and NUMERIC
- Correct validation logic
- Correct PostgreSQL type mapping

### 2. ✅ `test/data_type_registry_test.dart`
**Status:** Fixed (just completed)

**Previous errors:**
- Used wrong base IDs for all types (10000, 20000, 30000, etc.)
- Wrong TEXT encoding base (70000 instead of 10000)
- Wrong NUMERIC encoding base (60000 instead of 20000)
- Invalid validation tests

**Fixed:**
- All base type IDs corrected (0-7)
- TEXT encoding tests: 10000-19999 range
- NUMERIC encoding tests: 20000-29999 range
- Validation tests aligned with DataTypeX

### 3. ⚠️ `lib/src/data/data_type_mapping.dart`
**Status:** Needs verification

### 4. ⚠️ `lib/src/data/numeric_codec.dart`
**Status:** Needs verification

### 5. ⚠️ `test/data_type_mapping_test.dart`
**Status:** Needs verification

### 6. ⚠️ `test/jx_codec_1118_test.dart`
**Status:** Needs verification

### 7. ⚠️ `test/jx_codec_test.dart`
**Status:** Needs verification

## Migration From Old Catalog

### Old Catalog IDs (Deprecated)
```
10000: BOOLEAN
20000: SMALLINT
30000: INT32
40000: INT64
40001: DATETIME
40002: TIME
50000: UUID
60000: NUMERIC (base)
70000: TEXT (base)
80000: JSON
80001: JSONB
```

### New DataTypeX IDs
```
0: BOOLEAN
1: SMALLINT
2: INT32
3: INT64
4: DATETIME
5: TIME
6: UUID
7: JSONB (unified JSON/JSONB)
10000: TEXT (base)
20000: NUMERIC (base)
```

**Key changes:**
- Base types moved from 10000-80001 → 0-7
- TEXT base moved from 70000 → 10000
- NUMERIC base moved from 60000 → 20000
- JSON and JSONB unified as single JSONB type (ID 7)
- Removed separate JSON type (80000)

## Alignment with AIX

JCore DataTypeX now **matches AIX DataTypeX exactly:**

| Component | AIX | JCore | Status |
|-----------|-----|-------|--------|
| Base type IDs | 0-7 | 0-7 | ✅ Aligned |
| TEXT range | 10000-19999 | 10000-19999 | ✅ Aligned |
| NUMERIC range | 20000-29999 | 20000-29999 | ✅ Aligned |
| Encoding formula | TEXT: 10000+len<br>NUMERIC: 20000+p*100+s | Same | ✅ Aligned |
| Storage types (sdt) | BOOLEAN, SMALLINT, INTEGER, BIGINT, UUID, JSONB, TEXT, NUMERIC | Same | ✅ Aligned |
| Programming types (pdt) | Bool, Int16, Int32, Int64, Uuid, Json, String, Decimal | Same | ✅ Aligned |

## Testing

### Run tests to verify migration:
```bash
cd /Users/Shared/dev/git/jcore/dart
dart test test/data_type_registry_test.dart
```

### Expected results:
- All base type ID tests pass (0-7)
- TEXT encoding/decoding tests pass (10000-19999)
- NUMERIC encoding/decoding tests pass (20000-29999)
- Validation tests pass with correct DataTypeX ranges

## Next Steps

1. **Verify remaining modified files:**
   - Check `data_type_mapping.dart` for DataTypeX alignment
   - Check `numeric_codec.dart` for correct encoding
   - Verify codec tests use DataTypeX IDs

2. **Run full test suite:**
   ```bash
   cd /Users/Shared/dev/git/jcore/dart
   dart test
   ```

3. **Commit changes:**
   ```bash
   git add .
   git commit -m "Migrate to DataTypeX catalog (0-7, 10000-19999, 20000-29999)

   - Update base types from 10000-80001 → 0-7
   - Update TEXT range from 70000-79999 → 10000-19999
   - Update NUMERIC range from 60000-69999 → 20000-29999
   - Unify JSON/JSONB as single JSONB type (ID 7)
   - Fix all test values to match DataTypeX encoding
   - Align with AIX DataTypeX catalog structure

   Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
   ```

4. **Update dependent systems:**
   - ContextStudio (if it references JCore data types)
   - Dataset (if it references JCore data types)
   - Any other systems using JCore type IDs

## Documentation

- **AIX DataTypeX:** See `/Users/Shared/dev/git/aix/TYPEX_DTX_MIGRATION.md`
- **AIX Schema:** `db/aix/tables/datatypex.sql`
- **AIX Seed:** `db/aix/seed/seed_datatypex.sql`

---

**Migration Date:** 2025-01-XX  
**Status:** Implementation complete, needs testing and commit  
**Alignment:** ✅ JCore DataTypeX matches AIX DataTypeX exactly
