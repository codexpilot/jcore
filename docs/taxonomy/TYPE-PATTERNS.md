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

| TypeX Group | Column | Singular | Plural | Description |
|-------------|--------|----------|--------|-------------|
| Group 3 | dt | dtx | dtxs | Data type (for ColumnX) |
| Group 4 | tt | ttx | ttxs | Table type (for TableX) |
| Group 5 | ct | ctx | ctxs | Column type (for ColumnX) |
| Group 6 | mt | mtx | mtxs | Model type (for ModelX) |
| Group 7 | ft | ftx | ftxs | Field type (for FieldX) |
| Group 8 | qt | qtx | qtxs | Query type (for QueryX) |
| Group 9 | pt | ptx | ptxs | Parameter type (for ParamX) |
| SQLX | - | sqtx | sqtxs | SQLX type (for SQLX) |

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

1. **Column names** use the two-letter abbreviation: `dt`, `tt`, `ct`, etc.
2. **Variable names** append `x` to the column abbreviation: `v_dtx`, `v_ttx`, etc.
3. **Plural forms** add `s`: `dtxs`, `ttxs`, `ctxs`, etc.
4. **SQLX** is a special case using `sqtx` (not just `sx`)

---

## Examples

### Database Schema
```sql
-- TableX has a table type
CREATE TABLE mx.tablex (
    i INT PRIMARY KEY,
    tt INT NOT NULL,           -- Column: table type
    FOREIGN KEY (tt) REFERENCES mx.typex(i)
);

-- ColumnX has both data type and column type
CREATE TABLE mx.columnx (
    i INT PRIMARY KEY,
    dt INT NOT NULL,           -- Column: data type
    ct INT,                    -- Column: column type
    FOREIGN KEY (dt) REFERENCES mx.typex(i),
    FOREIGN KEY (ct) REFERENCES mx.typex(i)
);
```

### SQL Function Variables
```sql
CREATE FUNCTION settablex(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_ttx INT;                 -- Table type variable
BEGIN
    v_ttx := (input->>'tt')::int;
    -- Validate v_ttx is in TypeX group 4
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION setcolumnx(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_dtx INT;                 -- Data type variable
    v_ctx INT;                 -- Column type variable
BEGIN
    v_dtx := (input->>'dt')::int;
    v_ctx := (input->>'ct')::int;
    -- Validate v_dtx is in group 3, v_ctx in group 5
END;
$$ LANGUAGE plpgsql;
```

### API Response
```json
{
  "tableId": 42,
  "tableType": 400001,
  "dataType": 300007,
  "columnType": 500002
}
```

### Code Comments
```sql
-- Good: Clear what type of type this is
v_dtx INT;     -- Data type ID from TypeX group 3
v_ttx INT;     -- Table type ID from TypeX group 4

-- Confusing: What kind of type?
v_txi INT;     -- TableX ID? TypeX ID? Which group?
```

---

## Complete Mapping

### From Column to API

| Column | Variable | API Field | TypeX Group |
|--------|----------|-----------|-------------|
| dt | v_dtx | dataType | 3 |
| tt | v_ttx | tableType | 4 |
| ct | v_ctx | columnType | 5 |
| mt | v_mtx | modelType | 6 |
| ft | v_ftx | fieldType | 7 |
| qt | v_qtx | queryType | 8 |
| pt | v_ptx | paramType | 9 |
| - | v_sqtx | sqlType | (SQLX) |

---

## Validation Pattern

When validating type references, use the group-specific variable names:

```sql
-- Validate data type is in correct group
IF NOT EXISTS (
    SELECT 1 FROM mx.typex 
    WHERE i = v_dtx AND g = 3
) THEN
    RAISE EXCEPTION 'Invalid data type: % must be in TypeX group 3', v_dtx;
END IF;

-- Validate table type
IF NOT EXISTS (
    SELECT 1 FROM mx.typex 
    WHERE i = v_ttx AND g = 4
) THEN
    RAISE EXCEPTION 'Invalid table type: % must be in TypeX group 4', v_ttx;
END IF;
```

---

## Summary

- **Generic:** Use `tx/txs` when type group is unknown or mixed
- **Specific:** Use group pattern (`dtx`, `ttx`, `ctx`, etc.) for type references
- **Never:** Use `txi/txis` for TypeX references (conflicts with TableX)
- **Always:** Match the pattern to the TypeX group being referenced
