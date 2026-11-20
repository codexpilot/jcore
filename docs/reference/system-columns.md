# System Columns Reference

**Version:** 2.0  
**Last Updated:** 2025-01-19

Complete reference for the 7 required system columns in generated tables.

---

## Overview

Generated tables require 7 system columns:
- `i` - ID (primary key)
- `d` - Date last edit (epoch milliseconds)
- `e` - Last editor (user ID)
- `a` - Active status (0 or 1)
- `n` - Name
- `s` - Status (workflow state)
- `v` - Version (optimistic locking)

---

## Column: i (ID)

**Data Type:** INTEGER, BIGINT, or TEXT  
**Constraint:** PRIMARY KEY  
**Nullable:** NOT NULL

**Format determined by table type:**
- Algorithm 1: Auto-increment `INTEGER GENERATED ALWAYS AS IDENTITY`
- Algorithm 2: BIGINT epoch-based
- Algorithm 0: Custom format

**Examples:**
```sql
-- Algorithm 1 (default)
i INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY

-- Algorithm 2
i BIGINT PRIMARY KEY

-- Algorithm 0
i TEXT PRIMARY KEY
```

**Best Practices:**
- Never manually set i when using Algorithm 1
- Use Algorithm 2 for distributed systems
- Algorithm 0 for legacy integration

---

## Column: d (Date Last Edit)

**Data Type:** BIGINT  
**Constraint:** NOT NULL  
**Format:** Epoch milliseconds UTC

**Value:** Milliseconds since Unix epoch (1970-01-01 00:00:00 UTC)

**Generation:**
```sql
d BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
```

**Usage:**
```sql
-- Set current time
UPDATE customer SET d = extract(epoch from now()) * 1000;

-- Convert to timestamp
SELECT to_timestamp(d / 1000.0) FROM customer;

-- Format for display
SELECT to_char(to_timestamp(d / 1000.0), 'YYYY-MM-DD HH24:MI:SS') FROM customer;

-- Filter by date range
SELECT * FROM customer 
WHERE d >= extract(epoch from '2025-01-01'::timestamp) * 1000
  AND d < extract(epoch from '2025-02-01'::timestamp) * 1000;
```

**Best Practices:**
- Always update d when modifying records
- Store in UTC, convert for display
- Use for audit trails

---

## Column: e (Last Editor)

**Data Type:** INTEGER  
**Constraint:** NOT NULL, REFERENCES aix.userx(i)  
**Format:** User ID foreign key

**Definition:**
```sql
e INTEGER NOT NULL REFERENCES aix.userx(i)
```

**Usage:**
```sql
-- Set editor
UPDATE customer SET e = current_user_id WHERE i = 123;

-- Query with editor name
SELECT c.*, u.n as editor_name
FROM customer c
JOIN aix.userx u ON c.e = u.i;

-- Audit trail
SELECT i, n, d, u.n as editor
FROM customer c
JOIN aix.userx u ON c.e = u.i
ORDER BY d DESC;
```

**Best Practices:**
- Always set e from authenticated user ID
- Use for audit trails
- Join with userx for display

---

## Column: a (Active Status)

**Data Type:** SMALLINT  
**Constraint:** NOT NULL, CHECK (a IN (0, 1))  
**Format:** Binary flag

**Values:**
- `0` = Inactive (soft deleted)
- `1` = Active

**Definition:**
```sql
a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0, 1))
```

**Usage:**
```sql
-- Query active records only
SELECT * FROM customer WHERE a = 1;

-- Soft delete
UPDATE customer SET a = 0, d = extract(epoch from now()) * 1000 WHERE i = 123;

-- Restore
UPDATE customer SET a = 1, d = extract(epoch from now()) * 1000 WHERE i = 123;

-- Include inactive in query
SELECT * FROM customer WHERE i = 123;  -- Don't filter by a

-- Count active vs inactive
SELECT 
    COUNT(*) FILTER (WHERE a = 1) as active_count,
    COUNT(*) FILTER (WHERE a = 0) as inactive_count
FROM customer;
```

**Best Practices:**
- Default to active (a = 1)
- NEVER hard delete records
- Filter by a = 1 in most queries
- Update d when changing a

**Common Mistakes:**
```sql
-- ✗ WRONG: Hard delete
DELETE FROM customer WHERE i = 123;

-- ✓ CORRECT: Soft delete
UPDATE customer SET a = 0 WHERE i = 123;
```

---

## Column: n (Name)

**Data Type:** TEXT  
**Constraint:** NOT NULL  
**Format:** Free-form text

**Definition:**
```sql
n TEXT NOT NULL
```

**Usage:**
```sql
-- Simple name
INSERT INTO customer (n, ...) VALUES ('John Doe', ...);

-- Search by name
SELECT * FROM customer WHERE n ILIKE '%john%' AND a = 1;

-- Order by name
SELECT * FROM customer WHERE a = 1 ORDER BY n;

-- Index for performance
CREATE INDEX idx_customer_name ON customer(n);
```

**Best Practices:**
- Always required
- Use for display purposes
- Index if frequently searched
- Store formatted name (e.g., "First Last")

---

## Column: s (Status)

**Data Type:** INTEGER  
**Constraint:** NOT NULL  
**Format:** Business workflow state

**Definition:**
```sql
s INTEGER NOT NULL DEFAULT 0
```

**Common Status Values:**
- `0` = Draft
- `1` = Pending
- `2` = Approved
- `3` = Rejected
- `4` = Completed
- `5` = Cancelled

