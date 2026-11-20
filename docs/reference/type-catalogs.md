# AIX Type Catalogs

**Consolidated from:**
- docs/10-TYPE-CATALOGS.md
- docs/09-TABLE-TYPE-IMPLEMENTATION.md
- docs/15-FIELD-TYPE-REFERENCE.md
- docs/TYPE_SYSTEM_REDESIGN.md
- docs/TABLE_TYPE_FORMAT_MAPPING.md
- docs/COMPLETE-TAXONOMY-SPECIFICATION.md
- docs/archive/TYPEX_ID_EXPANSION_SUMMARY.md

**Consolidation Date:** 2026-01-XX  
**Status:** Active - Source of Truth for TypeX Catalogs

---

## Overview

This document describes the complete TypeX catalog system used by `db/aix/seed/seed.sql`, `db/aix/functions/validation.sql`, AIXHub, and ContextStudio. TypeX provides type safety and validation across all AIX components through a hierarchical group system.

---

## TypeX Group System

TypeX assigns each catalog group an ID range. The fresh AIX loader seeds groups 0–9 and group 12.

| Group | ID Range | Catalog | Description |
|---:|---:|---|---|
| 0 | 0–99 | SYX user roles | System user role definitions |
| 1 | 100–199 | DomainX types | Domain categorization types |
| 2 | 1000–1999 | AppX platform | Platform and app combinations |
| 3 | 10000–99999 | JCore data types | Fundamental data types |
| 4 | 100000–199999 | Table types | Table structure and behavior |
| 5 | 200000–299999 | Column types | Column categorization |
| 6 | 300000–399999 | Model types | Model categorization |
| 7 | 400000–499999 | Field types | Field capabilities |
| 8 | 500000–599999 | Query types | Query operations |
| 9 | 600000–699999 | Parameter types | Parameter roles |
| 12 | 900000–999999 | MapX operation types | Constraints, relationships, and bindings |

### Encoding Formula

**For groups 4 and higher:**
```
i = (tgi - 3) × 100000 + k
```

Where:
- `tgi` = TypeX group ID
- `k` = Type-specific encoding
- `i` = Final TypeX catalog ID

**For groups 0-3:**  
Groups 0-3 use their catalog ID directly as `i` and `k` according to the catalog definition.

---

## Group 3: JCore Data Types (10000-99999)

JCore provides fundamental data types used throughout the AIX system. All MetaX and generated tables use these types.

### Fixed Data Types

| ID | JCore Name | PostgreSQL Type | Description |
|---:|---|---|---|
| 10000 | BOOLEAN | boolean | Boolean true/false |
| 20000 | SMALLINT (INT16) | smallint | 16-bit integer |
| 30000 | INT32 | integer | 32-bit integer (default integer) |
| 40000 | INT64 | bigint | 64-bit integer |
| 40001 | DATETIME | bigint | Epoch milliseconds UTC |
| 40002 | TIME | bigint | Milliseconds since midnight |
| 50000 | UUID | uuid | UUID type |
| 60000 | NUMERIC | numeric | Arbitrary precision decimal |
| 70000 | TEXT | text | Variable-length text |
| 80000 | JSON | json | JSON data |
| 80001 | JSONB | jsonb | Binary JSON data |

### Parameterized Types

#### NUMERIC(p,s)
```
ID = 60000 + (p × 100) + s
Range: 60100–69999
```

Examples:
- NUMERIC(10,2) = 60000 + (10 × 100) + 2 = 61002
- NUMERIC(15,4) = 60000 + (15 × 100) + 4 = 61504

#### TEXT(n)
```
ID = 70000 + n
Range: 70001–79999
```

Examples:
- TEXT(50) = 70050
- TEXT(255) = 70255
- TEXT(1000) = 71000

### Date and Time Storage

**DATETIME (40001):**
- Stored as BIGINT epoch milliseconds UTC
- Display: `yyyy-MM-dd HH:mm` or `yyyy-MM-dd HH:mm:ss` or `yyyy-MM-dd HH:mm:ss.SSS`
- Always UTC internally, convert for display

**TIME (40002):**
- Stored as BIGINT milliseconds since midnight
- Range: 0 to 86399999 (24 hours)

### JSON Types

**JSON (80000):**
- Text-based JSON storage
- Full JSON validation
- Use for human-readable storage

