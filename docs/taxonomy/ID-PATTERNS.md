# MetaX ID Patterns

**Source of Truth:** JCore taxonomy documentation  
**Purpose:** Define singular/plural ID patterns for all MetaX tables

---

## MetaX Table ID Patterns

| Table | Singular | Plural | Usage |
|-------|----------|--------|-------|
| DomainX | dxi | dxis | Domain ID references |
| TableX | txi | txis | Table ID references |
| ColumnX | cxi | cxis | Column ID references |
| ModelX | mxi | mxis | Model ID references |
| FieldX | fxi | fxis | Field ID references |
| QueryX | qxi | qxis | Query ID references |
| ParamX | pxi | pxis | Parameter ID references |
| SQLX | sxi | sxis | SQLX ID references |
| RelationX | rxi | rxis | Relation ID references |
| MapX | maxi | maxis | MapX ID references |

---

## Three-Level Naming Convention

The taxonomy uses a three-level naming system:

### 1. Database Column Level (Short Form)
```sql
-- Use short column names
di INT NOT NULL  -- Domain ID
ti INT NOT NULL  -- Table ID  
mi INT NOT NULL  -- Model ID
```

### 2. Variable Level (Taxonomy Pattern)
```sql
-- Use taxonomy pattern in code
DECLARE v_dxi INT;   -- Domain ID variable
DECLARE v_txi INT;   -- Table ID variable
DECLARE v_mxi INT;   -- Model ID variable
DECLARE v_dxis INT[];  -- Domain ID array
```

### 3. API Level (Descriptive)
```javascript
// Use descriptive names in APIs
{
  domainId: 1,       // or domain_id in snake_case
  tableId: 42,
  modelId: 100
}
```

---

## Pattern Rules

1. **Singular form** ends in `xi` (except MapX which uses `maxi`)
2. **Plural form** adds `s` to singular: `xis` or `maxis`
3. **Array types** always use plural form: `dxis INT[]`
4. **Variable prefix** is `v_` followed by taxonomy pattern
5. **API names** use full descriptive names (camelCase or snake_case)

---

## Examples

### Database Schema
```sql
CREATE TABLE mx.tablex (
    i INT PRIMARY KEY,
    di INT NOT NULL,     -- Short form: domain ID
    ti INT,              -- Short form: table ID (self-reference for parent)
    n TEXT NOT NULL
);
```

### SQL Function
```sql
CREATE FUNCTION settablex(input jsonb) RETURNS jsonb AS $$
DECLARE
    v_dxi INT;           -- Taxonomy pattern
    v_txi INT;           -- Taxonomy pattern
    v_mxis INT[];        -- Plural for array
BEGIN
    v_dxi := (input->>'di')::int;
    v_txi := (input->>'ti')::int;
    -- ...
END;
$$ LANGUAGE plpgsql;
```

### API Response
```json
{
  "tableId": 42,
  "domainId": 1,
  "modelIds": [100, 101, 102]
}
```

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
