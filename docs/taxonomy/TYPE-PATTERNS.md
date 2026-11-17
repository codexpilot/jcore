# TypeX Reference Patterns

**Source of Truth:** JCore taxonomy documentation  
**Purpose:** Define TypeX reference patterns (special rules for type references)

---

## Overview

TypeX references use **group-specific patterns** instead of the generic `txi` pattern. This distinguishes type references by their type group and avoids confusion with TableX IDs.

---

## Generic TypeX Pattern

When the specific group is unknown or mixed:

| Form | Pattern | Usage |
|------|---------|-------|
| Singular | tx | Generic type reference |
| Plural | txs | Generic type array |

**Example:**
```sql
DECLARE v_tx INT;        -- Generic type ID
DECLARE v_txs INT[];     -- Generic type array
```

---

## Group-Specific Patterns

Each TypeX group has its own pattern to distinguish the reference context:

| TypeX Group | Singular | Plural | Description |
|-------------|----------|--------|-------------|
| Group 3 | dtx | dtxs | Data type (for ColumnX) |
| Group 4 | ttx | ttxs | Table type (for TableX) |
| Group 5 | ctx | ctxs | Column type (for ColumnX) |
| Group 6 | mtx | mtxs | Model type (for ModelX) |
| Group 7 | ftx | ftxs | Field type (for FieldX) |
| Group 8 | qtx | qtxs | Query type (for QueryX) |
| Group 9 | ptx | ptxs | Parameter type (for ParamX) |
| SQLX | sqtx | sqtxs | SQLX type (for SQLX) |

---

## Why Group-Specific Patterns?

Using `txi/txis` for type references would be confusing:
- `txi` could mean "TableX ID" (table reference)
- `txi` could mean "TypeX ID" (type reference)

Group-specific patterns solve this:
- `txi` = TableX ID reference
- `dtx` = Data type ID reference (TypeX group 3)
- `ttx` = Table type ID reference (TypeX group 4)

---

## Pattern Rules

1. **Column names** use the taxonomy pattern: `dtx`, `ttx`, `ctx`, `mtx`, `ftx`
2. **Variable names** add `v_` prefix: `v_dtx`, `v_ttx`, `v_ctx`, `v_mtx`, `v_ftx`
3. **Plural forms** add `s`: `dtxs`, `ttxs`, `ctxs`, `mtxs`, `ftxs`
4. **SQLX** is a special case using `sqtx` (not just `sx`)
5. **JSON keys** use the taxonomy pattern: `"dtx"`, `"ttx"`, `"ctx"`, etc.

---

## Examples

### Database Schema

```sql
-- TableX has a table type
CREATE TABLE mx.tablex (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i),
    ttx INT NOT NULL REFERENCES cox.typex(i),  -- Table type
    n TEXT NOT NULL
);

-- ColumnX has both data type and column type
CREATE TABLE mx.columnx (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i),
    txi BIGINT NOT NULL,                       -- Parent table reference
    dtx INT NOT NULL REFERENCES cox.typex(i),  -- Data type
    ctx INT NOT NULL REFERENCES cox.typex(i),  -- Column type
    n TEXT NOT NULL
);

-- ModelX has model type
CREATE TABLE mx.modelx (
    i BIGINT PRIMARY KEY,
    dxi INT NOT NULL REFERENCES mx.domainx(i),
    mtx INT NOT NULL REFERENCES cox.typex(i),  -- Model type
    n TEXT NOT NULL
);
```

### SQL Function Variables