**JSONB (80001):**
- Binary JSON storage
- Faster querying and indexing
- Preferred for query operations
- Use for performance-critical data

### Important Notes

- **Type 40003 does NOT exist** (was incorrectly documented as TEXT in some older docs)
- Status and version columns MUST use INT32 (30000)
- Active status is binary: 0=inactive, 1=active
- Lock state belongs in workflow status column, NOT active status

---

## Group 4: Table Types (100000-199999)

Table types define table structure, ID generation strategy, sync behavior, and logging requirements.

### Encoding Formula (SDALF)

```
k = S × 1000 + DA × 100 + L × 10 + F
ID = 100000 + k

Where:
  S  = Sync policy (0-3)
  DA = Direction×Algorithm packed (0-8)
  L  = Log features (0-3)
  F  = ID format (3,4,5)
```

### Dimensions

#### 1. Sync Policy (S, Multiplier: 1000)

| Value | Policy | Description |
|---:|---|---|
| 0 | Private | Local to single database instance |
| 1 | Protected | Reserved for future use |
| 2 | Synced-Origin | Synchronized across instances |
| 3 | Synced-Origin-Main | Main sync node (requires logging) |

**Validation:**
- Sync values 2 and 3 require BIGINT or UUID format
- Sync value 3 MUST have logging enabled (L ≥ 2)

#### 2. Direction×Algorithm (DA, Multiplier: 100)

The DA dimension packs direction and algorithm into a single digit:

```
DA = (Direction - 1) × 3 + Algorithm

Where:
  Direction ∈ {1, 2, 3}
  Algorithm ∈ {0, 1, 2}
```

**Complete DA Lookup Table:**

| DA | Direction | Algorithm | Description |
|---:|---:|---:|---|
| 0 | 1 (Unclaimed) | 0 (Custom) | No policy, caller-supplied IDs |
| 1 | 1 (Unclaimed) | 1 (Auto-inc) | No policy, sequence IDs |
| 2 | 1 (Unclaimed) | 2 (Epoch-SS) | No policy, generated IDs |
| 3 | 2 (Table-Win) | 0 (Custom) | Table rules model, custom IDs |
| 4 | 2 (Table-Win) | 1 (Auto-inc) | Table rules model, sequence IDs |
| 5 | 2 (Table-Win) | 2 (Epoch-SS) | Table rules model, generated IDs |
| 6 | 3 (Model-Win) | 0 (Custom) | Model rules table, custom IDs |
| 7 | 3 (Model-Win) | 1 (Auto-inc) | Model rules table, sequence IDs |
| 8 | 3 (Model-Win) | 2 (Epoch-SS) | Model rules table, generated IDs |

**Direction Policies:**
- **Unclaimed (1):** No ownership policy defined between table and model
- **Table-Win (2):** Table rules model - table structure and constraints are authoritative
- **Model-Win (3):** Model rules table - domain model and business logic are authoritative

**Algorithm Types:**
- **Custom (0):** Caller-supplied IDs
- **Auto-increment (1):** Database sequence/identity
- **Epoch-Server-Serial (2):** Generated BIGINT/UUID from allocator

**Extraction:**
```sql
direction = DA / 3 + 1
algorithm = DA % 3
```

#### 3. Log Features (L, Multiplier: 10)

The log dimension encodes logging and recursiveness:

```
L = Logging × 2 + Recursiveness
```

| L | Logging | Recursiveness | Log Table | Parent Column |
|---:|---|---|---|---|
| 0 | Off | Off | No | No |
| 1 | Off | On | No | Required (200103) |
| 2 | On | Off | Yes | No |
| 3 | On | On | Yes | Required (200103) |

**Extraction:**
```sql
logging = (L >= 2)
recursiveness = (L % 2 = 1)
```

#### 4. ID Format (F, Multiplier: 1)

| Value | JCore Type | SQL Type | Description |
|---:|---:|---|---|
| 3 | 30000 | INTEGER | 32-bit integer |
| 4 | 40000 | BIGINT | 64-bit integer |
| 5 | 50000 | UUID | UUID type |

**Validation:**
- Sync values 2 and 3 require format 4 (BIGINT) or 5 (UUID)
- INTEGER format (3) only allowed for Private (S=0) and Protected (S=1)
- Algorithm 1 (Auto-inc) supports INTEGER and BIGINT
- Algorithm 2 (Epoch-SS) supports BIGINT and UUID only

