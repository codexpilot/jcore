# Parent Column Rules (p/ps)

**Source of Truth:** JCore taxonomy documentation  
**Purpose:** Define architectural rules for parent columns (self-referential constraint)

---

## Architectural Rule

**p and ps columns MUST be self-referential ONLY.**

This means:
- p/ps columns can ONLY reference the same table's `i` column
- p/ps columns can NEVER reference another table's ID
- Cross-table relationships must use other patterns (foreign keys, junction tables)

---

## p (Parent - Singular)

### Definition
References the parent record within the SAME table for hierarchical structures.

### Rules
1. MUST reference same table's `i` column
2. NEVER reference another table's ID
3. Self-reference (p = i) indicates root record
4. Type must match table's `i` column type
5. Used for single-parent hierarchies

### Schema Pattern
```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    p INT NOT NULL,
    -- p references domainx.i (same table)
    FOREIGN KEY (p) REFERENCES mx.domainx(i)
);
```

### Root Record Pattern
Root records reference themselves:
```sql
-- Root domain
INSERT INTO mx.domainx (i, p, n, c) 
VALUES (-1, -1, 'AIX Framework Root', 'aix-root');
--      ^   ^
--      |   |
--      |   Parent = self (root indicator)
--      Identity

-- Child domain
INSERT INTO mx.domainx (i, p, n, c) 
VALUES (1, -1, 'My Solution', 'my-solution');
--      ^  ^
--      |  |
--      |  Parent = -1 (references root)
--      Identity
```

### Query Pattern
```sql
-- Find all children of a domain
SELECT * FROM mx.domainx 
WHERE p = 1 AND p <> i;  -- p <> i excludes root

-- Find root domains
SELECT * FROM mx.domainx 
WHERE p = i;

-- Recursive query for entire tree
WITH RECURSIVE domain_tree AS (
    SELECT i, p, n, 0 AS level
    FROM mx.domainx
    WHERE i = -1  -- Start from root
    
    UNION ALL
    
    SELECT d.i, d.p, d.n, dt.level + 1
    FROM mx.domainx d
    INNER JOIN domain_tree dt ON d.p = dt.i
    WHERE d.p <> d.i  -- Exclude self-references
)
SELECT * FROM domain_tree ORDER BY level, i;
```

---

## ps (Parents - Plural Array)

### Definition
Array of parent record IDs within the SAME table for multi-parent hierarchies.

### Rules
1. Array elements MUST all reference same table's `i` column
2. NEVER mix references to different tables
3. Empty array allowed for root or orphan records
4. Used for directed acyclic graphs (DAGs)

### Schema Pattern
```sql
CREATE TABLE mx.categoryx (
    i INT PRIMARY KEY,
    ps INT[] NOT NULL DEFAULT '{}',
    n TEXT NOT NULL
);

-- Add constraint to validate self-referential
CREATE OR REPLACE FUNCTION validate_ps_self_referential()
RETURNS TRIGGER AS $$
BEGIN
    IF array_length(NEW.ps, 1) > 0 THEN
        IF NOT (SELECT bool_and(EXISTS(
            SELECT 1 FROM mx.categoryx WHERE i = parent_id
        )) FROM unnest(NEW.ps) AS parent_id) THEN
            RAISE EXCEPTION 'All ps elements must reference existing records in the same table';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_categoryx_ps
BEFORE INSERT OR UPDATE ON mx.categoryx
FOR EACH ROW EXECUTE FUNCTION validate_ps_self_referential();
```

### Multi-Parent Example
```sql
-- Root categories (no parents)
INSERT INTO mx.categoryx (i, ps, n) VALUES 
(1, '{}', 'Products'),
(2, '{}', 'Services');

-- Child with single parent
INSERT INTO mx.categoryx (i, ps, n) VALUES 
(3, '{1}', 'Electronics');

-- Child with multiple parents (cross-categorization)
INSERT INTO mx.categoryx (i, ps, n) VALUES 
(4, '{1,2}', 'Software Licenses');
--     ^  ^
--     |  |
--     |  Also under Services
--     Under Products
```

### Query Pattern
```sql
-- Find all direct parents of a category
SELECT p.* FROM mx.categoryx c
CROSS JOIN unnest(c.ps) AS parent_id
INNER JOIN mx.categoryx p ON p.i = parent_id
WHERE c.i = 4;

-- Find all children of a category
SELECT c.* FROM mx.categoryx c
WHERE 1 = ANY(c.ps);

-- Check if category has specific parent
SELECT * FROM mx.categoryx
WHERE i = 4 AND 1 = ANY(ps);
```

---

## Violations and Solutions

### ❌ VIOLATION: Cross-Table Reference
```sql
-- WRONG: p/ps referencing another table
CREATE TABLE app.employees (
    i INT PRIMARY KEY,
    p INT,  -- References departments.i (VIOLATION!)
    n TEXT
);

CREATE TABLE app.departments (
    i INT PRIMARY KEY,
    n TEXT
);
```

### ✓ SOLUTION: Use Standard Foreign Key
```sql
-- CORRECT: Use foreign key column for cross-table reference
CREATE TABLE app.employees (
    i INT PRIMARY KEY,
    department_id INT,  -- Standard foreign key
    n TEXT,
    FOREIGN KEY (department_id) REFERENCES app.departments(i)
);

CREATE TABLE app.departments (
    i INT PRIMARY KEY,
    p INT,  -- Self-referential for department hierarchy
    n TEXT,
    FOREIGN KEY (p) REFERENCES app.departments(i)
);
```

### ❌ VIOLATION: Mixed References in ps
```sql
-- WRONG: ps mixing references to different tables
CREATE TABLE app.items (
    i INT PRIMARY KEY,
    ps INT[],  -- Contains both category IDs and tag IDs (VIOLATION!)
    n TEXT
);
```

