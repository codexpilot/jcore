# AIX Coding Standards

**Consolidated from:**
- .claude/CLAUDE.md (Database Pattern section)
- docs/12-IMPLEMENTATION-REFERENCES.md
- docs/COLUMN-NAMING-STANDARDS.md
- docs/JSON-CODING-STANDARD.md
- docs/CODE_STYLE_GUIDE.md

**Consolidation Date:** 2026-01-XX  
**Status:** Active - Project Standard

---

## Overview

This document defines coding standards for the AIX project, covering database patterns, naming conventions, CRUD functions, and implementation guidelines.

**Scope:**
- Database schema design
- Column naming conventions
- CRUD function patterns
- JSON serialization
- Code generation standards

---

## Database Patterns

### AIX Standard Pattern

**If user does not specify a different pattern**, use this standard:

### Column Names (System Columns)

#### MetaX Tables (Metadata)

MetaX tables use **6 core columns**:

| Column | Name | Type | Description |
|---|---|---|---|
| **i** | Identity | INT/BIGINT/TEXT | Primary key, record ID |
| **d** | Date | BIGINT | Last edit timestamp (epoch ms UTC) |
| **e** | Editor | INT | Last editor user ID |
| **a** | Active | SMALLINT | Binary status (0=inactive, 1=active) |
| **n** | Name | TEXT | Display name/title/description |
| **c** | Code | TEXT | Immutable identifier |

**Example:**
```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    d BIGINT NOT NULL,
    e INT NOT NULL,
    a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0,1)),
    n TEXT NOT NULL,
    c TEXT NOT NULL UNIQUE
);
```

#### Generated Runtime Tables

Generated runtime tables use **7 fixed columns**:

| Column | Name | Type | Description |
|---|---|---|---|
| **i** | Identity | INT/BIGINT/UUID | Primary key (format from table type) |
| **d** | Date | BIGINT | Last edit timestamp (epoch ms UTC) |
| **e** | Editor | INT | Last editor user ID |
| **a** | Active | SMALLINT | Binary status (0=inactive, 1=active) |
| **n** | Name | TEXT | Display name |
| **s** | Status | INT32 | Business workflow state |
| **v** | Version | INT32 | Edit count (optimistic concurrency) |

**Optional columns (via ColumnX metadata):**
- **c** - Code (TEXT, immutable identifier)
- **f** - Foreign key reference (matches parent table id type)
- **p** - Parent id (self-referential, for hierarchical models)
- **o** - Sort order/sequence (datatype configurable)
- Custom business columns (c1, c2, c3, etc.)

**Example:**
```sql
CREATE TABLE customers (
    i BIGINT PRIMARY KEY,
    d BIGINT NOT NULL,
    e INTEGER NOT NULL,
    a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0,1)),
    n TEXT NOT NULL,
    s INTEGER NOT NULL DEFAULT 0,
    v INTEGER NOT NULL DEFAULT 0,
    
    -- Optional fixed
    c TEXT UNIQUE,
    p BIGINT REFERENCES customers(i),
    
    -- Custom business columns
    c1 TEXT,    -- email
    c2 TEXT,    -- phone
    c3 JSONB    -- metadata
);
```

### Important Distinctions

| Aspect | MetaX Tables | Generated Tables |
|--------|--------------|------------------|
| **Core columns** | 6 (i, d, e, a, n, c) | 7 (i, d, e, a, n, s, v) |
| **Status column** | ❌ No `s` | ✅ Has `s` |
| **Version column** | ❌ No `v` | ✅ Has `v` |
| **Active meaning** | Binary (0 or 1) | Binary (0 or 1) |
| **Lock status** | Not in `a` | Not in `a` (use `s`) |

**CRITICAL RULES:**

1. **Active status is binary only:** 0=inactive, 1=active
2. **Lock status belongs in workflow status column (`s`), NOT active status (`a`)**
3. **Status (`s`) and version (`v`):** Only in generated runtime tables, NOT MetaX
4. **Parent column (`p`):** Self-referential only (p=i for root, p!=i for child)

### Parent Column Rules

**Self-referential only:**
- `p` column MUST reference the same table's `i` column
- Root nodes: `p = i` (self-reference)
- Child nodes: `p != i` (references parent in same table)

**Forbidden:**
- Cross-table parent references (e.g., FieldX.p → ColumnX.i)

**Example:**
```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    p INT NOT NULL,
    CONSTRAINT domainx_parent_fk FOREIGN KEY (p) REFERENCES mx.domainx(i),
    CONSTRAINT domainx_root_self_parent CHECK (i NOT BETWEEN -1000 AND -1 OR p = i)
);
```