### Default Table Type

**100104** - The standard default table type:

```
k = 104
S  = 0 (Private)
DA = 1 → Direction=1 (Unclaimed), Algorithm=1 (Auto-inc)
L  = 0 (Log Off, Rec Off)
F  = 4 (BIGINT)
```

**Meaning:** Private, Unclaimed policy, Auto-increment, No logging/recursiveness, BIGINT

### Example Table Types

| ID | S | DA | L | F | Description |
|---:|---|---:|---|---|-------------|
| 100104 | 0 | 1 | 0 | 4 | Private, Unclaimed, Auto-inc, Flat, BIGINT |
| 100404 | 0 | 4 | 0 | 4 | Private, Table-Win, Auto-inc, Flat, BIGINT |
| 100704 | 0 | 7 | 0 | 4 | Private, Model-Win, Auto-inc, Flat, BIGINT |
| 100424 | 0 | 4 | 2 | 4 | Private, Table-Win, Auto-inc, Logged, BIGINT |
| 100714 | 0 | 7 | 1 | 4 | Private, Model-Win, Auto-inc, Recursive, BIGINT |
| 102424 | 2 | 4 | 2 | 4 | Synced, Table-Win, Auto-inc, Logged, BIGINT |

### Catalog Size

The catalog contains approximately **150-200 structurally valid table types** with SDALF encoding.

### Validation Rules

1. Populated table's ID type cannot be changed in place
2. Changing storage type requires explicit migration
3. Recursiveness validation enforced by ColumnX checks
4. Logging tables auto-generated by JDB when required
5. Sync policy constraints enforced at table creation
6. Direction policies are metadata only (runtime behavior not yet implemented)

---

## Group 5: Column Types (200000-299999)

Column types use 3-dimensional encoding to categorize columns by registry, uniqueness, and scheme.

### Encoding Formula

```
ID = 200000 + Registry × 100 + Uniqueness × 10 + Scheme
Format: 2nn[X][Y][Z]
```

Where (reading right to left):
- **Z** (rightmost digit): Scheme (0-4)
- **Y** (middle digit): Uniqueness (0-5)
- **X** (left digit): Registry (0-9)

### Dimension 1: Scheme (Z, rightmost digit, 0-4)

Column category:

| Value | Scheme | Description |
|---:|---|---|
| 0 | User | Business/custom columns |
| 1 | System-key | i=ID, c=Code (MUST have uniqueness ≥ 1) |
| 2 | System-log | d, e, a, v, s, m columns |
| 3 | System-map | f=Foreign key, p=Parent |
| 4 | System-other | n=Name, o=Sort order |

### Dimension 2: Uniqueness (Y, middle digit, 0-5)

Constraint type:

| Value | Uniqueness | Description |
|---:|---|---|
| 0 | Non-unique | No uniqueness constraint |
| 1 | ID key unique | Primary key (only for `i` column) |
| 2 | Single unique | Unique constraint on single column |
| 3 | Single semi-unique | Conditional uniqueness (e.g., unique if value > 0) |
| 4 | Composite unique | Unique as part of multi-column constraint |
| 5 | Composite semi-unique | Conditional composite uniqueness |

**Validation Rule:** System-key scheme (Z=1) columns MUST have uniqueness ≥ 1.

### Dimension 3: Registry (X, left digit, 0-9)

Role within scheme group:

**Scheme 0 (User):**
- 00 = Generic user column

**Scheme 1 (System-key):**
- 00 = i (ID) — must be ID key unique (uniqueness=1)
- 01 = c (Code) — must be unique (uniqueness ≥ 1)

**Scheme 2 (System-log):**
- 00 = d (Date)
- 01 = e (Editor)
- 02 = a (Active)
- 03 = v (Version)
- 04 = s (Status)
- 05 = m (Server or terminal)

**Scheme 3 (System-map):**
- 00 = f (Foreign key)
- 01 = p (Parent)

**Scheme 4 (System-other):**
- 00 = n (Name)
- 01 = o (Sort order)

### Standard Column Catalog

