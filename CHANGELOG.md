## 4.0.0

**BREAKING CHANGES: Taxonomy Compliance**

All MetaX models now comply with the ID-PATTERNS.md taxonomy for foreign key references.

**Field Name Changes:**

**Go Models:**
- ColumnX: `T` → `TXI` (json:"t" → json:"txi")
- FieldX: `Ent` → `MXI` (json:"ent" → json:"mxi")
- FieldX: `P` → `CXIS` (json:"p" → json:"cxis")
- ParamX: `Q` → `QXI` (json:"q" → json:"qxi")
- SqlX: `Q` → `QXI` (json:"q" → json:"qxi")
- TypeX: `G` → `TGI` (json:"g" → json:"tgi")

**Dart Models:**
- ColumnX: `t` → `txi` (json:"t" → json:"txi")
- FieldX: `ent` → `mxi` (json:"ent" → json:"mxi")
- FieldX: `p` → `cxis` (json:"p" → json:"cxis")
- ParamX: `q` → `qxi` (json:"q" → json:"qxi")
- ParamX: `dt` → `dtx` (json:"dt" → json:"dtx") - **Bug fix**
- SqlX: `q` → `qxi` (json:"q" → json:"qxi")
- TypeX: `g` → `tgi` (json:"g" → json:"tgi")

**Documentation Updates:**
- ID-PATTERNS.md: Added TypeG (tgi/tgis) and TypeX (tyxi/tyxis) patterns
- ID-PATTERNS.md: Added TypeX catalog reference pattern documentation (ctx, dtx, ftx, ptx, ttx)

**Bug Fixes:**
- ParamX Dart model: Fixed pre-existing inconsistency where field was named `dt` but Go used `dtx`

**Migration Guide:**

All JSON payloads using these models must update field names:
```json
// Before (v3.x)
{"t": 100, "ent": 500, "p": [10, 20], "q": 200, "g": 3}

// After (v4.0.0)
{"txi": 100, "mxi": 500, "cxis": [10, 20], "qxi": 200, "tgi": 3}
```

Database schemas and CRUD functions also need updates to match these patterns.

**Tests:**
- Go: All metax tests pass
- Dart: All 120 tests pass

## 3.3.0

**BREAKING CHANGES:**
- DomainX field names corrected to match AIX database schema and existing documentation
  - Go: `IDS` → `IDXIS` (json:"i_dxis")
  - Go: `CDS` → `CDXIS` (json:"c_dxis")
  - Dart: `ids` → `iDxis` (json:"i_dxis")
  - Dart: `cds` → `cDxis` (json:"c_dxis")

**NEW: Complete 10 Canonical MetaX Types**

JCore now defines all 10 core MetaX types as the source of truth:

1. **DomainX** - Domain hierarchy and scope (cox.domainx) - FIXED
2. **TypeG** - Type group catalog (cox.typeg) - NEW
3. **TypeX** - Type catalog with group-based IDs (cox.typex) - NEW
4. **TableX** - Physical table metadata (mx.tablex)
5. **ColumnX** - Physical column metadata (mx.columnx)
6. **ModelX** - Logical model metadata (mx.modelx)
7. **FieldX** - Logical field metadata (mx.fieldx)
8. **QueryX** - Query operation metadata (mx.queryx)
9. **ParamX** - Query parameter metadata (mx.paramx)
10. **SqlX** - SQL template metadata (mx.sqlx)

**TypeG** (NEW):
- Structure: {i, d, n}
- Organizes types into semantic categories
- Groups have distinct ID ranges

**TypeX** (NEW):
- Structure: {i, d, e, a, n, g, k, c}
- References TypeG via g (group ID)
- k = key within group
- Deterministic ID construction based on group

**Tests:**
- Dart: All 120 tests pass
- Go: All metax tests pass

## 3.2.0

- Add f provenance field to all 6 MetaX models (TableX, ColumnX, ModelX, FieldX, QueryX, ParamX)
- Rename ModelX.p to ModelX.ps (parent model IDs array)
- f Provenance semantics: 0=native, >0=copied, <0=imported
- All tests pass (120 Dart, all Go metax)

## 3.1.2

- Complete removal of legacy 300000-series data type IDs from entire codebase.
- Remove all legacy documentation files containing outdated ID references.
- Update all tests, code examples, and current documentation to use registry IDs (10000-80000 series).
- Fix NUMERIC and TEXT parameterized type encodings in all examples.
- All 112 tests passing with zero analysis issues.

## 3.1.0

- Remove CUID from the data type registry and documentation.

## 3.0.9

- Add the data type registry, SMALLINT validation, and parameterized
  NUMERIC/TEXT IDs.
- Add exact scale-preserving Numeric arithmetic, JSONC number-mode output,
  and the existing value validation behavior.
- Move the Dart package to /dart while retaining the jcore package name and
  public import.
- Gather documentation under /docs and add the requested language folder
  structure, with unimplemented language ports marked as coming soon.
- Expose registry operations through DataTypeRegistry without changing the
  assigned IDs or behavior.
- Keep JUX, JSYNC, and other language implementations planned.

## 2.0.0

- Enforce numeric precision and scale, and signed INT32 and INT64 ranges.
- Convert INT64 values according to JSONC number-format modes and preserve
  those modes when merging data with schemas.
- Document PostgreSQL response handling and the package version policy.

## 1.0.0

- Initial version.