---

## Column Registry Mapping

Map short column names in `registry.json`:

```json
{
  "tables": {
    "customers": {
      "columns": {
        "i": "id",
        "d": "date_last_edit",
        "e": "last_editor",
        "a": "active_status",
        "n": "name",
        "s": "workflow_status",
        "v": "version",
        "c": "code",
        "c1": "email",
        "c2": "phone",
        "c3": "metadata"
      }
    }
  }
}
```

**Purpose:**
- Human-readable field names for APIs
- Documentation generation
- Client-side mapping

---

## DateTime Standard

### Storage

**Always use epoch milliseconds UTC (INTEGER/BIGINT)**

```sql
d BIGINT NOT NULL  -- Epoch milliseconds since 1970-01-01 00:00:00 UTC
```

**Example values:**
- 1730384400000 = 2024-10-31 15:00:00 UTC
- 1640995200000 = 2022-01-01 00:00:00 UTC

### Display Formats

Choose based on precision needs:

| Format | Example | Use Case |
|--------|---------|----------|
| `yyyy-MM-dd HH:mm` | 2024-10-31 15:30 | Standard display |
| `yyyy-MM-dd HH:mm:ss` | 2024-10-31 15:30:45 | Detailed logs |
| `yyyy-MM-dd HH:mm:ss.SSS` | 2024-10-31 15:30:45.123 | High-precision |

### Implementation

**PostgreSQL to epoch ms:**
```sql
EXTRACT(EPOCH FROM clock_timestamp() AT TIME ZONE 'UTC')::bigint * 1000
```

**Epoch ms to PostgreSQL:**
```sql
to_timestamp(d / 1000.0) AT TIME ZONE 'UTC'
```

**Display formatting:**
```sql
to_char(to_timestamp(d / 1000.0) AT TIME ZONE 'UTC', 'YYYY-MM-DD HH24:MI:SS')
```

---

## CRUD Functions

### Function Naming

Use only **TWO functions per table** (AIX naming convention):

1. **`get<tablename>(jsonb)`** - Read operations (get by id, list with filters)
2. **`set<tablename>(jsonb)`** - Write operations (insert, update, delete)

**Examples:**
- `getdomainx(jsonb)` / `setdomainx(jsonb)`
- `getmodelx(jsonb)` / `setmodelx(jsonb)`
- `getsqlx(jsonb)` / `setsqlx(jsonb)`
- `getcustomers(jsonb)` / `setcustomers(jsonb)`

### Get Function Pattern

```sql
CREATE OR REPLACE FUNCTION get<tablename>(p_params JSONB)
RETURNS JSONB AS $$
DECLARE
    v_i <id_type>;
    v_mode TEXT;
    v_limit INT;
    v_offset INT;
    v_result JSONB;
BEGIN
    v_i := (p_params->>'i')::<id_type>;
    v_mode := COALESCE(p_params->>'_mode', 'list');
    v_limit := COALESCE((p_params->>'_limit')::int, 100);
    v_offset := COALESCE((p_params->>'_offset')::int, 0);
    
    IF v_mode = 'single' AND v_i IS NOT NULL THEN
        -- Get by ID
        SELECT row_to_json(t) INTO v_result
        FROM <tablename> t
        WHERE i = v_i AND a = COALESCE((p_params->>'a')::smallint, 1);
        
        RETURN jsonb_build_object('data', v_result);
        
    ELSIF v_mode = 'list' THEN
        -- List with filters
        SELECT jsonb_build_object(
            'data', COALESCE(jsonb_agg(row_to_json(t)), '[]'::jsonb),
            'meta', jsonb_build_object('count', COUNT(*))
        ) INTO v_result
        FROM (
            SELECT * FROM <tablename>
            WHERE a = COALESCE((p_params->>'a')::smallint, 1)
            ORDER BY i
            LIMIT v_limit OFFSET v_offset
        ) t;
        
        RETURN v_result;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Set Function Pattern

```sql
CREATE OR REPLACE FUNCTION set<tablename>(p_params JSONB)
RETURNS JSONB AS $$
DECLARE
    v_i <id_type>;
    v_operation TEXT;
    v_result JSONB;
