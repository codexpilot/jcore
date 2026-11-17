# DomainX Special Columns (i_dxis and c_dxis)

**Source of Truth:** JCore taxonomy documentation  
**Purpose:** Define DomainX provenance tracking columns

---

## Overview

DomainX has two special array columns that appear to violate the p/ps self-referential rule but serve a different purpose:

- **i_dxis** - Imported domain IDs (provenance tracking)
- **c_dxis** - Copied domain IDs (provenance tracking)

These are **NOT parent columns**. They track the lineage of domain metadata but do not define hierarchical relationships.

---

## Column Definitions

### i_dxis (Imported Domain IDs)

**Purpose:** Track which domains this domain imported metadata FROM (as-is, no modifications)

**Type:** `INT[]`

**Rules:**
- Contains IDs of template domains (-1002, -1003, etc.)
- Records pure imports where metadata was taken without changes
- Can reference any domain (not restricted to same table like ps)
- Used for provenance auditing and conflict detection

**Example:**
```sql
-- Solution domain that imported from two templates
INSERT INTO mx.domainx (i, p, n, c, i_dxis) VALUES
(1, -1, 'My Solution', 'my-solution', '{-1001, -1002}');
--                                      ^^^^^^^^^^^^^
--                                      Imported from templates -1001 and -1002
```

### c_dxis (Copied Domain IDs)

**Purpose:** Track which domains this domain copied AND MODIFIED metadata FROM

**Type:** `INT[]`

**Rules:**
- Contains IDs of domains where metadata was copied then changed
- Can include both template domains and solution domains
- Records attribution when metadata was forked/customized
- Cannot include the domain's own ID (self-copy is invalid)

**Example:**
```sql
-- Solution domain that copied and customized from template and another solution
INSERT INTO mx.domainx (i, p, n, c, c_dxis) VALUES
(2, -1, 'My Solution 2', 'my-solution-2', '{-1001, 1}');
--                                         ^^^^^^^^^^^^
--                                         Copied from template -1001 and solution 1
```

---

## Why These Aren't p/ps Columns

| Aspect | p/ps (Parent) | i_dxis/c_dxis (Provenance) |
|--------|---------------|----------------------------|
| **Purpose** | Hierarchical structure | Metadata lineage tracking |
| **Semantic** | "Parent-child relationship" | "Derived from / based on" |
| **Query pattern** | Recursive tree traversal | Flat provenance audit |
| **Self-reference** | Root indicator (p = i) | Invalid (cannot import/copy self) |
| **Naming** | Standard p/ps pattern | Domain-specific i_dxis/c_dxis |
| **Constraint** | Self-referential only | Can reference any domain |

The `p` column in DomainX is still the hierarchical parent and must be self-referential.

---

## Schema Definition

```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    d BIGINT NOT NULL,
    e INT NOT NULL,
    a SMALLINT NOT NULL DEFAULT 1,
    n TEXT NOT NULL,
    c TEXT NOT NULL UNIQUE,
    p INT NOT NULL,              -- Hierarchical parent (self-referential)
    i_dxis INT[] DEFAULT '{}',   -- Imported domain IDs (provenance)
    c_dxis INT[] DEFAULT '{}',   -- Copied domain IDs (provenance)
    -- ... other columns
    FOREIGN KEY (p) REFERENCES mx.domainx(i)
    -- Note: i_dxis and c_dxis have NO foreign key constraint
    --       because they may reference domains in other systems
);
```

---

## Column Naming Convention

The columns follow the taxonomy pattern:

- **i_dxis** = "imported domain IDs" (plural of dxi)
- **c_dxis** = "copied domain IDs" (plural of dxi)

Note the underscore separating the action prefix (i, c) from the taxonomy pattern (dxis).

**Pattern:** `[action]_[taxonomy_plural]`

This distinguishes them from:
- Regular columns: `di` (domain ID foreign key)
- Taxonomy variables: `v_dxi` (domain ID variable)
- Parent columns: `p` or `ps` (hierarchical relationships)

---

## Domain ID Ranges

DomainX uses different ID ranges for different purposes:

| Range | Purpose | i_dxis | c_dxis |
|-------|---------|--------|--------|
| -1000 to -1 | Root domains | ✗ Never | ✗ Never |
| -1001 to -∞ | Template domains | ✓ Source | ✓ Source |
| 1 to +∞ | Solution domains | ✗ Invalid | ✓ Valid |

**Rules:**
1. i_dxis can only contain template IDs (< -1000)
2. c_dxis can contain template IDs or solution IDs (< -1000 or > 0)
3. Neither can contain root IDs (-1000 to -1)
4. Neither can contain the domain's own ID

---

## Validation Rules

### i_dxis Validation
```sql
-- In setdomainx function
IF array_length(v_i_dxis, 1) > 0 THEN
    -- Must only contain template domains (< -1000)
    IF EXISTS (SELECT 1 FROM unnest(v_i_dxis) AS id WHERE id >= -1000) THEN
        RAISE EXCEPTION 'i_dxis can only contain template domain IDs (< -1000)';
    END IF;
    
    -- Cannot contain duplicates
    IF (SELECT COUNT(*) FROM unnest(v_i_dxis)) > 
       (SELECT COUNT(DISTINCT id) FROM unnest(v_i_dxis) AS id) THEN
        RAISE EXCEPTION 'i_dxis contains duplicate domain IDs';
    END IF;
END IF;
```

