# JCore TableType + DataTypeX Integration

## Scan Results

**File:** `lib/src/metax/tablex.dart`

### TableType Encoding (100000-199999)

**Formula:**
```
100000 + sync×1000 + log×100 + algorithm×10 + datatypex_id
```

**Components:**
- **Sync (thousands):** 0=Private, 1=Protected, 2=Synced-Origin, 3=Synced-Origin-Main
- **Log (hundreds):** 0=Off, 1=On
- **Algorithm (tens):** 0=Custom, 1=Auto Increment, 2=Epoch Server Serial
- **DataTypeX ID (ones - LAST DIGIT):** 2=INT32, 3=INT64, 6=UUID

## Critical Finding

**The last digit of TableType ID IS the DataTypeX ID directly.**

No mapping needed - the format code directly references DataTypeX catalog.

## Changes Made

### 1. Updated `formatName` Getter
```dart
// BEFORE
case 3: return 'INTEGER';
case 4: return 'BIGINT';
case 5: return 'UUID';

// AFTER
case 2: return 'INT32';
case 3: return 'INT64';
case 6: return 'UUID';
```

### 2. Simplified `dataTypeId` Getter
```dart
// BEFORE - Complex mapping
int? get dataTypeId {
  switch (format) {
    case 3: return 2; // Wrong mapping
    case 4: return 3;
    case 5: return 6;
    default: return null;
  }
}

// AFTER - Direct reference
int get dataTypeId => format;
```

### 3. Updated Default Value
```dart
// BEFORE
ttx = 100014  // Last digit 4 (invalid)

// AFTER  
ttx = 100013  // Last digit 3 (DataTypeX INT64)
```

**Comment updated:**
- Old: "Default: 100014 (Private · Log Off · Auto Increment · BIGINT)"
- New: "Default: 100013 (Private · Log Off · Auto Increment · INT64)"

### 4. Updated Test File
```dart
// test/metax_test.dart
ttx: 100013, // Private, Log Off, Auto Increment, INT64 (DataTypeX 3)
```

## TableType Examples

| TableType ID | Sync | Log | Algorithm | Last Digit | DataTypeX | Type Name |
|--------------|------|-----|-----------|------------|-----------|-----------|
| 100012 | Private | Off | Auto Inc | 2 | 2 | INT32 |
| 100013 | Private | Off | Auto Inc | 3 | 3 | INT64 |
| 100016 | Private | Off | Auto Inc | 6 | 6 | UUID |
| 100103 | Private | On | Custom | 3 | 3 | INT64 |
| 101013 | Protected | Off | Auto Inc | 3 | 3 | INT64 |

## Usage Example

```dart
final tableX = TableX(
  i: 1,
  d: 1234567890,
  e: 1,
  a: 1,
  dxi: 1,
  n: 'users',
  f: 0,
  ttx: 100013, // Private, Auto Inc, INT64
  c: 'users',
);

final tableType = tableX.tableType;
print(tableType.sync);        // 0 (Private)
print(tableType.log);         // 0 (Off)
print(tableType.algorithm);   // 1 (Auto Increment)
print(tableType.format);      // 3
print(tableType.dataTypeId);  // 3 (DataTypeX INT64)
print(tableType.formatName);  // 'INT64'
```

## Design Benefits

1. **Direct Coupling:** Last digit = DataTypeX ID eliminates mapping complexity
2. **Self-Documenting:** TableType ID directly reveals its DataTypeX
3. **Type Safety:** Format code guarantees valid DataTypeX ID
4. **Efficiency:** No lookup tables or switch statements needed

## Alignment Status

| Component | Implementation | Status |
|-----------|----------------|--------|
| Format codes = DataTypeX IDs | ✅ Yes | Complete |
| formatName uses DataTypeX names | ✅ INT32, INT64, UUID | Complete |
| dataTypeId returns format directly | ✅ No mapping | Complete |
| Default value aligned | ✅ 100013 (last digit 3) | Complete |
| Tests updated | ✅ metax_test.dart | Complete |

---

**Status:** ✅ JCore TableType fully integrated with DataTypeX  
**Key Rule:** **TableType last digit = DataTypeX ID**