```sql
CREATE FUNCTION settablex(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_dxi INT;
    v_ttx INT;                 -- Table type variable
BEGIN
    v_dxi := (input->>'dxi')::int;
    v_ttx := (input->>'ttx')::int;
    
    -- Validate v_ttx is in TypeX group 4
    IF NOT EXISTS (
        SELECT 1 FROM cox.typex 
        WHERE i = v_ttx AND g = 4
    ) THEN
        RAISE EXCEPTION 'Invalid table type: % must be in TypeX group 4', v_ttx;
    END IF;
    
    INSERT INTO mx.tablex (i, dxi, ttx, n)
    VALUES (v_i, v_dxi, v_ttx, v_n)
    RETURNING *;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION setcolumnx(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_dxi INT;
    v_txi BIGINT;
    v_dtx INT;                 -- Data type variable
    v_ctx INT;                 -- Column type variable
BEGIN
    v_dxi := (input->>'dxi')::int;
    v_txi := (input->>'txi')::bigint;
    v_dtx := (input->>'dtx')::int;
    v_ctx := (input->>'ctx')::int;
    
    -- Validate v_dtx is in group 3, v_ctx in group 5
    IF NOT EXISTS (SELECT 1 FROM cox.typex WHERE i = v_dtx AND g = 3) THEN
        RAISE EXCEPTION 'Invalid data type: % must be in TypeX group 3', v_dtx;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM cox.typex WHERE i = v_ctx AND g = 5) THEN
        RAISE EXCEPTION 'Invalid column type: % must be in TypeX group 5', v_ctx;
    END IF;
    
    INSERT INTO mx.columnx (i, dxi, txi, dtx, ctx, n)
    VALUES (v_i, v_dxi, v_txi, v_dtx, v_ctx, v_n)
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
  "ttx": 400001,
  "dtx": 300007,
  "ctx": 500002,
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
  "tableType": 400001,
  "dataType": 300007,
  "columnType": 500002
}
```

The API layer translates between descriptive names and taxonomy patterns.

---

## Complete Mapping

### From Schema to API

| Schema Column | Variable | JSON Key | API Field | TypeX Group |
|---------------|----------|----------|-----------|-------------|
| dtx | v_dtx | "dtx" | dataType | 3 |
| ttx | v_ttx | "ttx" | tableType | 4 |
| ctx | v_ctx | "ctx" | columnType | 5 |
| mtx | v_mtx | "mtx" | modelType | 6 |
| ftx | v_ftx | "ftx" | fieldType | 7 |
| qtx | v_qtx | "qtx" | queryType | 8 |
| ptx | v_ptx | "ptx" | paramType | 9 |
| sqtx | v_sqtx | "sqtx" | sqlType | (SQLX) |

---

## Validation Pattern

When validating type references, use the group-specific variable names:

```sql
-- Validate data type is in correct group
IF NOT EXISTS (
    SELECT 1 FROM cox.typex 
    WHERE i = v_dtx AND g = 3
) THEN
    RAISE EXCEPTION 'Invalid data type: % must be in TypeX group 3', v_dtx;
END IF;

-- Validate table type
IF NOT EXISTS (
    SELECT 1 FROM cox.typex 
    WHERE i = v_ttx AND g = 4
) THEN
    RAISE EXCEPTION 'Invalid table type: % must be in TypeX group 4', v_ttx;
END IF;
```

---

## Migration Note

AIX schemas currently use `dt`, `tt`, `ct`, `mt`, `ft` instead of `dtx`, `ttx`, `ctx`, `mtx`, `ftx`. This is incorrect and requires migration:

**Current (incorrect):**
```sql
dt INT NOT NULL  -- Wrong
tt INT NOT NULL  -- Wrong
ct INT NOT NULL  -- Wrong
```

**Correct (taxonomy compliant):**
```sql
dtx INT NOT NULL  -- Correct
ttx INT NOT NULL  -- Correct
ctx INT NOT NULL  -- Correct
```

All AIX schemas must be updated to follow the taxonomy pattern.

---

## Summary

- **Generic:** Use `tx/txs` when type group is unknown or mixed
- **Specific:** Use group pattern (`dtx`, `ttx`, `ctx`, etc.) for type references
- **Never:** Use `txi/txis` for TypeX references (conflicts with TableX)
- **Always:** Match the pattern to the TypeX group being referenced
- **Consistency:** Use the same pattern in columns, variables, and JSON keys