### c_dxis Validation
```sql
-- In setdomainx function
IF array_length(v_c_dxis, 1) > 0 THEN
    -- Cannot contain root domains (-1000 to -1)
    IF EXISTS (SELECT 1 FROM unnest(v_c_dxis) AS id WHERE id BETWEEN -1000 AND -1) THEN
        RAISE EXCEPTION 'c_dxis cannot contain root domain IDs (-1000 to -1)';
    END IF;
    
    -- Cannot contain self
    IF v_i = ANY(v_c_dxis) THEN
        RAISE EXCEPTION 'c_dxis cannot contain its own domain ID';
    END IF;
    
    -- Cannot contain duplicates
    IF (SELECT COUNT(*) FROM unnest(v_c_dxis)) > 
       (SELECT COUNT(DISTINCT id) FROM unnest(v_c_dxis) AS id) THEN
        RAISE EXCEPTION 'c_dxis contains duplicate domain IDs';
    END IF;
END IF;
```

---

## Usage Examples

### Creating Domain with Provenance
```sql
-- Template domain (no provenance)
INSERT INTO mx.domainx (i, p, n, c, i_dxis, c_dxis) VALUES
(-1001, -1, 'CRM Template', 'crm-template', '{}', '{}');

-- Solution importing from template
INSERT INTO mx.domainx (i, p, n, c, i_dxis, c_dxis) VALUES
(1, -1, 'Acme CRM', 'acme-crm', '{-1001}', '{}');
--                                ^^^^^^^^
--                                Pure import from CRM template

-- Solution copying and customizing from template
INSERT INTO mx.domainx (i, p, n, c, i_dxis, c_dxis) VALUES
(2, -1, 'Beta CRM', 'beta-crm', '{}', '{-1001}');
--                                     ^^^^^^^^
--                                     Copied and modified from CRM template

-- Solution mixing import and copy from multiple sources
INSERT INTO mx.domainx (i, p, n, c, i_dxis, c_dxis) VALUES
(3, -1, 'Gamma CRM', 'gamma-crm', '{-1001}', '{-1002, 2}');
--                                 ^^^^^^^^   ^^^^^^^^^^^
--                                 Imported   Copied from template and solution
```

### Updating Provenance
```sql
-- Add imported domain after creation
UPDATE mx.domainx 
SET i_dxis = array_append(i_dxis, -1003)
WHERE i = 1;

-- Add copied domain after creation
UPDATE mx.domainx 
SET c_dxis = array_append(c_dxis, 5)
WHERE i = 2;

-- Using setdomainx function
SELECT setdomainx('{"i":1,"i_dxis":[-1001,-1003]}'::jsonb);
SELECT setdomainx('{"i":2,"c_dxis":[-1001,5]}'::jsonb);
```

### Querying Provenance
```sql
-- Find all domains that imported from a specific template
SELECT i, n, c FROM mx.domainx
WHERE -1001 = ANY(i_dxis);

-- Find all domains that copied from a specific domain
SELECT i, n, c FROM mx.domainx
WHERE 2 = ANY(c_dxis);

-- Find domains with any provenance
SELECT i, n, c, 
       array_length(i_dxis, 1) AS import_count,
       array_length(c_dxis, 1) AS copy_count
FROM mx.domainx
WHERE array_length(i_dxis, 1) > 0 
   OR array_length(c_dxis, 1) > 0;

-- Get full provenance chain
SELECT d.i, d.n,
       (SELECT array_agg(n) FROM mx.domainx WHERE i = ANY(d.i_dxis)) AS imported_from,
       (SELECT array_agg(n) FROM mx.domainx WHERE i = ANY(d.c_dxis)) AS copied_from
FROM mx.domainx d
WHERE d.i = 3;
```

---

## API Field Mapping

### JSON Payload
```json
{
  "id": 1,
  "name": "My Solution",
  "code": "my-solution",
  "parentId": -1,
  "importedDomainIds": [-1001, -1002],
  "copiedDomainIds": [-1003, 5]
}
```

### Database to API Mapping
| Database Column | API Field | Type |
|----------------|-----------|------|
| i | id | number |
| n | name | string |
| c | code | string |
| p | parentId | number |
| i_dxis | importedDomainIds | number[] |
| c_dxis | copiedDomainIds | number[] |

---

## Common Mistakes

### ❌ WRONG: Treating as Parent Columns
```sql
-- Don't use i_dxis/c_dxis for hierarchy
SELECT * FROM mx.domainx WHERE p = ANY(i_dxis);  -- WRONG!
```

### ✓ CORRECT: Use p for Hierarchy
```sql
-- Use p column for hierarchical queries
SELECT * FROM mx.domainx WHERE p = 1;  -- CORRECT
```

### ❌ WRONG: Self-Reference in c_dxis
```sql
-- Cannot copy from self
UPDATE mx.domainx SET c_dxis = '{1}' WHERE i = 1;  -- INVALID!
```

### ✓ CORRECT: Reference Other Domains
```sql
-- Copy from different domain
UPDATE mx.domainx SET c_dxis = '{2}' WHERE i = 1;  -- VALID
```

### ❌ WRONG: Solution ID in i_dxis
```sql
-- i_dxis only accepts template IDs (< -1000)
UPDATE mx.domainx SET i_dxis = '{1}' WHERE i = 2;  -- INVALID!
```

### ✓ CORRECT: Template IDs Only
```sql
-- Only template domains in i_dxis
UPDATE mx.domainx SET i_dxis = '{-1001}' WHERE i = 2;  -- VALID
```

---

## Summary

1. **i_dxis** tracks imported (unchanged) metadata from templates
2. **c_dxis** tracks copied (modified) metadata from any domain
3. **NOT parent columns** - they track provenance, not hierarchy
4. **p column** is still the self-referential parent for structure
5. **Naming follows** `[action]_[taxonomy_plural]` pattern
6. **Validation enforces** proper ID ranges and no self-references
7. **Use cases:** provenance auditing, conflict detection, attribution
