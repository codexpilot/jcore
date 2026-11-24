# JCore Taxonomy Reference

**Consolidated from:**
- docs/JCORE-TAXONOMY-AUTHORITY.md
- docs/JCORE-ALIGNMENT-SUMMARY.md
- docs/jcore/AIX-METAX-TAXONOMY.md
- docs/COMPLETE-TAXONOMY-SPECIFICATION.md
- changelog/GLOSSARY-TAXONOMY.md

**Consolidation Date:** 2026-01-XX  
**Status:** Active - JCore is Source of Truth

---

## Authority and Scope

### JCore as Source of Truth

**JCore Repository:** https://github.com/codexpilot/jcore  
**Version:** 4.1.0

**Authority Level:** ABSOLUTE

**Rule:** When JCore and AIX documentation conflict, **JCore is authoritative**.

### Authority Hierarchy

1. **JCore** - Authoritative source of truth for taxonomy, types, and naming
2. **AIX Architecture docs** - Must align with JCore specifications
3. **CLAUDE.md** - Project-specific conventions (never overrides JCore)

### JCore vs AIX MetaX Relationship

**JCore:**
- Type: Framework (Java/Go/Dart packages)
- Provides: Data (data types), JMetaX (MetaX contracts), Taxonomy (naming standards)
- Scope: TYPE DEFINITIONS, CONTRACTS, TAXONOMY
- Does NOT have: Physical database tables

**AIX MetaX:**
- Type: Database schema (PostgreSQL `mx` schema)
- Contains: DomainX, TableX, ColumnX, ModelX, FieldX, QueryX physical tables
- Uses: JCore data types for column definitions
- Scope: ACTUAL DATABASE IMPLEMENTATION

**Relationship:**
```
┌─────────────────────────────┐
│ JCore Framework             │
│ - Data (types)              │
│ - JMetaX (contracts)        │
│ - Taxonomy (naming)         │
└─────────┬───────────────────┘
          │ Defines
          ↓
┌─────────────────────────────┐
│ AIX Database (mx schema)    │
│ - DomainX, TableX, etc.     │
│ - Uses JCore types          │
│ - Follows JCore taxonomy    │
└─────────────────────────────┘
```

---

## TypeX Group System

TypeX assigns each catalog group an ID range. The fresh AIX loader seeds groups 0–9 and the MapX operation catalog in group 12.

| Group | ID Range | Catalog | Description |
|---:|---:|---|---|
| 0 | 0–99 | SYX user roles | System user role definitions |
| 1 | 100–199 | DomainX types | Domain categorization |
| 2 | 1000–1999 | AppX platform | Platform combinations |
| 3 | 10000–99999 | JCore data types | Fundamental data types |
| 4 | 100000–199999 | Table types | Table structure and behavior |
| 5 | 200000–299999 | Column types | Column categorization |
| 6 | 300000–399999 | Model types | Model categorization |
| 7 | 400000–499999 | Field types | Field capabilities |
| 8 | 500000–599999 | Query types | Query operations |
| 9 | 600000–699999 | Parameter types | Parameter roles |
| 12 | 900000–999999 | MapX operation types | Rules for constraints, relationships, and bindings |

### Type ID Encoding Formula

**For groups 4 and higher:**
```
i = (tgi - 3) × 100000 + k
```

Where:
- `tgi` = TypeX group ID
- `k` = Type-specific encoding
- `i` = Final TypeX catalog ID

**For groups 0-3:**  
Use catalog ID directly as both `i` and `k`.

---

## MetaX Field Naming (CRITICAL)

### Type Reference Patterns

JCore uses **group-specific patterns** instead of generic `txi` for type references:

| Group | Field Name | Singular | Plural | Description |
|---:|---|---|---|---|
| 3 | Data Type | **dtx** | **dtxs** | Data type reference |
| 4 | Table Type | **ttx** | **ttxs** | Table type reference |
| 5 | Column Type | **ctx** | **ctxs** | Column type reference |
| 6 | Model Type | **mtx** | **mtxs** | Model type reference |
| 7 | Field Type | **ftx** | **ftxs** | Field type reference |
| 8 | Query Type | **qtx** | **qtxs** | Query type reference |
| 9 | Parameter Type | **ptx** | **ptxs** | Parameter type reference |