| ID | Registry | Uniqueness | Scheme | Code | Role | Data Type |
|---:|---:|---:|---:|---|---|---|
| 200000 | 0 | 0 | 0 | `user` | User-defined column | Varies |
| 200020 | 0 | 2 | 0 | `user_unique` | User column with unique | Varies |
| 200040 | 0 | 4 | 0 | `user_composite` | User composite unique | Varies |
| 200011 | 0 | 1 | 1 | `i` | ID (Primary Key) | INT/BIGINT/UUID |
| 200111 | 1 | 1 | 1 | `c` | Code (Unique) | TEXT |
| 200002 | 0 | 0 | 2 | `d` | Last-edit date | BIGINT |
| 200102 | 1 | 0 | 2 | `e` | Last editor | INT/BIGINT/UUID |
| 200202 | 2 | 0 | 2 | `a` | Active status | SMALLINT |
| 200302 | 3 | 0 | 2 | `v` | Version | INT32 (30000) |
| 200402 | 4 | 0 | 2 | `s` | Workflow status | INT32 (30000) |
| 200502 | 5 | 0 | 2 | `m` | Server or terminal | INT/TEXT |
| 200003 | 0 | 0 | 3 | `f` | Foreign key | Varies |
| 200103 | 1 | 0 | 3 | `p` | Parent ID (self-ref) | Same as `i` |
| 200043 | 0 | 4 | 3 | `f_composite` | Foreign in composite | Varies |
| 200004 | 0 | 0 | 4 | `n` | Name | TEXT |
| 200104 | 1 | 0 | 4 | `o` | Sort order | INT/BIGINT |

### System Column Standards

**MetaX tables (metadata) use:**
- `i` - id (INT/BIGINT/TEXT PRIMARY KEY)
- `d` - date of last edit (BIGINT, epoch milliseconds UTC)
- `e` - last editor (INT, user_id foreign key)
- `a` - active status (SMALLINT, binary: 0=inactive, 1=active)
- `n` - name/title/description (TEXT)
- `c` - code (TEXT, immutable identifier)

**Generated runtime tables use 7 fixed columns:**
- `i` - id (format determined by table type)
- `d` - date of last edit (BIGINT, epoch ms UTC)
- `e` - last editor (INT, user_id foreign key)
- `a` - active status (SMALLINT, binary: 0=inactive, 1=active)
- `n` - name (TEXT)
- `s` - status (INT32, business workflow state: 0=draft, 1=pending, etc.)
- `v` - version (INT32, edit count for optimistic concurrency)

**Optional columns (via ColumnX metadata):**
- `c` - code (TEXT, immutable identifier)
- `f` - foreign key reference (matches parent table id type)
- `p` - parent id (self-referential, for hierarchical models)
  - `p == i` = root (self-reference indicates root node)
  - `p != i` = references parent record id
- `o` - sort order/sequence (datatype configurable)
- Custom business columns defined in ColumnX

### Important Distinctions

- **MetaX `a` column:** Binary only (0 or 1), no lock bits
- **Generated table `a` column:** Also binary (0 or 1)
- **Lock status:** NOT in `a` column, handled separately (e.g., syx uses bit flags)
- **`s` (status) and `v` (version):** Only in generated runtime tables, NOT in MetaX
- **Active status is NEVER used for locking:** Lock state belongs in workflow status column

---

## Group 6: Model Types (300000-399999)

Model types use `3xnnnnn`, where `x` is the claim type (0=unclaimed, 1=table-claimed-model, 2=model-claimed-table, 3=tables-claimed-model, 4=model-claimed-tables, 9=system) and `nnnnn` is sequential numbering. Each QueryX declares its operation through its Group 8 type. MapX specifies a model’s associations and composition. The ModelX default is `320000`. [ModelX types](model-types.md)

---

## Group 7: Field Types (400000-499999)

Field types define input/output capabilities for model fields.

### Standard Field Types

| ID | Capability | Description |
|---:|---|---|
| 400000 | Input and output | Full bidirectional field |
| 400001 | Input only | Write-only field (commands, passwords) |
| 400002 | Output only | Read-only field (calculated, system) |

### Query Operation Rules

**Input queries** (Set operations) accept fields:
- 400000 (Input and output)
- 400001 (Input only)

**Output queries** (Get operations) accept fields:
- 400000 (Input and output)
- 400002 (Output only)

### Field Ownership

- A field belongs to ONE model
- Field's model and query must share the same domain
- Column type and data type are separate metadata fields on FieldX

---

