# Column Types Reference

**Version:** 2.0  
**Last Updated:** 2025-01-19  
**Type Range:** 200000-299999  
**Encoding:** XYZ (X=nullable, Y=precision, Z=scale)

Column types define the structure and constraints of database columns in the AIX platform.

---

## Overview

Column types in the 200000-299999 range specify:
- Base data type
- Nullability constraints
- Precision and scale
- Default values
- Validation rules

### Encoding Structure: XYZ

```
200XYZ
  │││
  ││└─ Z: Scale/decimal places (0-9)
  │└── Y: Precision/size category (0-9)
  └─── X: Nullability (0=NOT NULL, 1=nullable)
```

**Examples:**
- `200001` = NOT NULL, standard precision, no scale
- `201001` = Nullable, standard precision, no scale
- `200832` = NOT NULL, precision=8, scale=2

---

## Base Column Types

### Text Column Types (200000-200099)

#### 200001 - TEXT NOT NULL
```sql
-- Standard text column, required
ALTER TABLE tablename ADD COLUMN colname TEXT NOT NULL;
```

**Use cases:**
- Required name fields
- Mandatory codes
- Non-empty descriptions

#### 201001 - TEXT NULLABLE
```sql
-- Optional text column
ALTER TABLE tablename ADD COLUMN colname TEXT;
```

**Use cases:**
- Optional descriptions
- Comments
- Notes fields

#### 200255 - VARCHAR(255) NOT NULL
```sql
-- Limited text, required
ALTER TABLE tablename ADD COLUMN colname VARCHAR(255) NOT NULL;
```

**Use cases:**
- Email addresses
- Short codes
- Limited-length identifiers

#### 201255 - VARCHAR(255) NULLABLE
```sql
-- Limited text, optional
ALTER TABLE tablename ADD COLUMN colname VARCHAR(255);
```

---

### Numeric Column Types (200100-200199)

#### 200101 - INTEGER NOT NULL
```sql
-- Standard integer, required
ALTER TABLE tablename ADD COLUMN colname INTEGER NOT NULL;
```

**Use cases:**
- IDs
- Counters
- Quantities

#### 201101 - INTEGER NULLABLE
```sql
-- Optional integer
ALTER TABLE tablename ADD COLUMN colname INTEGER;
```

**Use cases:**
- Optional counts
- Conditional references

#### 200102 - BIGINT NOT NULL
```sql
-- Large integer, required
ALTER TABLE tablename ADD COLUMN colname BIGINT NOT NULL;
```

**Use cases:**
- Epoch timestamps
- Large IDs
- High-volume counters

#### 201102 - BIGINT NULLABLE
```sql
-- Large integer, optional
ALTER TABLE tablename ADD COLUMN colname BIGINT;
```

#### 200103 - SMALLINT NOT NULL
```sql
-- Small integer, required
ALTER TABLE tablename ADD COLUMN colname SMALLINT NOT NULL;
```

**Use cases:**
- Status flags
- Small enums
- Boolean alternatives (0/1)

#### 201103 - SMALLINT NULLABLE
```sql
-- Small integer, optional
ALTER TABLE tablename ADD COLUMN colname SMALLINT;
```

---

### Decimal Column Types (200200-200299)

#### 200832 - NUMERIC(8,2) NOT NULL
```sql
-- Currency/decimal, required
ALTER TABLE tablename ADD COLUMN colname NUMERIC(8,2) NOT NULL;
```

**Use cases:**
- Prices
- Currency amounts
- Financial calculations

**Example:**
```sql
-- Can store: 999999.99
INSERT INTO product (price) VALUES (99.95);
```

#### 201832 - NUMERIC(8,2) NULLABLE
```sql
-- Currency/decimal, optional
ALTER TABLE tablename ADD COLUMN colname NUMERIC(8,2);
```

#### 201042 - NUMERIC(10,4) NULLABLE
```sql
-- High precision decimal
ALTER TABLE tablename ADD COLUMN colname NUMERIC(10,4);
```

