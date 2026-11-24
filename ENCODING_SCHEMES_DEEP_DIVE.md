# DataTypeX Encoding Schemes - Deep Dive

## Critical Issues Found and Fixed

### 1. Wrong JSONB ID
- **Wrong:** JSONB = 8
- **Correct:** JSONB = 7
- **Files affected:** data_type_mapping.dart comment

### 2. Wrong ColumnType IDs
- **Wrong:** Status = 200008, Version = 200010
- **Correct:** Version = 200302, Status = 200402
- **Files affected:** data_type_mapping.dart, data_type_mapping_test.dart

### 3. Test Files Using Completely Wrong Catalog
- **data_type_registry_test.dart:** Had old catalog IDs (10000-80001)
- **data_type_mapping_test.dart:** Had old catalog IDs throughout
- **Status:** Both files now fixed with DataTypeX IDs

## Encoding Schemes Explained

### OLD Catalog System (Deprecated)

**FIRST DIGIT = Storage Class Classification**
```
1xxxx: 1-byte values
  10000: BOOLEAN

2xxxx: 2-byte values  
  20000: SMALLINT

3xxxx: 4-byte values
  30000: INT32

4xxxx: 8-byte values
  40000: INT64 (base)
  40001: DATETIME (variant 1 - stored as 8-byte integer)
  40002: TIME (variant 2 - stored as 8-byte integer)

5xxxx: 16-byte values
  50000: UUID

6xxxx: Variable precision decimal
  60000: NUMERIC (base)
  60100-69999: NUMERIC(precision, scale)

7xxxx: Variable length text
  70000: TEXT (base)
  70001-79999: TEXT(1) through TEXT(9999)

8xxxx: Variable JSON
  80000: JSON (base)
  80001: JSONB (variant 1)
```

**LAST DIGIT = Variant Within Storage Class**
- Base type: last digit = 0 (10000, 20000, 30000, etc.)
- Variant 1: last digit = 1 (40001, 80001)
- Variant 2: last digit = 2 (40002)

**Problems with old system:**
- Wasteful ID space (90% unused)
- Complex classification logic
- First digit doesn't scale beyond 9 categories
- Variants limited to 10 per category

### NEW DataTypeX System (Current)

**Direct IDs for Base Types (0-7)**
```
0: BOOLEAN  - Bool, BOOLEAN
1: SMALLINT - Int16, SMALLINT
2: INT32    - Int32, INTEGER
3: INT64    - Int64, BIGINT
4: DATETIME - Int64, BIGINT (epoch ms)
5: TIME     - Int64, BIGINT (epoch ms)
6: UUID     - Uuid, UUID
7: JSONB    - Json, JSONB (unified JSON/JSONB)
```

**Range-Based Encoding for Parameterized Types**
```
TEXT Range: 10000-19999
  10000: Unlimited TEXT
  10001-19999: TEXT(1) through TEXT(9999)
  Formula: 10000 + length

NUMERIC Range: 20000-29999
  20000: Unlimited NUMERIC
  20100-29999: NUMERIC(precision, scale)
  Formula: 20000 + precision * 100 + scale
  Constraints:
    - precision: 1-99
    - scale: 0-precision
    - 20001-20099: INVALID (precision=0)
```

**Benefits:**
- Compact base type IDs (0-7)
- Efficient range encoding
- Clear mathematical formulas
- Scales well (10,000 TEXT variants, 5,050 NUMERIC variants)
- No wasted ID space

### ColumnType XYZ Encoding (200000-299999)

**Formula: 200000 + X×100 + Y×10 + Z**

**Where:**
- **X = Registry (0-9):** Which registry manages this column type
- **Y = Uniqueness (0-5):** Uniqueness constraint level
- **Z = Scheme (0-4):** Column scheme/purpose

**THE LAST DIGIT (Z) IS THE SCHEME!**

**Examples:**
```
200302: Version column
  X=3 (Registry 3)
  Y=0 (Uniqueness 0)
  Z=2 (Scheme 2)

200402: Status column
  X=4 (Registry 4)
  Y=0 (Uniqueness 0)
  Z=2 (Scheme 2)

200011: ID column
  X=0 (Registry 0)
  Y=1 (Uniqueness 1)
  Z=1 (Scheme 1)

200004: Name column
  X=0 (Registry 0)
  Y=0 (Uniqueness 0)
  Z=4 (Scheme 4)
```