### ✓ SOLUTION: Use MapX Junction Table
```sql
-- CORRECT: Separate relationships via MapX
CREATE TABLE app.items (
    i INT PRIMARY KEY,
    n TEXT
);

CREATE TABLE app.categories (
    i INT PRIMARY KEY,
    n TEXT
);

CREATE TABLE app.tags (
    i INT PRIMARY KEY,
    n TEXT
);

-- Junction table for item-category relationships
CREATE TABLE app.item_categories (
    item_id INT,
    category_id INT,
    PRIMARY KEY (item_id, category_id),
    FOREIGN KEY (item_id) REFERENCES app.items(i),
    FOREIGN KEY (category_id) REFERENCES app.categories(i)
);

-- Junction table for item-tag relationships
CREATE TABLE app.item_tags (
    item_id INT,
    tag_id INT,
    PRIMARY KEY (item_id, tag_id),
    FOREIGN KEY (item_id) REFERENCES app.items(i),
    FOREIGN KEY (tag_id) REFERENCES app.tags(i)
);
```

---

## Compliant Examples

### Single-Parent Hierarchy (p)
```sql
-- Organization structure
CREATE TABLE app.org_units (
    i INT PRIMARY KEY,
    p INT NOT NULL,
    n TEXT NOT NULL,
    FOREIGN KEY (p) REFERENCES app.org_units(i)
);

-- Root: Company
INSERT INTO app.org_units (i, p, n) VALUES (1, 1, 'ACME Corp');

-- Level 1: Divisions
INSERT INTO app.org_units (i, p, n) VALUES 
(2, 1, 'Engineering'),
(3, 1, 'Sales');

-- Level 2: Departments
INSERT INTO app.org_units (i, p, n) VALUES 
(4, 2, 'Backend Team'),
(5, 2, 'Frontend Team'),
(6, 3, 'East Region'),
(7, 3, 'West Region');
```

### Multi-Parent DAG (ps)
```sql
-- Skill taxonomy with cross-references
CREATE TABLE app.skills (
    i INT PRIMARY KEY,
    ps INT[] NOT NULL DEFAULT '{}',
    n TEXT NOT NULL
);

-- Root skills (no prerequisites)
INSERT INTO app.skills (i, ps, n) VALUES 
(1, '{}', 'Programming Basics'),
(2, '{}', 'Database Basics');

-- Intermediate skills
INSERT INTO app.skills (i, ps, n) VALUES 
(3, '{1}', 'Object-Oriented Programming'),
(4, '{2}', 'SQL Fundamentals');

-- Advanced skill requiring multiple prerequisites
INSERT INTO app.skills (i, ps, n) VALUES 
(5, '{3,4}', 'Full-Stack Web Development');
```

---

## DomainX Special Case: i_dxis and c_dxis

DomainX has special columns that look like they violate the rule but don't:

```sql
CREATE TABLE mx.domainx (
    i INT PRIMARY KEY,
    p INT NOT NULL,       -- Self-referential (parent domain)
    i_dxis INT[],         -- Imported domain IDs (provenance tracking)
    c_dxis INT[],         -- Copied domain IDs (provenance tracking)
    FOREIGN KEY (p) REFERENCES mx.domainx(i)
);
```

**Why i_dxis/c_dxis are OK:**
- They are NOT parent columns (not named p or ps)
- They track provenance (where this domain came from)
- They reference DomainX IDs but for different semantic purpose
- The `p` column is still the only hierarchical parent reference

**See:** DOMAINX-SPECIAL.md for full details on i_dxis and c_dxis

---

## Validation Patterns

### Validate p References Same Table
```sql
CREATE OR REPLACE FUNCTION validate_p_self_referential()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.p IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM [table_name] WHERE i = NEW.p) THEN
            RAISE EXCEPTION 'Parent p=% does not exist in same table', NEW.p;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Validate ps Array Elements
```sql
CREATE OR REPLACE FUNCTION validate_ps_self_referential()
RETURNS TRIGGER AS $$
DECLARE
    parent_id INT;
BEGIN
    IF array_length(NEW.ps, 1) > 0 THEN
        FOREACH parent_id IN ARRAY NEW.ps LOOP
            IF NOT EXISTS (SELECT 1 FROM [table_name] WHERE i = parent_id) THEN
                RAISE EXCEPTION 'Parent ps element % does not exist in same table', parent_id;
            END IF;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### Prevent Circular References (p)
```sql
CREATE OR REPLACE FUNCTION prevent_circular_parent()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.i = NEW.p AND NEW.p IS NOT NULL THEN
        -- Self-reference is OK (indicates root)
        RETURN NEW;
    END IF;
    
    -- Check for cycles using recursive query
    IF EXISTS (
        WITH RECURSIVE ancestors AS (
            SELECT p AS ancestor FROM [table_name] WHERE i = NEW.i
            UNION
            SELECT t.p FROM [table_name] t
            INNER JOIN ancestors a ON t.i = a.ancestor
            WHERE t.i <> t.p
        )
        SELECT 1 FROM ancestors WHERE ancestor = NEW.i
    ) THEN
        RAISE EXCEPTION 'Circular parent reference detected';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## Summary

1. **p column:** Self-referential ONLY, single-parent hierarchy
2. **ps column:** Self-referential array ONLY, multi-parent DAG
3. **Root records:** Set p = i (self-reference)
4. **Cross-table:** Use standard foreign keys, NOT p/ps
5. **Many-to-many:** Use MapX junction tables, NOT ps
6. **Validation:** Enforce self-referential constraint with triggers
7. **Exception:** i_dxis/c_dxis in DomainX are provenance tracking, not parent columns
