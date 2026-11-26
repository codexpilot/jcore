# Composed ModelX Implementation Handoff

**Date:** 2025-01-23  
**Repository:** jcore (shared library for AIX and MJUX)  
**Status:** Complete and verified

---

## 1. TypeX Definition

### Group 6 Model Type: Composed Model

| Property | Value |
|----------|-------|
| **TypeX ID** | `370000` |
| **TypeX Code** | `composed` |
| **TypeX Name** | Composed Model |
| **TypeX Group** | 6 (Model Type) |
| **Family** | `37xxxx` |
| **Claim Type** | 7 |
| **TypeX Key** | 70000 |

**Documentation:** [docs/reference/composed-model-type.md](../jcore/docs/reference/composed-model-type.md)

### Composition Rules

- **One-level composition only**: A composed model contains only non-composed child models
- **No recursion**: Child models MUST have `mtx != 370000`
- **System-managed**: `ModelX.mxis` is read-only, populated from active MapX `951400` rules
- **Validation**: Circular references prohibited, section keys must not conflict with field codes

---

## 2. Metadata and Projection Contracts

### ModelX Extensions

**Dart:** `jcore/dart/lib/src/metax/modelx.dart`
```dart
class ModelX {
  // ... existing fields ...
  
  /// System-managed preview: Direct child ModelX IDs from MapX 951400
  /// Sorted, distinct array of child model IDs for composed models
  final List<int> mxis;
  
  /// Whether this model is a composed model (contains child models)
  bool get isComposed => mxis.isNotEmpty;
  
  /// Whether this model uses the composed model type
  bool get isComposedType => mtx == 370000;
}
```

**Go:** `jcore/go/metax/modelx.go`
```go
type ModelX struct {
    // ... existing fields ...
    MXIS []int `json:"mxis,omitempty"` // Direct child ModelX IDs from MapX 951400
}

func (m *ModelX) IsComposed() bool
func (m *ModelX) IsComposedType() bool
```

### Row Projection Contract

**JxRow:** Mixed array access (index and name)
```dart
final row = JxRow(schema: schema, cells: [1, 'John', '123.45']);
row[0]           // Index access: 1
row['name']      // Name access: 'John'
row.getInt('id') // Type-safe: 1
row.getNumeric('amount') // Exact: '123.45'
```

**JxComposedRow:** Structured sections
```dart
final invoice = JxComposedRow(
  schema: headerSchema,
  cells: headerCells,
  sections: {
    'invoiceInfo': JxOneSection(row: headerRow),     // one: single row or null
    'invoiceDetails': JxManySection(rows: items),    // many: list or []
    'payments': JxManySection(rows: payments),
  },
);

invoice['invoice_id']            // Root field access
invoice.getOne('invoiceInfo')    // One section
invoice.getMany('invoiceDetails') // Many section
```

**Value Preservation:**
- INT64: Preserved as `int` or `String` (beyond 2^53-1)
- NUMERIC/DECIMAL: Always preserved as `String` for exact precision

---

## 3. Public Dart API

### DbContext Singleton

**Location:** `jcore/dart/lib/src/data/db_context.dart`

```dart
// Access registries
final models = DbContext.instance.models;
final schemas = DbContext.instance.schemas;

// Look up models
final model = models.byId(123);
final modelByName = models.byName('Customer');  // Exact match, throws on ambiguity
final modelByCode = models.byCode('CUST');

// Activate validated models and schemas together
await DbContext.instance.activate(
  models: [model1, model2],
  schemas: {123: schema1, 124: schema2},
);

// Clear on session/scope change (rejects stale results)
DbContext.instance.clear();
```

**Validation:**
- Duplicate IDs, names (ambiguity), or codes rejected
- Schema required for every model
- Atomic activation (all or nothing)

### Exports

