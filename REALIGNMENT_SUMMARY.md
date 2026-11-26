# JCore Realignment Summary

**Baseline:** commit 142775f4313548e0f0ffc11ae42097e1f970817e  
**Realigned:** commits 279d167, 8805366, 48eb934  
**Date:** 2026-01-20

## Changes Made

### 1. ModelX Type Alignment (Table-First)

**Issue:** Child models used retired type 320000 (Model-claimed-table)  
**Fix:** Updated to use Table-First type catalog

```dart
// BEFORE (Incorrect - retired type)
static final ModelX invoiceHeader = ModelX(
  mtx: 320000, // Model-claimed-table (deprecated)
);

// AFTER (Correct - Table-First)
static final ModelX invoiceHeader = ModelX(
  mtx: 310000, // Single Table Mapped
);
```

**Table-First Type Catalog:**
- `300000`: No Map
- `310000`: Single Table Mapped
- `330000`: Multiple Tables Mapped
- `370000`: Composed Model (one-level composition)
- `390000`: System Mapped

### 2. Field Code vs Name Separation

**Issue:** Wire JSON used field names instead of field codes  
**Fix:** Separated concerns for protocol stability

```dart
// Wire JSON (from API responses, in toMap()) - uses field.c
Map<String, dynamic> toMap() {
  return {
    for (var i = 0; i < schema.fields.length; i++)
      schema.fields[i].c: cells[i]  // Use field CODE
  };
}

// Row access (Dart API) - uses field.n
dynamic operator [](dynamic key) {
  if (key is String) {
    final index = _nameIndex[key];  // Use field NAME
    return cells[index];
  }
}
```

**Rationale:** Field codes remain stable when field names change during internationalization or refactoring.

### 3. IsComposed Logic Realignment

**Issue:** `IsComposed()` checked `len(mxis) > 0` instead of type  
**Fix:** Separated type check from preview check

**Go:**
```go
// Check if model uses composed type (370000)
func (m *ModelX) IsComposed() bool {
    return m.MTX != nil && *m.MTX == 370000
}

// Check if model has children in preview
func (m *ModelX) HasChildren() bool {
    return len(m.MXIS) > 0
}
```

**Dart:**
```dart
// Check if model uses composed type (370000)
bool get isComposed => mtx == 370000;

// Check if model has children in preview
bool get hasChildren => mxis.isNotEmpty;
```

**Rationale:** `mxis` is read-only metadata derived from MapX 951400 rules, not the source of truth.

### 4. Documentation Updates

- Removed all references to retired type 320000
- Updated `docs/reference/composed-model-type.md`
- Added 370000 to ModelTypeCategory enum
- Clarified mxis as read-only preview field

## Public API Examples

### Dart: Composed Row Deserialization

```dart
// Wire JSON response from QueryX (uses field codes)
final response = {
  'invoice_id': 1,              // field.c = 'invoice_id'
  'customer_name': 'Acme Corp',
  'total_amount': '2500.00',
  'invoiceInfo': {              // section key from MapX
    'invoice_number': 'INV-001',
    'invoice_date': 1737590400000,
  },
  'invoiceDetails': [           // section key from MapX
    {
      'line_id': 1,
      'product_name': 'Widget',
      'quantity': 10,
      'unit_price': '100.00',
    },
  ],
  'payments': [],
};

// Deserialize using published section metadata
final row = deserializeComposedRow(
  response,
  model,
  schema,
  childSchemas,
  sections,  // From MapX 951400 rules
);

// Access via field names (Dart API)
print(row['customer_name']);  // 'Acme Corp'
print(row.getNumeric('total_amount')); // '2500.00' (exact)
```

### RecordX: Save Payload Format

```dart
// Edit record
final editable = RecordX(
  modelId: 500,
  recordId: 1,
  schemaVersion: 1,
  _cachedRow: originalRow,
);

editable.setField('customer_name', 'Updated Corp');
editable.removeSectionRow('invoiceDetails', 0);  // line_id: 1
editable.addSectionRow('invoiceDetails', {
  'product_name': 'New Product',
  'quantity': 5,
  'unit_price': '50.00',
});

// Save payload (uses field codes for wire JSON)
final payload = editable.toJson();
// {
//   'i': 1,
//   'v': 1,
//   'customer_name': 'Updated Corp',  // Edited field (omitted fields = no change)
//   'invoiceDetails': [                // Full section after edits
//     {'line_id': 2, 'product_name': 'Item 2', ...},
//     {'product_name': 'New Product', 'quantity': 5, ...},  // New row (no ID)
//   ],
//   '_removed_invoiceDetails': [1],    // Explicit removal (excludes temp IDs)
// }
```