**Use cases:**
- Exchange rates
- Scientific measurements
- High-precision calculations

---

### Boolean Column Types (200300-200399)

#### 200301 - BOOLEAN NOT NULL
```sql
-- Boolean flag, required
ALTER TABLE tablename ADD COLUMN colname BOOLEAN NOT NULL DEFAULT false;
```

**Use cases:**
- Feature flags
- Yes/No questions
- Binary choices

#### 201301 - BOOLEAN NULLABLE
```sql
-- Boolean flag, optional (three-state)
ALTER TABLE tablename ADD COLUMN colname BOOLEAN;
```

**States:**
- `true` - Yes
- `false` - No
- `NULL` - Unknown/Not set

---

### Date/Time Column Types (200400-200499)

#### 200401 - TIMESTAMP NOT NULL
```sql
-- Full timestamp, required
ALTER TABLE tablename ADD COLUMN colname TIMESTAMP NOT NULL;
```

**Use cases:**
- Created dates
- Modified dates
- Event timestamps

#### 201401 - TIMESTAMP NULLABLE
```sql
-- Optional timestamp
ALTER TABLE tablename ADD COLUMN colname TIMESTAMP;
```

#### 200402 - DATE NOT NULL
```sql
-- Date only, required
ALTER TABLE tablename ADD COLUMN colname DATE NOT NULL;
```

**Use cases:**
- Birth dates
- Due dates
- Date ranges

#### 201402 - DATE NULLABLE
```sql
-- Optional date
ALTER TABLE tablename ADD COLUMN colname DATE;
```

#### 200403 - TIME NOT NULL
```sql
-- Time only, required
ALTER TABLE tablename ADD COLUMN colname TIME NOT NULL;
```

**Use cases:**
- Business hours
- Scheduled times
- Time ranges

---

### Binary Column Types (200500-200599)

#### 200501 - BYTEA NOT NULL
```sql
-- Binary data, required
ALTER TABLE tablename ADD COLUMN colname BYTEA NOT NULL;
```

**Use cases:**
- File uploads
- Images
- Binary documents

#### 201501 - BYTEA NULLABLE
```sql
-- Optional binary data
ALTER TABLE tablename ADD COLUMN colname BYTEA;
```

---

### JSON Column Types (200600-200699)

#### 200601 - JSONB NOT NULL
```sql
-- JSON document, required
ALTER TABLE tablename ADD COLUMN colname JSONB NOT NULL DEFAULT '{}'::jsonb;
```

**Use cases:**
- Configuration data
- Flexible attributes
- Dynamic properties

#### 201601 - JSONB NULLABLE
```sql
-- Optional JSON document
ALTER TABLE tablename ADD COLUMN colname JSONB;
```

**Example:**
```sql
-- Store flexible data
INSERT INTO product (attributes) VALUES ('{
    "color": "red",
    "size": "large",
    "weight": 2.5
}'::jsonb);

-- Query JSON data
SELECT * FROM product 
WHERE attributes->>'color' = 'red';
```

#### 200602 - JSON NOT NULL
```sql
-- JSON text, required
ALTER TABLE tablename ADD COLUMN colname JSON NOT NULL;
```

**Note:** JSONB is generally preferred over JSON for better performance.

---

### UUID Column Types (200700-200799)

#### 200701 - UUID NOT NULL
```sql
-- UUID identifier, required
ALTER TABLE tablename ADD COLUMN colname UUID NOT NULL DEFAULT gen_random_uuid();
```

**Use cases:**
- Distributed IDs
- Unique tokens
- Cross-system references

#### 201701 - UUID NULLABLE
```sql
-- Optional UUID
ALTER TABLE tablename ADD COLUMN colname UUID;
```

---

### Array Column Types (200800-200899)

#### 200801 - INTEGER[] NOT NULL
```sql
-- Integer array, required
ALTER TABLE tablename ADD COLUMN colname INTEGER[] NOT NULL DEFAULT '{}';
```