**Package:** `package:jcore/data.dart`
```dart
export 'src/data/db_context.dart';    // DbContext, ModelRegistry, SchemaRegistry
export 'src/data/jx_row.dart';        // JxRow, JxComposedRow, sections
export 'src/data/jx_schema.dart';     // JxSchema, JxField
export 'src/data/query_service.dart'; // QueryService interface
```

---

## 4. Go Implementation

### DBContext and Registries

**Location:** `jcore/go/metax/db_context.go`

```go
ctx := metax.NewDBContext()

// Activate models and schemas
err := ctx.Activate(models, schemas)

// Look up models
model := ctx.Models.ByID(123)
model, err := ctx.Models.ByName("Customer") // Returns error on ambiguity
model := ctx.Models.ByCode("CUST")

// Look up schema
schema := ctx.Schemas.ByModelID(123)

// Clear registries
ctx.Clear()
```

**Row Access:**
```go
row, err := metax.NewRow(schema, cells)

// Access by index or name
val, err := row.Get(0)           // by index
val, err := row.Get("name")      // by name

// Type-safe getters
str, err := row.GetString("name")
num, err := row.GetNumeric("amount") // exact string
i64, err := row.GetInt64("timestamp")

// Composed rows
composed := &metax.ComposedRow{
    Row: row,
    Sections: map[string]metax.Section{
        "info": &metax.OneSection{Row: headerRow},
        "items": &metax.ManySection{Rows: itemRows},
    },
}

infoRow, err := composed.GetOne("info")
itemRows, err := composed.GetMany("items")
```

---

## 5. Sales Invoice Fixture

### Location
- **Dart:** `jcore/dart/lib/src/fixtures/sales_invoice_fixture.dart`
- **Models:** 4 models (1 composed + 3 children)
- **Schemas:** 3 distinct schemas (header, line item, payment)

### Models

```dart
SalesInvoiceModels.salesInvoice    // ID: 500, mtx: 370000 (composed)
SalesInvoiceModels.invoiceHeader   // ID: 501, mtx: 320000 (child)
SalesInvoiceModels.invoiceLineItem // ID: 502, mtx: 320000 (child)
SalesInvoiceModels.invoicePayment  // ID: 503, mtx: 320000 (child)
```

### Sample Data

**Invoice Structure:**
- Root fields: invoice_id, invoice_number, invoice_date, customer_name, total_amount
- Section `invoiceInfo` (one): header data
- Section `invoiceDetails` (many): 2 line items
- Section `payments` (many): 1 payment record

**Exact Numeric Preservation:**
```dart
total_amount: '1250.50'    // Exact NUMERIC as string
unit_price: '75.00'        // Preserved with trailing zeros
line_total: '750.00'       // No floating-point loss
```

### Usage

```dart
// Create sample invoice
final invoice = SalesInvoiceFixture.createSampleInvoice();

// Activate in DbContext
SalesInvoiceFixture.activate();

// Access data
print(invoice['invoice_number']); // 'INV-2025-001'
final items = invoice.getMany('invoiceDetails');
print(items[0]['product_name']); // 'Widget Pro'
```

---

## 6. Verification Results

### Dart Tests

```bash
$ cd jcore/dart && dart test
```

**Result:** ✓ All 163 tests passed

**New test coverage:**
- `test/db_context_test.dart`: DbContext activation, registry lookups, validation
- `test/jx_row_test.dart`: Row access patterns, composed rows, sections
- `test/sales_invoice_fixture_test.dart`: Fixture models, schemas, data integrity

### Dart Analysis

```bash
$ cd jcore/dart && dart analyze --fatal-infos
```

**Result:** ✓ No issues found!

### Go Tests

```bash
$ cd jcore/go && go test ./...
```

**Result:** ✓ All tests passed

