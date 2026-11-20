# Table Types Reference

**Version:** 2.0  
**Last Updated:** 2025-01-19  
**Type Range:** 100000-199999  
**Encoding:** XXYYZZ Format

Table types define structure, ID generation, and behavior patterns for generated database tables.

---

## Encoding Structure

```
1XXYYZZ
 ││││││
 │││││└─ Reserved (00-99)
 ││││└── Reserved (00-99)
 │││└─── Format variation (00-99)
 ││└──── Primary format (00-99)
 │└───── Category (0-9)
 └────── Table type prefix (1)
```

---

## Core Table Types (100000-109999)

### 100001 - Standard Table
**Structure:** 7 system columns + business columns  
**ID Algorithm:** Auto-increment (Algorithm 1)

```sql
CREATE TABLE aix.tablename (
    i INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    d BIGINT NOT NULL,
    e INTEGER NOT NULL,
    a SMALLINT NOT NULL DEFAULT 1,
    n TEXT NOT NULL,
    s INTEGER NOT NULL DEFAULT 0,
    v INTEGER NOT NULL DEFAULT 1,
    -- Business columns follow
);
```

**Use cases:** Most business tables

### 100002 - Master Data Table
**Structure:** 7 system columns + code field  
**ID Algorithm:** Auto-increment

**Additional columns:**
- `c` - Immutable code field

**Use cases:** Reference data, lookup tables

### 100003 - Transaction Table
**Structure:** Standard + transaction metadata

**Additional columns:**
- `tx_date` - Transaction date
- `tx_type` - Transaction type

**Use cases:** Orders, invoices, payments

---

## Hierarchical Types (110000-119999)

### 110001 - Tree Table
**Structure:** Standard + parent reference

```sql
CREATE TABLE aix.category (
    i INTEGER PRIMARY KEY,
    -- ... system columns ...
    p INTEGER,  -- Parent ID (p = i for root)
    o INTEGER   -- Sort order
);
```

**Constraints:**
- `p = i` indicates root node
- `p != i` references parent
- Cyclic references prevented

### 110002 - Self-Referential Table
**Structure:** Standard + self-FK

**Use cases:** Organizational charts, BOMs

---

## Temporal Types (120000-129999)

### 120001 - Versioned Table
**Structure:** Standard + version tracking

**Features:**
- Full history preservation
- Point-in-time queries
- Audit trail

### 120002 - Soft-Delete Table
**Structure:** Standard (default behavior)

**Behavior:**
- `a = 0` for deleted
- Records never physically deleted

---

## Multi-Instance Types (130000-139999)

### 130001 - Domain-Partitioned Table
**Structure:** Standard + domain isolation

```sql
CREATE TABLE aix.customer (
    i INTEGER PRIMARY KEY,
    dx INTEGER NOT NULL REFERENCES aix.domainx(i),
    -- ... system columns ...
);

-- RLS policy
CREATE POLICY domain_isolation ON customer
USING (dx = current_setting('app.current_domain_id')::int);
```

**Use cases:** Multi-tenant systems

---

## Type Selection

**Standard business tables:** 100001  
**Reference/master data:** 100002  
**Hierarchical data:** 110001  
**Multi-tenant:** 130001

---

**Related Documentation:**
- [Data Types](DATA-TYPES.md)
- [Column Types](COLUMN-TYPES.md)
- [Model Types](MODEL-TYPES.md)