**Use cases:**
- Multiple IDs
- Tag lists
- Selection groups

**Example:**
```sql
-- Store array
INSERT INTO product (tag_ids) VALUES (ARRAY[1,2,3]);

-- Query array
SELECT * FROM product WHERE 1 = ANY(tag_ids);
```

#### 201801 - INTEGER[] NULLABLE
```sql
-- Optional integer array
ALTER TABLE tablename ADD COLUMN colname INTEGER[];
```

#### 200802 - TEXT[] NOT NULL
```sql
-- Text array, required
ALTER TABLE tablename ADD COLUMN colname TEXT[] NOT NULL DEFAULT '{}';
```

**Use cases:**
- Multiple names
- String lists
- Keywords

---

## System Column Types

### 200001 - System Column 'i' (ID)
```sql
-- Primary key column
i INTEGER PRIMARY KEY
-- or
i BIGINT PRIMARY KEY
-- or
i TEXT PRIMARY KEY
```

**Format determined by:** Table type configuration (ttx)

### 200102 - System Column 'd' (Date)
```sql
-- Last edit timestamp
d BIGINT NOT NULL
```

**Value:** Epoch milliseconds UTC

### 200101 - System Column 'e' (Editor)
```sql
-- Last editor ID
e INTEGER NOT NULL REFERENCES aix.userx(i)
```

### 200103 - System Column 'a' (Active)
```sql
-- Active status
a SMALLINT NOT NULL DEFAULT 1
```

**Values:** 0 (inactive) or 1 (active)

### 200001 - System Column 'n' (Name)
```sql
-- Name/title/description
n TEXT NOT NULL
```

### 200101 - System Column 's' (Status)
```sql
-- Business workflow status
s INTEGER NOT NULL DEFAULT 0
```

**Common values:**
- 0 = Draft
- 1 = Pending
- 2 = Approved
- 3 = Rejected

### 200101 - System Column 'v' (Version)
```sql
-- Optimistic lock version
v INTEGER NOT NULL DEFAULT 1
```

**Incremented on each update**

---

## Constraint Column Types

### Foreign Key Column Types (210000-219999)

#### 210101 - FOREIGN KEY NOT NULL
```sql
-- Required foreign key
ALTER TABLE tablename ADD COLUMN fk_column INTEGER NOT NULL 
    REFERENCES parent_table(i);
```

#### 211101 - FOREIGN KEY NULLABLE
```sql
-- Optional foreign key
ALTER TABLE tablename ADD COLUMN fk_column INTEGER
    REFERENCES parent_table(i);
```

---

### Unique Column Types (220000-229999)

#### 220001 - TEXT UNIQUE NOT NULL
```sql
-- Unique text, required
ALTER TABLE tablename ADD COLUMN colname TEXT UNIQUE NOT NULL;
```

**Use cases:**
- Unique codes
- Usernames
- Email addresses

#### 221001 - TEXT UNIQUE NULLABLE
```sql
-- Unique text, optional
ALTER TABLE tablename ADD COLUMN colname TEXT UNIQUE;
```

**Note:** NULL values are not considered duplicates

---

### Check Constraint Types (230000-239999)

#### 230101 - POSITIVE INTEGER
```sql
-- Integer > 0
ALTER TABLE tablename ADD COLUMN colname INTEGER NOT NULL
    CHECK (colname > 0);
```

#### 230102 - NON-NEGATIVE INTEGER
```sql
-- Integer >= 0
ALTER TABLE tablename ADD COLUMN colname INTEGER NOT NULL
    CHECK (colname >= 0);
```

#### 230832 - POSITIVE AMOUNT
```sql
-- Decimal > 0
ALTER TABLE tablename ADD COLUMN colname NUMERIC(8,2) NOT NULL
    CHECK (colname > 0);
```

---

## Default Value Types (240000-249999)

### 240101 - INTEGER DEFAULT 0
```sql
ALTER TABLE tablename ADD COLUMN colname INTEGER NOT NULL DEFAULT 0;
```