BEGIN
    v_i := COALESCE((p_params->>'i')::<id_type>, 0);
    v_operation := COALESCE(p_params->>'_operation', 'insert');
    
    IF v_i = 0 OR v_operation = 'insert' THEN
        -- INSERT: Create new record
        INSERT INTO <tablename> (i, d, e, a, n, s, v, ...)
        VALUES (
            COALESCE(v_i, generate_next_id()),  -- ID generation
            EXTRACT(EPOCH FROM clock_timestamp() AT TIME ZONE 'UTC')::bigint * 1000,
            (p_params->>'e')::int,
            COALESCE((p_params->>'a')::smallint, 1),
            p_params->>'n',
            COALESCE((p_params->>'s')::int, 0),
            0,  -- Initial version
            ...
        )
        RETURNING row_to_json(<tablename>.*) INTO v_result;
        
    ELSIF v_operation = 'update' THEN
        -- UPDATE: Modify existing record
        UPDATE <tablename>
        SET 
            d = EXTRACT(EPOCH FROM clock_timestamp() AT TIME ZONE 'UTC')::bigint * 1000,
            e = (p_params->>'e')::int,
            a = COALESCE((p_params->>'a')::smallint, a),
            n = COALESCE(p_params->>'n', n),
            s = COALESCE((p_params->>'s')::int, s),
            v = v + 1,  -- Increment version
            ...
        WHERE i = v_i
        RETURNING row_to_json(<tablename>.*) INTO v_result;
        
    ELSIF v_operation = 'delete' THEN
        -- SOFT DELETE: Set a=0
        UPDATE <tablename>
        SET 
            d = EXTRACT(EPOCH FROM clock_timestamp() AT TIME ZONE 'UTC')::bigint * 1000,
            e = (p_params->>'e')::int,
            a = 0
        WHERE i = v_i
        RETURNING row_to_json(<tablename>.*) INTO v_result;
    END IF;
    
    RETURN jsonb_build_object('data', v_result);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### CRUD Conventions

**Insert (i=0):**
```json
{
  "i": 0,
  "e": 100,
  "n": "New Record",
  "field1": "value1"
}
```

**Update (i>0):**
```json
{
  "i": 12345,
  "e": 100,
  "n": "Updated Record",
  "field1": "new value"
}
```

**Soft Delete:**
```json
{
  "i": 12345,
  "e": 100,
  "a": 0
}
```

### Auto-updated Fields

These fields are automatically set by `set` functions:

| Field | On Insert | On Update |
|---|---|---|
| `d` | Current timestamp | Current timestamp |
| `e` | From params | From params |
| `v` | 0 | v + 1 (increment) |
| `i` | Generated if 0 | Unchanged |

**Never manually set:**
- `d` - Always auto-set to current timestamp
- `v` - Always auto-incremented on update

---

## Soft Delete

**Rule:** Never hard delete records. Always use soft delete by setting `a = 0`.

### Why Soft Delete?

1. **Audit trail** - Preserve record history
2. **Data integrity** - Foreign keys remain valid
3. **Reversibility** - Can restore deleted records
4. **Compliance** - Meet regulatory requirements

### Implementation

```sql
-- Soft delete via setcustomers
SELECT setcustomers('{
  "i": 12345,
  "e": 100,
  "a": 0
}'::jsonb);

-- Filter out inactive in queries
SELECT * FROM customers WHERE a = 1;
```

### Reactivation

```sql
-- Restore deleted record
SELECT setcustomers('{
  "i": 12345,
  "e": 100,
  "a": 1
}'::jsonb);
```

---

## JSON Coding Standard

### JSONB Convention

**Use JSONB for all JSON columns:**

```sql
metadata JSONB DEFAULT '{}'::jsonb
```

**Reasons:**
- Faster querying with GIN indexes
- Binary storage (smaller)
- Validation on insert
- Better performance for large documents

### Numeric Type Serialization

**CRITICAL:** JCore `Numeric` type MUST serialize as string in JSON.

**Correct:**
```json
{
  "price": "19.99",
  "quantity": "10.00"
}
```

**Incorrect:**
```json
{
  "price": 19.99,
  "quantity": 10.0
}
```

**Rationale:**
- Preserves exact decimal value (no floating-point errors)
- Maintains scale (10.00 ≠ 10.0 ≠ 10)
- JavaScript safe (no precision loss)
- Financial/medical accuracy requirements

### Date Serialization

Dates serialize as BIGINT epoch milliseconds:

```json
{
  "created_at": 1730384400000,
  "updated_at": 1730384400123
}
```

### Array Serialization

Arrays serialize as JSON arrays:

```json
{
  "tags": ["tag1", "tag2", "tag3"],
  "related_ids": [100, 200, 300]
}
```

---

## Code Generation Conventions

### Variable Naming

Use JCore taxonomy patterns in generated code:

**PostgreSQL functions:**
```sql
DECLARE
    v_dxi INT;        -- Domain ID
    v_txi BIGINT;     -- Table ID
    v_mxi BIGINT;     -- Model ID
    v_fxi BIGINT;     -- Field ID
    v_ttx INT;        -- Table type
    v_dtx INT;        -- Data type
BEGIN
    ...
END;
```

### Function Generation

**Pattern:**
1. Extract control parameters first
2. Validate required fields
3. Execute operation based on mode/operation
4. Return JSONB result

**Example:**
```sql
-- Extract parameters
v_mode := COALESCE(p_params->>'_mode', 'list');
v_limit := COALESCE((p_params->>'_limit')::int, 100);

-- Validate
IF v_mode NOT IN ('single', 'list', 'search') THEN
    RAISE EXCEPTION 'Invalid mode: %', v_mode;
END IF;

-- Execute
CASE v_mode
    WHEN 'single' THEN ...
    WHEN 'list' THEN ...
    WHEN 'search' THEN ...
END CASE;

-- Return
RETURN jsonb_build_object('data', v_result, 'meta', v_meta);
```

---

## Implementation References

| Behavior | Source File |
|----------|-------------|
| TypeX and JCore catalog seed | `db/aix/seed/seed.sql` |
| Type validation | `db/aix/functions/validation.sql`, `db/aix/functions/type_helpers.sql` |
| MetaX schema | `db/aix/tables/tablex.sql`, `db/aix/tables/columnx.sql`, etc. |
| MetaX CRUD | `db/aix/functions/*_crud.sql` |
| ID generation | `db/aix/tables/generation.sql` |
| Runtime DDL generation | `db/jdx/runtime_generation.sql` |
| Algorithm 2 BIGINT | `db/jdx/algorithm2_bigint.sql` |
| Algorithm 2 UUID | `db/jdx/algorithm2_uuid.sql` |
| API validation | `aixhub/metax_helpers.go` |
| Type selectors | `contextstudio/lib/services/typex_service.dart` |

---

## Validation Patterns

### Required Field Validation

```sql
IF p_params->>'n' IS NULL THEN
    RAISE EXCEPTION 'Field "n" is required';
END IF;
```

### Type Validation

```sql
IF NOT valid_data_type((p_params->>'dtx')::int) THEN
    RAISE EXCEPTION 'Invalid data type: %', p_params->>'dtx';
END IF;
```

### Foreign Key Validation

```sql
IF NOT EXISTS (SELECT 1 FROM mx.domainx WHERE i = v_dxi) THEN
    RAISE EXCEPTION 'Domain % not found', v_dxi;
END IF;
```

### Business Logic Validation

```sql
IF v_status = 0 AND v_active = 1 THEN
    RAISE EXCEPTION 'Inactive records cannot have draft status';
END IF;
```

---

## Best Practices

### Database Design

1. **Use AIX standard columns** - Stick to i, d, e, a, n, s, v pattern
2. **Binary active status** - Always 0 or 1, never use for locking
3. **Soft delete only** - Never hard delete records
4. **Self-referential parent** - p column must reference same table
5. **Epoch milliseconds** - Always store dates as BIGINT epoch ms UTC
6. **JSONB for metadata** - Use JSONB, not JSON

### CRUD Functions

1. **Two functions per table** - get<table> and set<table> only
2. **Control parameters prefixed** - Use `_mode`, `_limit`, etc.
3. **Auto-update d and v** - Never manual timestamps or versions
4. **i=0 for insert** - Sentinel value for create operation
5. **SECURITY DEFINER** - Functions run with owner privileges
6. **Return JSONB** - Always return structured JSONB response

### Code Generation

1. **Follow taxonomy** - Use v_dxi, v_txi patterns
2. **Validate inputs** - Check all parameters before use
3. **Handle errors** - Meaningful error messages
4. **Return structured** - Always { "data": ..., "meta": ... }
5. **Document behavior** - Comment complex logic

---

## See Also

- [JCore Taxonomy](../architecture/taxonomy.md) - Naming standards
- [Type Catalogs](../reference/type-catalogs.md) - Type system reference
- [ID Generation](../../db/reference/id-generation.md) - ID generation algorithms
- [Generation Workflow](../../codegen/reference/generation-workflow.md) - DDL/CRUD generation
- [Database Schema](../../db/reference/schema.md) - Schema structure

---

**Document Status:** Active  
**Last Updated:** 2026-01-XX  
**Maintained By:** AIX Core Team  
**Authority:** Project standard for all AIX development