**IMPORTANT:** Use `ttx`, `mtx`, `qtx`, etc. — NOT `tt`, `mt`, `qt`

### Entity Reference Patterns

| Entity | Singular | Plural | Description |
|---|---|---|---|
| DomainX | **dxi** | **dxis** | Domain ID reference |
| TableX | **txi** | **txis** | Table ID reference |
| ColumnX | **cxi** | **cxis** | Column ID reference |
| ModelX | **mxi** | **mxis** | Model ID reference |
| FieldX | **fxi** | **fxis** | Field ID reference |
| QueryX | **qxi** | **qxis** | Query ID reference |
| ParamX | **pxi** | **pxis** | Parameter ID reference |
| SQLX | **sxi** | **sxis** | SQL ID reference |
| MapX | **mapxi** | **mapxis** | Unified rule ID reference |
| TypeX | **tx** | **txs** | Type ID reference (generic) |

---

## MetaX Table Definitions

### DomainX

```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,              -- Domain ID
    d BIGINT NOT NULL,              -- Last edit timestamp (epoch ms UTC)
    e INT NOT NULL,                 -- Editor user ID
    a SMALLINT NOT NULL,            -- Active status (0=inactive, 1=active)
    n TEXT NOT NULL,                -- Name
    c TEXT NOT NULL UNIQUE,         -- Code (immutable)
    p INT NOT NULL,                 -- Parent domain ID (self-referential)
    
    -- Provenance arrays
    i_dxis INT[] NOT NULL DEFAULT '{}',  -- Imported source domain IDs
    c_dxis INT[] NOT NULL DEFAULT '{}',  -- Copied source domain IDs
    
    CONSTRAINT domainx_root_self_parent CHECK (i NOT BETWEEN -1000 AND -1 OR p = i)
);
```

**Key Fields:**
- `p` - Parent domain (self-referential: root has `p = i`)
- `i_dxis` - Imported from these domain IDs
- `c_dxis` - Copied from these domain IDs

### TableX and ColumnX

TableX owns physical table identity, table type `ttx`, and partition interval `px` where required. ColumnX belongs to a TableX through `txi` and shares its domain. `ctx` identifies the column role and `dtx` the data type. [TableX schema](../../../db/aix/tables/tablex.sql) · [ColumnX schema](../../../db/aix/tables/columnx.sql)

### ModelX and FieldX