**Usage:**
```sql
-- Set status
UPDATE customer SET s = 2, d = extract(epoch from now()) * 1000 WHERE i = 123;

-- Query by status
SELECT * FROM customer WHERE s = 2 AND a = 1;

-- Status transition
UPDATE customer 
SET s = 2, d = extract(epoch from now()) * 1000, v = v + 1
WHERE i = 123 AND s = 1;  -- Only transition from Pending

-- Map to names via TypeX
SELECT c.*, t.n as status_name
FROM customer c
LEFT JOIN aix.typex t ON c.s = t.i
WHERE c.a = 1;
```

**Best Practices:**
- Define status values in TypeX
- Document status transitions
- Use with workflow logic
- Index if frequently filtered

**Difference from 'a':**
- `a` = Binary visibility (active/inactive)
- `s` = Multi-state workflow status
- Both can be used together

---

## Column: v (Version)

**Data Type:** INTEGER  
**Constraint:** NOT NULL  
**Format:** Incremental counter

**Definition:**
```sql
v INTEGER NOT NULL DEFAULT 1
```

**Purpose:** Optimistic concurrency control

**Usage:**
```sql
-- Read record with version
SELECT i, n, s, v FROM customer WHERE i = 123;
-- Returns: i=123, n='John', s=2, v=5

-- Update with version check
UPDATE customer 
SET n = 'John Doe',
    d = extract(epoch from now()) * 1000,
    v = v + 1
WHERE i = 123 
  AND v = 5;  -- Only update if version matches

-- Check if update succeeded
GET DIAGNOSTICS updated_rows = ROW_COUNT;
IF updated_rows = 0 THEN
    RAISE EXCEPTION 'Record was modified by another user';
END IF;
```

**CRUD Function Pattern:**
```sql
CREATE FUNCTION setcustomer(p jsonb) RETURNS jsonb AS $$
DECLARE
    result jsonb;
BEGIN
    IF (p->>'i')::int = 0 THEN
        -- Insert: v starts at 1
        INSERT INTO customer (n, d, e, a, s, v)
        VALUES (
            p->>'n',
            extract(epoch from now()) * 1000,
            (p->>'e')::int,
            1,
            0,
            1
        )
        RETURNING row_to_json(customer.*) INTO result;
    ELSE
        -- Update: check version and increment
        UPDATE customer
        SET n = p->>'n',
            d = extract(epoch from now()) * 1000,
            v = v + 1
        WHERE i = (p->>'i')::int
          AND v = (p->>'v')::int
          AND a = 1
        RETURNING row_to_json(customer.*) INTO result;
        
        IF result IS NULL THEN
            RAISE EXCEPTION 'Version conflict or record not found';
        END IF;
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

**Best Practices:**
- Always include v in update operations
- Return v in query results
- Handle version conflicts gracefully
- Never skip version check in concurrent systems

---

## Complete Example

```sql
CREATE TABLE aix.customer (
    -- System columns
    i INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    d BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT,
    e INTEGER NOT NULL REFERENCES aix.userx(i),
    a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0, 1)),
    n TEXT NOT NULL,
    s INTEGER NOT NULL DEFAULT 0,
    v INTEGER NOT NULL DEFAULT 1,
    
    -- Business columns
    c1 TEXT UNIQUE NOT NULL,  -- Email
    c2 TEXT,                   -- Phone
    c3 INTEGER                 -- Category FK
);

-- Insert
INSERT INTO customer (n, e, c1, c2) VALUES
    ('John Doe', 1, 'john@example.com', '555-0100');
-- Returns: i=1, d=<current epoch>, e=1, a=1, n='John Doe', s=0, v=1

-- Update
UPDATE customer 
SET n = 'John Smith',
    c2 = '555-0200',
    d = extract(epoch from now()) * 1000,
    v = v + 1
WHERE i = 1 AND v = 1 AND a = 1;
-- New state: i=1, n='John Smith', v=2

-- Soft delete
UPDATE customer 
SET a = 0,
    d = extract(epoch from now()) * 1000
WHERE i = 1;

-- Query active
SELECT * FROM customer WHERE a = 1;

-- Audit query
SELECT 
    i,
    n,
    to_char(to_timestamp(d / 1000.0), 'YYYY-MM-DD HH24:MI:SS') as last_edit,
    u.n as editor,
    CASE a WHEN 1 THEN 'Active' ELSE 'Inactive' END as status_flag,
    CASE s 
        WHEN 0 THEN 'Draft'
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Approved'
        ELSE 'Unknown'
    END as workflow_status,
    v as version
FROM customer c
JOIN aix.userx u ON c.e = u.i
ORDER BY d DESC;
```

---

## System Column Summary Table

| Column | Type | Constraint | Purpose | Default |
|--------|------|------------|---------|---------|
| i | INT/BIGINT/TEXT | PRIMARY KEY, NOT NULL | Unique identifier | Auto/Generated |
| d | BIGINT | NOT NULL | Last edit timestamp | Current epoch ms |
| e | INTEGER | NOT NULL, FK userx(i) | Last editor | Current user |
| a | SMALLINT | NOT NULL, CHECK (0,1) | Active status | 1 (active) |
| n | TEXT | NOT NULL | Name/title | Required |
| s | INTEGER | NOT NULL | Workflow status | 0 (draft) |
| v | INTEGER | NOT NULL | Optimistic lock version | 1 |

---

**Related Documentation:**
- [MetaX Columns](../../db/reference/metax-columns.md)
- [Database Schema](../../db/reference/schema.md)
- [CRUD Patterns](../../db/reference/crud-patterns.md)
- [Best Practices](../../aix/guides/best-practices.md)