### 240102 - BIGINT DEFAULT CURRENT EPOCH
```sql
ALTER TABLE tablename ADD COLUMN colname BIGINT NOT NULL 
    DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT;
```

### 240301 - BOOLEAN DEFAULT FALSE
```sql
ALTER TABLE tablename ADD COLUMN colname BOOLEAN NOT NULL DEFAULT false;
```

### 240601 - JSONB DEFAULT EMPTY OBJECT
```sql
ALTER TABLE tablename ADD COLUMN colname JSONB NOT NULL DEFAULT '{}'::jsonb;
```

### 240801 - ARRAY DEFAULT EMPTY
```sql
ALTER TABLE tablename ADD COLUMN colname INTEGER[] NOT NULL DEFAULT '{}';
```

---

## Computed Column Types (250000-259999)

### 250101 - GENERATED IDENTITY
```sql
ALTER TABLE tablename ADD COLUMN colname INTEGER GENERATED ALWAYS AS IDENTITY;
```

**Use case:** Auto-incrementing IDs

### 250201 - GENERATED STORED
```sql
ALTER TABLE tablename ADD COLUMN full_name TEXT 
    GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED;
```

**Use case:** Derived values stored in table

### 250202 - GENERATED VIRTUAL
```sql
-- PostgreSQL doesn't support VIRTUAL, but can use views
CREATE VIEW customer_view AS
SELECT 
    i,
    n,
    first_name || ' ' || last_name AS full_name
FROM customer;
```

---

## Special Column Types (260000-269999)

### 260001 - IMMUTABLE TEXT
```sql
-- Can be set once, never updated
ALTER TABLE tablename ADD COLUMN colname TEXT NOT NULL;

-- Enforce with trigger
CREATE TRIGGER prevent_update
BEFORE UPDATE ON tablename
FOR EACH ROW
WHEN (OLD.colname IS DISTINCT FROM NEW.colname)
EXECUTE FUNCTION raise_immutable_exception();
```

**Use cases:**
- Code fields
- Creation timestamps
- Permanent identifiers

### 260701 - ENCRYPTED TEXT
```sql
-- Encrypted at application layer
ALTER TABLE tablename ADD COLUMN colname TEXT NOT NULL;
```

**Note:** Encryption handled by application, not database

---

## Column Type Selection Guide

### Decision Tree

```
Need to store...

├─ Text?
│  ├─ Required? → 200001 (TEXT NOT NULL)
│  ├─ Optional? → 201001 (TEXT NULLABLE)
│  └─ Limited length? → 200255 (VARCHAR NOT NULL)
│
├─ Number?
│  ├─ Integer?
│  │  ├─ Small (0-32767)? → 200103 (SMALLINT)
│  │  ├─ Standard? → 200101 (INTEGER)
│  │  └─ Large/Timestamps? → 200102 (BIGINT)
│  │
│  └─ Decimal?
│     ├─ Currency? → 200832 (NUMERIC(8,2))
│     └─ High precision? → 201042 (NUMERIC(10,4))
│
├─ True/False?
│  ├─ Binary (required)? → 200301 (BOOLEAN NOT NULL)
│  └─ Three-state (yes/no/unknown)? → 201301 (BOOLEAN NULLABLE)
│
├─ Date/Time?
│  ├─ Full timestamp? → 200401 (TIMESTAMP)
│  ├─ Date only? → 200402 (DATE)
│  └─ Time only? → 200403 (TIME)
│
├─ Structured data?
│  ├─ JSON? → 200601 (JSONB NOT NULL)
│  └─ Array? → 200801 (INTEGER[])
│
├─ Unique identifier?
│  └─ UUID? → 200701 (UUID NOT NULL)
│
└─ Binary data?
   └─ Files/Images? → 200501 (BYTEA)
```

---

## Examples

### Complete Table Definition