## Group 8: Query Types (500000-599999)

Query types define the target and operation of database queries.

### Query Type Catalog

| ID | Target | Operation | Description |
|---:|---|---|---|
| 500000 | System | Get | System read operations |
| 500001 | System | Set | System write operations |
| 510000 | Table | Get | Table read operations |
| 510001 | Table | Set | Table write operations |
| 520000 | Model | Get | Model read operations |
| 520001 | Model | Set | Model write operations |

### Target Types

**System (500xxx):**
- Metadata operations
- System configuration queries
- Cross-cutting concerns

**Table (510xxx):**
- Direct table access
- Raw data operations
- Table-level CRUD

**Model (520xxx):**
- Business logic operations
- Domain model queries
- Field-based operations

### Result Shape Configuration

Query result shape is configured separately on QueryX, not in the type itself. This allows flexible result formatting independent of query type.

---

## Group 9: Parameter Types (600000-699999)

ParamX records purpose in `ptx` (Group 9) and value type in `dtx` (Group 3). `direction`, `req`, and `metadata` describe flow, requiredness, defaults, and declared constraints. See the Parameter Types reference for seeded controls and data roles. [Parameter types](parameter-types.md)

## Group 12: MapX operations (900000–999999)

MapX operation codes encode scope, operation, parameter count, and a reserved digit. [MapX specification](mapx-design.md)

---

## Type Reference Patterns

### Generic TypeX

- Singular: `tx`
- Plural: `txs`

### Group-Specific Patterns (Special Rule)

TypeX references use group-specific patterns instead of generic `txi` pattern to distinguish by type group:

| TypeX Group | Column | Singular | Plural | Description |
|---|---|---|---|---|
| Group 3 | dtx | dtx | dtxs | Data type |
| Group 4 | ttx | ttx | ttxs | Table type |
| Group 5 | ctx | ctx | ctxs | Column type |
| Group 6 | mtx | mtx | mtxs | Model type |
| Group 7 | ftx | ftx | ftxs | Field type |
| Group 8 | qtx | qtx | qtxs | Query type |
| Group 9 | ptx | ptx | ptxs | Parameter type |

**Rationale:** Group-specific suffixes provide immediate type context and prevent ambiguity in code and database columns.

---

## Validation System

### Database-Level Validation

Validation is implemented in `db/aix/functions/validation.sql` and includes:

1. **Table Type Validation:**
   - Sync policy vs ID format compatibility
   - Algorithm vs ID format compatibility
   - Logging requirements for Synced-Origin-Main
   - Recursiveness vs parent column presence

2. **Column Type Validation:**
   - System-key columns must have uniqueness ≥ 1
   - Status and version must use INT32 (30000)
   - Active status must use SMALLINT (20000)
   - Parent column must match table's ID type

3. **Field Type Validation:**
   - Field types match query operation types
   - Input/output compatibility
   - Model and query domain matching

### Application-Level Validation

AIXHub and ContextStudio enforce:
- Type catalog lookups from active seed data
- Type compatibility in foreign key relationships
- Query parameter type matching
- Field capability verification

---

## Migration and Compatibility

### Changing Table Types

**Allowed:**
- Changing unpopulated table types before data insertion
- Adding logging to existing table (creates log table)
- Changing recursiveness if compatible with data

**Requires Migration:**
- Changing ID format (INTEGER ↔ BIGINT ↔ UUID)
- Changing sync policy if data exists
- Changing algorithm if incompatible with format

### Type Catalog Updates

New types can be added to any group without breaking existing types. The encoding formulas ensure no ID collisions.

**Process:**
1. Add new type to `db/aix/seed/seed.sql`
2. Update validation rules if needed
3. Update ContextStudio type dropdowns
4. Document in this reference

---

## See Also

- [ID Generation](../../db/reference/id-generation.md) - Algorithm implementation details
- [JCore Taxonomy](../architecture/taxonomy.md) - Complete naming and type standards
- [Coding Standards](../guides/coding-standards.md) - Implementation patterns
- [Database Schema](../../db/reference/schema.md) - Schema structure
- [Query System](../architecture/query-system.md) - Query execution details

---

**Document Status:** Active  
**Last Updated:** 2026-01-XX  
**Maintained By:** AIX Core Team  
**Source Files:** db/aix/seed/seed.sql, db/aix/functions/validation.sql