### Go: Model Composition Check

```go
// Check if model uses composed type
if model.IsComposed() {
    // Model has mtx == 370000
    // Composition rules exist in MapX 951400
}

// Check if model has child preview
if model.HasChildren() {
    // mxis array is not empty
    // Children may be composed or non-composed
}
```

## Verification Results

```bash
# Dart
$ cd dart && dart analyze --fatal-infos
Analyzing dart...
No issues found!

$ dart test
00:00 +183: All tests passed!

# Go
$ cd go && go test ./...
ok  	github.com/codexpilot/jcore/go/metax	0.579s

$ go vet ./...
(no output = success)

# Git
$ git diff --check
(no output = no whitespace errors)
```

## Files Changed (Realignment)

```
 dart/lib/src/data/composed_row_decoder.dart        | 11 +++++++---
 dart/lib/src/data/jx_row.dart                      |  8 ++++++--
 dart/lib/src/fixtures/in_memory_query_service.dart |  7 +++++--
 dart/lib/src/fixtures/sales_invoice_fixture.dart   | 12 +++++------
 dart/lib/src/metax/modelx.dart                     | 24 +++++++++++++++-------
 dart/test/db_context_test.dart                     | 18 ++++++++--------
 dart/test/sales_invoice_fixture_test.dart          |  2 +-
 docs/reference/composed-model-type.md              |  8 ++++----
 go/metax/db_context_test.go                        |  2 +-
 go/metax/modelx.go                                 | 13 +++++++-----
 10 files changed, 65 insertions(+), 40 deletions(-)
```

## Preserved from Baseline 142775f

✅ **INT64 Precision:** Flutter Web safe integer handling  
✅ **NUMERIC Exact Values:** String encoding for financial amounts  
✅ **Sparse Updates:** Omitted fields vs explicit null distinction  
✅ **Removal ID Filtering:** Excludes temporary negative IDs  
✅ **Stable Child IDs:** Array-independent row identity

## Integration Guide for MJUX and AIX

### MJUX (Flutter UI Framework)

```dart
import 'package:jcore/data.dart';
import 'package:jcore/fixtures.dart';

// 1. Activate Sales Invoice fixture models
SalesInvoiceFixture.activate();

// 2. Set query service
final queryService = InMemoryQueryService();
DbContext.instance.setQueryService(queryService);

// 3. Fetch and edit records
final record = await DbContext.instance.fetchRecord(
  modelId: 500,
  recordId: 1,
);

final editable = DbContext.instance.openForEdit(record);
editable.setField('customer_name', 'New Name');

final saved = await DbContext.instance.saveChanges(editable);
```

### AIX (APIHub QueryHub Integration)

**Query Request (uses field codes):**
```json
{
  "queryId": 5000,
  "params": {"i": 1}
}
```

**Query Response (uses field codes):**
```json
{
  "invoice_id": 1,
  "customer_name": "Acme Corp",
  "total_amount": "2500.00",
  "invoiceDetails": [
    {"line_id": 1, "product_name": "Widget", "quantity": 10}
  ]
}
```

**Save Request (uses field codes):**
```json
{
  "queryId": 5001,
  "params": {
    "i": 1,
    "v": 1,
    "customer_name": "Updated Corp",
    "invoiceDetails": [
      {"line_id": 2, "product_name": "Item 2"}
    ],
    "_removed_invoiceDetails": [1]
  }
}
```

## Summary

The realignment corrects four critical deviations from baseline 142775f:

1. **Type Catalog**: Retired 320000 → Table-First 310000/370000
2. **Wire Protocol**: Field names → Field codes for stability
3. **Composition Logic**: mxis check → MTX type check
4. **Documentation**: Updated to reflect Table-First architecture

All changes are forward fixes on current history, preserving INT64 precision, exact numeric values, and stable child ID tracking from the baseline.