**Invalid old IDs found in JCore:**
```
200008: X=0, Y=0, Z=8
  INVALID! Z must be 0-4, not 8

200010: X=0, Y=1, Z=0
  Valid encoding but wrong column (not Status)
```

### TableType SXB Encoding (100000-199999)

**Formula: ttx = 100000 + 100×S + 10×X + B**

**Where:**
- **S = Sync (0-3):** Synchronization policy
- **X = 3×algorithm + (format-3):** ID algorithm and format packed together
- **B = 2×logging + recursion:** Logging and recursion packed

**X Encoding (ID Algorithm and Format):**
- algorithm: 0=Custom/supplied, 1=Auto-increment, 2=Epoch Server Serial
- format: 3=INTEGER, 4=BIGINT, 5=UUID
- X = 3×algorithm + (format-3), range 0-8

**B Encoding (Logging and Recursion):**
- logging: 0=off, 1=on
- recursion: 0=flat, 1=recursive
- B = 2×logging + recursion, range 0-3

**Example:**
```
100040: Private · Auto-increment BIGINT · Flat, log off
  S = 0 (Private)
  algorithm = 1, format = 4 (BIGINT)
  X = 3×1 + (4-3) = 4
  logging = 0, recursion = 0
  B = 2×0 + 0 = 0
  ttx = 100000 + 100×0 + 10×4 + 0 = 100040
```

**Direction Digit Removed:**
The old SDALF encoding included a Direction digit for Model-First vs Table-First authority. The new SXB format removes Direction entirely because **Table-First is now the only supported authority**.

## Migration Summary

### What Changed

**Base Type IDs:**
```
OLD → NEW
10000 → 0  (BOOLEAN)
20000 → 1  (SMALLINT)
30000 → 2  (INT32)
40000 → 3  (INT64)
40001 → 4  (DATETIME)
40002 → 5  (TIME)
50000 → 6  (UUID)
80001 → 7  (JSONB, unified with JSON)
60000 → 20000 (NUMERIC base)
70000 → 10000 (TEXT base)
```

**ColumnType IDs:**
```
OLD → NEW (from seed.sql)
200008 → 200402 (Status)
200010 → 200302 (Version)
```

### Files Fixed

1. ✅ **data_type_registry.dart**
   - Updated documentation to explain DataTypeX structure
   - Removed "first digit" reference

2. ✅ **data_type_mapping.dart**
   - Fixed JSONB ID: 8 → 7
   - Fixed ColumnType IDs: 200008/200010 → 200302/200402

3. ✅ **data_type_registry_test.dart**
   - Fixed all base type IDs (0-7)
   - Fixed TEXT encoding (10000-19999)
   - Fixed NUMERIC encoding (20000-29999)

4. ✅ **data_type_mapping_test.dart**
   - Fixed all base type mappings
   - Fixed ColumnType IDs in tests
   - Fixed TEXT/NUMERIC validation tests

## Key Insights

1. **Last Digit Logic:**
   - OLD catalog: Last digit = variant within storage class
   - ColumnType: Last digit = Scheme (Z in XYZ)
   - TableType SXB: Last digit = B (2×logging + recursion)

2. **NEW system eliminates first-digit classification:**
   - No more "storage class" grouping
   - Direct IDs for base types
   - Range-based for parameterized types

3. **Mathematical encoding is now explicit:**
   - TEXT: Simple addition (10000 + length)
   - NUMERIC: Clear formula (20000 + p×100 + s)
   - ColumnType: XYZ dimensional (X×100 + Y×10 + Z)
   - TableType: SXB packed encoding (100×S + 10×X + B)

## Alignment Verification

| Component | AIX | JCore | Status |
|-----------|-----|-------|--------|
| Base types | 0-7 | 0-7 | ✅ Fixed |
| TEXT range | 10000-19999 | 10000-19999 | ✅ Fixed |
| NUMERIC range | 20000-29999 | 20000-29999 | ✅ Fixed |
| JSONB ID | 7 | 7 | ✅ Fixed |
| Version CT | 200302 | 200302 | ✅ Fixed |
| Status CT | 200402 | 200402 | ✅ Fixed |

---

**Migration Status:** ✅ Complete  
**Encoding Understanding:** ✅ Deep dive complete  
**All files aligned with AIX DataTypeX:** ✅ Yes