```sql
CREATE TABLE aix.product (
    -- System columns
    i INTEGER PRIMARY KEY,                          -- 200101
    d BIGINT NOT NULL,                              -- 200102
    e INTEGER NOT NULL REFERENCES aix.userx(i),     -- 210101
    a SMALLINT NOT NULL DEFAULT 1,                  -- 200103
    n TEXT NOT NULL,                                -- 200001
    s INTEGER NOT NULL DEFAULT 0,                   -- 200101
    v INTEGER NOT NULL DEFAULT 1,                   -- 200101
    
    -- Business columns
    c1 TEXT UNIQUE NOT NULL,                        -- 220001 (SKU)
    c2 TEXT,                                        -- 201001 (Description)
    c3 NUMERIC(8,2) NOT NULL CHECK (c3 > 0),       -- 230832 (Price)
    c4 INTEGER NOT NULL DEFAULT 0 CHECK (c4 >= 0), -- 230102 (Stock)
    c5 INTEGER REFERENCES aix.category(i),          -- 211101 (Category FK)
    c6 JSONB DEFAULT '{}'::jsonb,                   -- 240601 (Attributes)
    c7 TEXT[] DEFAULT '{}',                         -- 240801 (Tags)
    c8 BOOLEAN NOT NULL DEFAULT true                -- 240301 (Available)
);
```

### TypeX Registration

```sql
-- Register column types in TypeX
INSERT INTO aix.typex (i, n, c, parent_group) VALUES
    (200001, 'Text Not Null', 'TEXT_NOT_NULL', 200000),
    (201001, 'Text Nullable', 'TEXT_NULLABLE', 200000),
    (200101, 'Integer Not Null', 'INT_NOT_NULL', 200100),
    (200832, 'Numeric(8,2) Not Null', 'DECIMAL_82_NOT_NULL', 200200),
    (200601, 'JSONB Not Null', 'JSONB_NOT_NULL', 200600);
```

---

## Best Practices

### 1. Use NOT NULL for System Columns
```sql
-- ✓ Correct
d BIGINT NOT NULL
e INTEGER NOT NULL
a SMALLINT NOT NULL

-- ✗ Wrong
d BIGINT
e INTEGER
```

### 2. Choose Appropriate Size
```sql
-- ✓ Correct: Use SMALLINT for small ranges
a SMALLINT  -- 0 or 1
s INTEGER   -- 0-1000

-- ✗ Wrong: Oversized types
a BIGINT    -- Wastes space for binary value
```

### 3. Use JSONB for Flexible Data
```sql
-- ✓ Correct: JSONB with default
attributes JSONB NOT NULL DEFAULT '{}'::jsonb

-- ✗ Wrong: Many nullable columns
color TEXT,
size TEXT,
weight NUMERIC,
-- ... dozens more
```

### 4. Index Foreign Keys
```sql
-- ✓ Correct
CREATE INDEX idx_product_category ON product(c5);

-- Required for efficient joins
```

---

## Migration Patterns

### Adding New Column Type

```sql
-- 1. Add column to table
ALTER TABLE aix.product 
ADD COLUMN c9 UUID DEFAULT gen_random_uuid();

-- 2. Register in TypeX
INSERT INTO aix.typex (i, n, c, parent_group)
VALUES (200701, 'UUID Not Null', 'UUID_NOT_NULL', 200700);

-- 3. Update FieldX metadata
INSERT INTO aix.fieldx (mx, n, c, dtx, ctx)
VALUES (100, 'Product UUID', 'c9', 10007, 200701);
```

### Changing Column Type

```sql
-- 1. Safe: Widening type
ALTER TABLE product ALTER COLUMN c4 TYPE BIGINT;

-- 2. Unsafe: Narrowing type (may lose data)
-- Verify first:
SELECT MAX(LENGTH(c2)) FROM product;

-- Then change:
ALTER TABLE product ALTER COLUMN c2 TYPE VARCHAR(500);
```

---

**Related Documentation:**
- [Data Types](DATA-TYPES.md)
- [Table Types](TABLE-TYPES.md)
- [System Columns](SYSTEM-COLUMNS.md)
- [Database Schema](../../db/reference/schema.md)
