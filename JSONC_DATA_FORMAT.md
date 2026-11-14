# JSONC Data Format - Always Array of Arrays

## ✅ Confirmed Behavior

The `data` field in JSONC is **always** an array of arrays `[[]]`, regardless of:
- Number of rows (single or multiple)
- Number of columns (single or multiple)
- Value types (scalar, string, etc.)

## Examples

### Single Scalar Value
```json
{
  "jv": 1,
  "jid": 1001,
  "schema": {"count": 300002},
  "data": [[42]]
}
```
**Not**: `"data": [42]` ❌  
**Not**: `"data": 42` ❌

### Single Row, Multiple Columns
```json
{
  "jv": 1,
  "jid": 1002,
  "schema": {"id": 300003, "name": 300008, "active": 300001},
  "data": [[1, "John", true]]
}
```
**Not**: `"data": [1, "John", true]` ❌

### Single Column, Multiple Rows
```json
{
  "jv": 1,
  "jid": 1003,
  "schema": {"id": 300003},
  "data": [
    [1],
    [2],
    [3]
  ]
}
```

### Multiple Rows, Multiple Columns
```json
{
  "jv": 1,
  "jid": 1004,
  "schema": {"id": 300003, "name": 300008},
  "data": [
    [1, "Alice"],
    [2, "Bob"],
    [3, "Charlie"]
  ]
}
```

### Empty Dataset
```json
{
  "jv": 1,
  "jid": 1005,
  "schema": {"id": 300003, "name": 300008},
  "data": []
}
```
**Not**: `"data": [[]]` for empty ❌

## Why This Design?

✅ **Consistent structure** - Same shape regardless of data size  
✅ **Row-oriented** - Each inner array is one complete row  
✅ **Efficient parsing** - No special cases needed  
✅ **Matches SQL result sets** - Similar to database query results  
✅ **Easy iteration** - `for (final row in data) { ... }`

## Implementation Verification

Our jcore implementation already handles this correctly:

```dart
// Single value - correctly formatted
final jsonc1 = JsonC(
  jv: 1,
  jid: 1001,
  schema: {'count': 300002},
  data: [[42]],  // Array of arrays ✓
);

// Multiple values - correctly formatted
final jsonc2 = JsonC(
  jv: 1,
  jid: 1002,
  schema: {'id': 300003, 'name': 300008},
  data: [
    [1, 'Alice'],
    [2, 'Bob'],
  ],  // Array of arrays ✓
);

// Empty - correctly formatted
final jsonc3 = JsonC(
  jv: 1,
  jid: 1003,
  schema: {'id': 300003},
  data: [],  // Empty array ✓
);

// All are valid
expect(jsonc1.isValid, isTrue);
expect(jsonc2.isValid, isTrue);
expect(jsonc3.isValid, isTrue);
```

## Access Patterns

```dart
// Always iterate as array of arrays
for (final row in jsonc.data!) {
  // row is List<dynamic>
  for (int i = 0; i < row.length; i++) {
    final value = row[i];
    final columnName = jsonc.columnNames[i];
    print('$columnName: $value');
  }
}

// Or convert to maps for easier access
final maps = JsonCConverter.toMaps(jsonc);
for (final map in maps) {
  print(map['name']);  // Access by column name
}
```

## Validation

Our validation correctly enforces this structure:

```dart
// ✅ Valid - array of arrays
JsonC(data: [[1, "test"]]);

// ✅ Valid - empty array
JsonC(data: []);

// ❌ Invalid - would fail JSON parsing
// JsonC(data: [1, "test"]);  // Single array
// JsonC(data: 42);           // Scalar value
```

## Type Definition

```dart
class JsonC {
  /// Data rows as arrays matching schema column order
  /// Always List<List<dynamic>>, never List<dynamic>
  /// 
  /// Examples:
  /// - Single value: [[42]]
  /// - Single row: [[1, "John", true]]
  /// - Multiple rows: [[1, "Alice"], [2, "Bob"]]
  /// - Empty: []
  final List<List<dynamic>>? data;
}
```

---

**Confirmed**: Our implementation is correct! The `data` field is typed as `List<List<dynamic>>?` and all tests verify this structure. ✅