ModelX owns logical record identity. `mtx` identifies its authoring type and `ps` lists parent ModelX IDs. FieldX belongs to a same-domain ModelX through `mxi`. `ctx` identifies its column role, `dtx` the data type, and `ftx` its input and output eligibility. `ModelX.txis` and `FieldX.cxis` are read-only linkage previews derived from usable MapX rules. Both are sorted, distinct ID arrays and default to `[]`. [ModelX schema](../../../db/aix/tables/modelx.sql) · [FieldX schema](../../../db/aix/tables/fieldx.sql) · [MapX linkage previews](../reference/mapx-design.md#modelx-linkage-preview)

### MapX

`mpx` identifies a Group 12 rule operation. The operation's scope determines the container types of `x1` and `x2`. A one-container rule stores `x2 = 0`. Operation-specific IDs and settings belong in the `options` object. Scope 7 owns TableX–ModelX associations and column-to-field mappings. [MapX schema](../../../db/aix/tables/mapx.sql) · [MapX specification](../reference/mapx-design.md)

### QueryX

`p` is `0` for a root or the same-domain parent QueryX ID for a child. The registered function name `c` and parent are immutable. `target_kind` is `system`, `table`, or `model`. It must match the Group 8 `qtx`. Model queries can declare the `model_output` role. `mapx_ids` selects dependencies. Published model output is keyed by QueryX ID and data-contract version. [QueryX schema](../../../db/aix/tables/queryx.sql) · [Query system](query-system.md)

### ParamX

`qxi` identifies the owning same-domain QueryX. `c` is unique within that query. `ptx` identifies purpose, `dtx` identifies value type, `direction` records input and output eligibility, and `req` specifies requiredness. `metadata` is a JSON object for defaults and operation-specific constraints. [ParamX schema](../../../db/aix/tables/paramx.sql) · [Parameter types](../reference/parameter-types.md)

---

## System Columns

### Standard System Columns

All MetaX tables include these columns:

| Column | Name | Type | Description |
|---|---|---|---|
| **i** | Identity | INT/BIGINT/UUID | Primary key, record ID |
| **d** | Date | BIGINT | Last edit timestamp (epoch ms UTC) |
| **e** | Editor | INT/BIGINT/UUID | Last editor user ID |
| **a** | Active | SMALLINT | Binary status (0=inactive, 1=active) |
| **n** | Name | TEXT | Display name |
| **c** | Code | TEXT | Immutable identifier |

### Extended System Columns

Additional columns used in specific contexts:

| Column | Name | Type | Description |
|---|---|---|---|
| **p** | Parent | Same as i | Self-referential parent (p=i for root) |
| **f** | Foreign | Varies | Foreign key reference |
| **s** | Status | INT | Business workflow state |
| **v** | Version | INT | Edit count (optimistic concurrency) |
| **o** | Ordinal | INT/BIGINT | Sort order/sequence |
| **m** | Marker | INT/TEXT | Server or terminal identifier |

### MetaX vs Generated Tables

**MetaX tables use:**
- `i`, `d`, `e`, `a`, `n`, `c` (6 core columns)
- NO `s` (status) or `v` (version)

**Generated runtime tables use 7 fixed columns:**
- `i`, `d`, `e`, `a`, `n`, `s`, `v` (7 columns)
- Plus optional: `c`, `f`, `p`, `o`, custom business columns

---

## Data Types (TypeX Group 3)

JCore data types in range 10000-99999:

### Fixed Data Types

| ID | Type | PostgreSQL | Description |
|---:|---|---|---|
| 10000 | BOOLEAN | boolean | Boolean true/false |
| 20000 | SMALLINT | smallint | 16-bit integer |
| 30000 | INT32 | integer | 32-bit integer |
| 40000 | INT64 | bigint | 64-bit integer |
| 40001 | DATETIME | bigint | Epoch milliseconds UTC |
| 40002 | TIME | bigint | Milliseconds since midnight |
| 50000 | UUID | uuid | UUID type |
| 60000 | NUMERIC | numeric | Arbitrary precision decimal |
| 70000 | TEXT | text | Variable-length text |
| 80000 | JSON | json | JSON data |
| 80001 | JSONB | jsonb | Binary JSON data |

### Parameterized Types

**NUMERIC(p,s):**
```
ID = 60000 + (p × 100) + s
Range: 60100–69999
```

Examples:
- NUMERIC(10,2) = 61002
- NUMERIC(15,4) = 61504

**TEXT(n):**
```
ID = 70000 + n
Range: 70001–79999
```

Examples:
- TEXT(50) = 70050
- TEXT(255) = 70255

### NUMERIC Type Implementation

**CRITICAL:** JCore implements `Numeric` as an **exact decimal class**, NOT as `double`.

**Implementation:** `jcore/dart/lib/src/data/numeric.dart`

```dart
/// Exact decimal value with scale-preserving arithmetic.
///
/// Values are stored as a [BigInt] coefficient and a decimal [scale], avoiding
/// binary floating-point arithmetic. Parsing and arithmetic preserve trailing
/// fractional zeros. Explicit conversion through [toNum] may round values.
final class Numeric implements Comparable<Numeric>
```

**Key Features:**
- BigInt-based coefficient with decimal scale
- Exact arithmetic (no floating-point rounding errors)
- Scale preservation (10.00 ≠ 10.0 ≠ 10)
- Supports NUMERIC(p,s) precision and scale
- Designed for financial/medical/ERP exact decimal requirements

**Serialization:**
- JSON: String representation (preserves exact value)
- Example: `{"price": "19.99"}` not `{"price": 19.99}`

---

## Query Types (TypeX Group 8)

Query types define operation family and direction.

| ID | k | Code | Family | Direction | Description |
|---:|---:|---|---|---|---|
| 500000 | 0 | system_get | System | Get | System metadata read |
| 500001 | 1 | system_set | System | Set | System metadata write |
| 510000 | 10000 | table_get | Table | Get | Direct table read |
| 510001 | 10001 | table_set | Table | Set | Direct table write |
| 520000 | 20000 | model_get | Model | Get | Model-based read |
| 520001 | 20001 | model_set | Model | Set | Model-based write |

**Encoding Formula:**
```
qtx = 500000 + (family × 10000) + direction
```

Where:
- Family: 0=System, 1=Table, 2=Model
- Direction: 0=Get, 1=Set

**IMPORTANT:** Use "Model" terminology, NOT "Entity"

---

## Model Types (TypeX Group 6)

Model types in range 300000-399999:

### Table-First Authority (Current)

**Table-First is the only supported authority for sealed TableX ↔ ModelX mappings.**

| ID | Name | Description |
|---:|---|---|
| 300000 | No Map | The model has no usable direct table link |
| 310000 | Single Table Mapped | The model links directly to one distinct table |
| 330000 | Multiple Tables Mapped | The model links directly to two or more distinct tables |
| 390000 | System Mapped | System-managed mapping |

The effective mapping type is derived from distinct, active, usable direct TableX links in MapX. TableX supplies the physical schema contract and ModelX follows that contract once sealed.

### Retired Types

The Model-First workflow has been retired. The following types are no longer supported:

- **320000:** Model-claimed-table (deprecated)
- **340000:** Model-claimed-tables (deprecated)

---

## Parent references

| Record | Parent field | Root convention |
| --- | --- | --- |
| DomainX | `p` is a DomainX ID. | A framework root uses `p = i`. |
| ModelX | `ps` contains parent ModelX IDs. | An empty array records no parents. Section composition is declared in MapX. |
| QueryX | `p` is the immediate parent QueryX ID. | `p = 0`. A child references an existing, same-domain QueryX. |
| Recursive business table | `p` is a row ID in that same generated table. | The selected table workflow defines the root rule. |

[JCore QueryX design](queryx-redesign.md) · [Recursive table workflow](../../aix/discussion/2026-11-19-recursive-table-workflow.md)

---

## Special Arrays: DomainX Provenance

DomainX has special provenance tracking arrays:

| Column | Taxonomy Pattern | Description |
|---|---|---|
| **i_dxis** | i_dxis | Imported source template domain IDs |
| **c_dxis** | c_dxis | Copied source template/solution domain IDs |

**Key Points:**
- These are provenance arrays, NOT hierarchy
- Track where domain was imported/copied from
- Both are domain ID arrays (specialized forms of dxis)
- Naming matches taxonomy pattern directly

**Schema:**
```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    i_dxis INT[] NOT NULL DEFAULT '{}',  -- Imported sources
    c_dxis INT[] NOT NULL DEFAULT '{}',  -- Copied sources
    ...
);
```

---

## Three-Level Naming Convention

JCore defines three naming levels for different contexts:

### Level 1: Database Column (Physical)

Short names for database efficiency:

```sql
dxi    -- domain ID
txi    -- table ID
mxi    -- model ID
i      -- identity
e      -- editor
a      -- active
n      -- name
c      -- code
p      -- parent
ttx    -- table type
dtx    -- data type
```

### Level 2: Variable Names (Code)

Taxonomy pattern with `v_` prefix:

```sql
v_dxi   -- DomainX ID variable
v_mxi   -- ModelX ID variable
v_fxi   -- FieldX ID variable
v_dtx   -- Data type variable
v_ttx   -- Table type variable
v_ctx   -- Column type variable
```

### Level 3: API Fields (Interface)

Descriptive names for clarity:

```json
{
  "domainId": 1,
  "modelId": 500,
  "fieldId": 1001,
  "dataType": 30000,
  "tableType": 100014
}
```

Or snake_case:

```json
{
  "domain_id": 1,
  "model_id": 500,
  "field_id": 1001,
  "data_type": 30000,
  "table_type": 100014
}
```

---

## Migration Requirements

### Critical Field Name Changes

The fresh AIX schema uses the JCore type names below. The short forms are listed for recognizing earlier schemas.

**Current (INCORRECT):**
```sql
dt INT NOT NULL  -- Wrong
tt INT NOT NULL  -- Wrong
ct INT NOT NULL  -- Wrong
mt INT NOT NULL  -- Wrong
ft INT NOT NULL  -- Wrong
qt INT NOT NULL  -- Wrong
pt INT NOT NULL  -- Wrong
```

**Correct (Taxonomy Compliant):**
```sql
dtx INT NOT NULL  -- Correct
ttx INT NOT NULL  -- Correct
ctx INT NOT NULL  -- Correct
mtx INT NOT NULL  -- Correct
ftx INT NOT NULL  -- Correct
qtx INT NOT NULL  -- Correct
ptx INT NOT NULL  -- Correct
```

### Type field names

Existing taxonomy updates include:

- `modelx.mt` → `modelx.mtx`
- `queryx.qt` → `queryx.qtx`
- `tablex.tt` → `tablex.ttx`
- `columnx.dt` → `columnx.dtx`
- `columnx.ct` → `columnx.ctx`
- `fieldx.ft` → `fieldx.ftx`
- `paramx.pt` → `paramx.ptx`

### Terminology Migration

**Entity → Model:**

All "entity" references must be changed to "model":

- Class names: `EntityX` → `ModelX`
- Variables: `entityId` → `modelId`
- Enums: `QueryType.entityGet` → `QueryType.modelGet`
- Database: `target_kind='entity'` → `target_kind='model'`
- JSON: `'entity_get'` → `'model_get'`

---

## Verification Checklist

Before claiming JCore compliance, verify:

- [ ] Database schema uses `mtx`, `qtx`, `ttx`, `dtx`, `ctx`, `ftx`, `ptx`
- [ ] No references to `mt`, `qt`, `tt`, `dt`, `ct`, `ft`, `pt` in schema
- [ ] Documentation uses "Model" not "Entity"
- [ ] API uses `modelId` not `entityId`
- [ ] JSON keys match JCore taxonomy
- [ ] Code generation templates use correct field names
- [ ] Query type categories: system, table, **model** (not entity)
- [ ] Variable names use `v_` prefix taxonomy pattern
- [ ] All `p` and `ps` columns are self-referential
- [ ] NUMERIC types use exact decimal, not double
- [ ] Active status is binary (0 or 1), no lock bits

---

## Quick Reference

### ID Patterns
```
dxi/dxis    txi/txis    cxi/cxis    mxi/mxis
fxi/fxis    qxi/qxis    pxi/pxis    sxi/sxis
mapxi/mapxis           tx/txs
```

### Type Patterns
```
dtx/dtxs (Group 3)    ttx/ttxs (Group 4)    ctx/ctxs (Group 5)
mtx/mtxs (Group 6)    ftx/ftxs (Group 7)    qtx/qtxs (Group 8)
ptx/ptxs (Group 9)
```

### System Columns
```
i=identity   d=date      e=editor    a=active
n=name       c=code      p=parent    f=foreign
s=status     v=version   o=ordinal   m=marker
```

### Type ID Formulas
```
Groups 4+:   i = (tgi - 3) × 100000 + k
NUMERIC(p,s): 60000 + (p × 100) + s
TEXT(n):      70000 + n
```

---

## See Also

- [Type Catalogs](../reference/type-catalogs.md) - Complete TypeX group system
- [ID Generation](../../db/reference/id-generation.md) - ID generation algorithms
- [Coding Standards](../guides/coding-standards.md) - Implementation patterns
- [Database Schema](../../db/reference/schema.md) - Schema structure
- [JCore Repository](https://github.com/codexpilot/jcore) - Authoritative source

---

**Document Status:** Active  
**Last Updated:** 2026-01-XX  
**Authority:** JCore 4.1.0

**Maintained By:** AIX Core Team