```
=== RUN   TestModelRegistry
--- PASS: TestModelRegistry (0.00s)
=== RUN   TestDBContext
--- PASS: TestDBContext (0.00s)
=== RUN   TestRow
--- PASS: TestRow (0.00s)
=== RUN   TestComposedRow
--- PASS: TestComposedRow (0.00s)
=== RUN   TestModelXComposedFields
--- PASS: TestModelXComposedFields (0.00s)
ok  	github.com/codexpilot/jcore/go/metax	0.451s
```

---

## 7. Files Changed

### Documentation
- `docs/reference/composed-model-type.md` (new)

### Dart Implementation
- `dart/lib/src/metax/modelx.dart` (modified: added mxis field and helpers)
- `dart/lib/src/data/db_context.dart` (new: singleton context and registries)
- `dart/lib/src/data/jx_row.dart` (new: row structures with mixed access)
- `dart/lib/src/fixtures/sales_invoice_fixture.dart` (new: sample data)
- `dart/lib/data.dart` (modified: added exports)
- `dart/lib/src/data/numeric_codec.dart` (modified: fixed analyze issues)

### Dart Tests
- `dart/test/db_context_test.dart` (new)
- `dart/test/jx_row_test.dart` (new)
- `dart/test/sales_invoice_fixture_test.dart` (new)

### Go Implementation
- `go/metax/modelx.go` (modified: added MXIS field and helpers)
- `go/metax/db_context.go` (new: context, registries, row structures)
- `go/metax/db_context_test.go` (new)

---

## 8. Integration Points

### Host Application Responsibilities

1. **Load authorized models and schemas** via QueryService
2. **Validate** models and schemas before activation
3. **Activate together** using `DbContext.instance.activate()`
4. **Clear** on session/scope change: `DbContext.instance.clear()`
5. **Reject stale results** by checking active scope before use

### Composed Model Workflow

1. Query service returns validated models with `mxis` populated
2. Application activates models + schemas atomically
3. Runtime creates `JxComposedRow` with sections
4. Each section uses its own ordered, versioned schema
5. Exact INT64 and NUMERIC values preserved throughout

---

## 9. Contract Compliance

✓ **TypeX ID documented:** 370000, code "composed", Group 6, 37xxxx family  
✓ **One-level composition:** Enforced by contract, child models non-composed  
✓ **ModelX.mxis:** System-managed, read-only, sorted distinct child IDs  
✓ **Metadata support:** Dart and Go implementations complete  
✓ **DbContext.instance:** Singleton exported with .models and .schema registries  
✓ **Lookup methods:** byId, byName (exact match, reports ambiguity), byCode  
✓ **Row access:** Mixed array with index and exact-name access  
✓ **SalesInvoice structure:** One row per invoice with ordered sections  
✓ **Section schemas:** Each section uses ordered, versioned schema  
✓ **Value preservation:** Exact INT64 and NUMERIC maintained  
✓ **Authorized loading:** QueryService contract defined  
✓ **Atomic activation:** Models and schemas validated together  
✓ **Scope clearing:** Clear on session/scope change  
✓ **Stale rejection:** Clear registries when scope changes  
✓ **Shared fixture:** Sales Invoice schema and data for fresh installations  
✓ **Verification:** dart test, dart analyze --fatal-infos, go test ./... all pass

---

## 10. Next Steps

**For AIX/MJUX integration:**

1. Update AIX TypeX seed with 370000 entry:
   ```sql
   INSERT INTO cox.typex (i, d, e, a, n, tgi, k, c) VALUES
     (370000, 0, 0, 1, 'Composed Model', 6, 70000, 'composed');
   ```

2. Implement QueryService in host applications:
   - AIXHub: HTTP API returning validated models/schemas
   - Dataset: Local adapter or HTTP client

3. Wire up DbContext activation in application startup
4. Use SalesInvoiceFixture for testing and demonstrations
5. Implement MapX 951400 rules for actual business models

**Repository:** `/Users/Shared/dev/git/jcore`  
**Branch:** main  
**Commit ready:** Yes (pending user approval)
