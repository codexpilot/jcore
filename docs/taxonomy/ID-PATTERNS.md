# MetaX ID Reference Patterns

**Source of Truth:** JCore taxonomy documentation  
**Purpose:** Define column naming patterns for foreign key references to MetaX tables

**Scope:** These patterns apply to FOREIGN KEY columns that reference MetaX tables. Each MetaX table's own primary key is always named `i` (system column).

---

## MetaX Table ID Reference Patterns

**Purpose:** Define column names for FOREIGN KEY references to MetaX tables.

**Note:** Each MetaX table uses `i` as its own primary key (system column). These patterns define the column name when OTHER tables reference that primary key.

| Table | Singular Reference | Plural Array | Usage |
|-------|-------------------|--------------|-------|
| DomainX | dxi | dxis | Foreign key → domainx.i |
| TypeG | tgi | tgis | Foreign key → typeg.i |
| TypeX | tyxi | tyxis | Foreign key → typex.i (catalog row) |
| TableX | txi | txis | Foreign key → tablex.i |
| ColumnX | cxi | cxis | Foreign key → columnx.i |
| ModelX | mxi | mxis | Foreign key → modelx.i |
| FieldX | fxi | fxis | Foreign key → fieldx.i |
| QueryX | qxi | qxis | Foreign key → queryx.i |
| ParamX | pxi | pxis | Foreign key → paramx.i |
| SQLX | sxi | sxis | Foreign key → sqlx.i |
| RelationX | rxi | rxis | Foreign key → relationx.i |
| MapX | maxi | maxis | Foreign key → mapx.i |

**Example:**
```sql
-- DomainX has its own primary key 'i'
CREATE TABLE mx.domainx (
    i SERIAL PRIMARY KEY    -- The domain's own ID
);

-- TableX REFERENCES DomainX using 'dxi'
CREATE TABLE mx.tablex (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i)  -- Foreign key reference
);
```

---

## Pattern Rules

1. **Singular form** ends in `xi` (except MapX which uses `maxi`)
2. **Plural form** adds `s` to singular: `xis` or `maxis`
3. **Array types** always use plural form: `dxis INT[]`
4. **Variable prefix** is `v_` followed by taxonomy pattern: `v_dxi`
5. **JSON keys** use the taxonomy pattern: `"dxi"`, `"txi"`, `"mxi"`

---

## Examples

### Database Schema

```sql
CREATE TABLE mx.tablex (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i),  -- Domain reference
    txi BIGINT,                                  -- Table reference (self-reference)
    n TEXT NOT NULL
);

CREATE TABLE mx.modelx (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i),  -- Domain reference
    mxis BIGINT[] NOT NULL DEFAULT '{}',        -- Model references (plural array)
    n TEXT NOT NULL
);
```

### SQL Function

```sql
CREATE FUNCTION settablex(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_dxi INT;           -- Domain ID variable
    v_txi BIGINT;        -- Table ID variable
    v_mxis BIGINT[];     -- Model ID array
BEGIN
    v_dxi := (input->>'dxi')::int;
    v_txi := (input->>'txi')::bigint;
    v_mxis := CASE WHEN input ? 'mxis' 
        THEN ARRAY(SELECT jsonb_array_elements_text(input->'mxis')::bigint)
        ELSE '{}'::bigint[] END;
    
    INSERT INTO mx.tablex (i, dxi, txi, n)
    VALUES (v_i, v_dxi, v_txi, v_n)
    RETURNING *;
END;
$$ LANGUAGE plpgsql;
```

### JSON Input/Output

```json
{
  "i": 42,
  "dxi": 1,
  "txi": 100,
  "mxis": [200, 201, 202],
  "n": "Example Table"
}
```

### API Layer

For external APIs, use descriptive names:

```javascript
// API request/response
{
  "tableId": 42,
  "domainId": 1,
  "parentTableId": 100,
  "modelIds": [200, 201, 202]
}
```

The API layer translates between descriptive names and taxonomy patterns.

---

## Special Cases

### MapX Uses `maxi/maxis`

MapX is unique in using a four-letter base to avoid confusion with model IDs:

```sql
-- Correct
DECLARE v_maxi INT;      -- MapX ID
DECLARE v_maxis INT[];   -- MapX ID array

-- Wrong (conflicts with ModelX)
DECLARE v_mxi INT;       -- This is ModelX, not MapX!
```

### Self-Referential Columns

When a table references its own ID, use the table-specific pattern:

```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    p INT NOT NULL       -- Parent domain (references domainx.i)
);

-- In function
DECLARE v_p_dxi INT;     -- Parent domain ID variable
```

### Parent Arrays

For multiple parent references (composition patterns):

```sql
CREATE TABLE mx.modelx (
    i BIGINT PRIMARY KEY,
    p BIGINT[] NOT NULL DEFAULT '{}',  -- Parent model IDs (self-referential array)
    dxi INT NOT NULL
);

-- In function
DECLARE v_p BIGINT[];    -- Parent array uses simple 'p' column name
```

Note: `p` is a special system column for parent references and doesn't follow the `mxi/mxis` pattern.

---

## Variable Naming Examples

```sql
-- Domain references
DECLARE v_dxi INT;
DECLARE v_dxis INT[];

-- Table references  
DECLARE v_txi BIGINT;
DECLARE v_txis BIGINT[];

-- Model references
DECLARE v_mxi BIGINT;
DECLARE v_mxis BIGINT[];

-- Field references
DECLARE v_fxi BIGINT;
DECLARE v_fxis BIGINT[];

-- Query references
DECLARE v_qxi BIGINT;
DECLARE v_qxis BIGINT[];

-- Parameter references
DECLARE v_pxi BIGINT;
DECLARE v_pxis BIGINT[];
```

---

## Migration Note

AIX schemas currently use `di` instead of `dxi`. This is incorrect and requires migration:

**Current (incorrect):**
```sql
di INT NOT NULL  -- Wrong
```

**Correct (taxonomy compliant):**
```sql
dxi INT NOT NULL  -- Correct
```

All AIX schemas must be updated to follow the taxonomy pattern.

---

## TypeX Catalog References

**TypeX catalog entries** use a different pattern than MetaX table row references:

| Reference | Pattern | Usage |
|-----------|---------|-------|
| Column Type | ctx | References TypeX catalog (Group 5) |
| Data Type | dtx | References TypeX catalog (Group 3) |
| Field Type | ftx | References TypeX catalog (Group 7) |
| Parameter Type | ptx | References TypeX catalog (Group 6) |
| Table Type | ttx | References TypeX catalog (Group 1) |

**Pattern:** `[entity]tx` where entity is what's being typed (column, data, field, parameter, table).

**Example:**
```sql
CREATE TABLE mx.columnx (
    i BIGINT PRIMARY KEY,
    txi BIGINT NOT NULL,  -- References tablex.i (MetaX table row)
    ctx INT NOT NULL,     -- Column type (TypeX catalog entry)
    dtx INT NOT NULL      -- Data type (TypeX catalog entry)
);
```

**Note:** Use `tyxi/tyxis` when referencing the typex TABLE ROW itself (rare), and `ctx/dtx/ftx/ptx/ttx` when referencing a TYPE CATALOG ENTRY (common).
