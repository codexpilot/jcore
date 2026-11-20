# Data Types Reference

**Version:** 2.0  
**Last Updated:** 2025-01-19  
**Type Range:** 10000-99999  
**Standard:** JCore (Java Core) Taxonomy

Data types define the fundamental storage and representation formats used in AIX database schemas.

---

## Overview

Data types in the 10000-99999 range represent JCore data types:
- Core primitive types (10000-19999)
- Composite types (20000-29999)
- Special types (30000-39999)
- Extended types (40000-49999)

### JCore Philosophy

JCore types map to Java primitive and object types, providing:
- Language-agnostic type definitions
- Clear semantics across platforms
- Predictable storage requirements
- Standard validation rules

---

## Core Primitive Types (10000-19999)

### 10001 - TEXT
**PostgreSQL:** `TEXT`  
**Java:** `String`  
**Description:** Variable-length character string

```sql
-- Definition
CREATE TABLE example (
    col TEXT
);

-- Usage
INSERT INTO example VALUES ('Any length text');
```

**Properties:**
- Unlimited length (practical limit ~1GB)
- UTF-8 encoding
- Suitable for most text fields

**Use cases:**
- Names
- Descriptions
- Comments
- Free-form text

---

### 10002 - INTEGER
**PostgreSQL:** `INTEGER`  
**Java:** `int`  
**Description:** 32-bit signed integer

```sql
-- Definition
CREATE TABLE example (
    col INTEGER
);

-- Usage
INSERT INTO example VALUES (42);
```

**Properties:**
- Range: -2,147,483,648 to 2,147,483,647
- 4 bytes storage
- Standard integer type

**Use cases:**
- IDs (moderate scale)
- Counters
- Quantities
- Status codes

---

### 10003 - BIGINT
**PostgreSQL:** `BIGINT`  
**Java:** `long`  
**Description:** 64-bit signed integer

```sql
-- Definition
CREATE TABLE example (
    col BIGINT
);

-- Usage
INSERT INTO example VALUES (9223372036854775807);
```

**Properties:**
- Range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
- 8 bytes storage
- Large integer type

**Use cases:**
- Epoch milliseconds timestamps
- Large IDs
- High-volume counters
- ID generation (Algorithm 2)

**AIX Standard:**
```sql
-- Store current time
d BIGINT DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT
```

---

### 10004 - SMALLINT
**PostgreSQL:** `SMALLINT`  
**Java:** `short`  
**Description:** 16-bit signed integer

```sql
-- Definition
CREATE TABLE example (
    col SMALLINT
);

-- Usage
INSERT INTO example VALUES (32767);
```

**Properties:**
- Range: -32,768 to 32,767
- 2 bytes storage
- Space-efficient integer

**Use cases:**
- Active status (0/1)
- Small enumerations
- Flags
- Limited-range values

**AIX Standard:**
```sql
-- Active status column
a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0, 1))
```

---

### 10005 - DECIMAL
**PostgreSQL:** `NUMERIC`  
**Java:** `BigDecimal`  
**Description:** Arbitrary precision decimal

```sql
-- Definition
CREATE TABLE example (
    col NUMERIC(10, 2)  -- 10 digits, 2 decimal places
);

-- Usage
INSERT INTO example VALUES (12345678.90);
```

**Properties:**
- Exact precision (no rounding errors)
- Configurable precision and scale
- Variable storage size

**Common configurations:**
- `NUMERIC(8,2)` - Currency (999999.99)
- `NUMERIC(10,4)` - High precision (999999.9999)
- `NUMERIC(18,6)` - Very high precision

**Use cases:**
- Currency amounts
- Financial calculations
- Scientific measurements
- Any calculation requiring exactness

---

### 10006 - BOOLEAN
**PostgreSQL:** `BOOLEAN`  
**Java:** `boolean`  
**Description:** True/false value

```sql
-- Definition
CREATE TABLE example (
    col BOOLEAN
);

-- Usage
INSERT INTO example VALUES (true);
INSERT INTO example VALUES (false);
INSERT INTO example VALUES (NULL);  -- If nullable
```

**Properties:**
- Values: `true`, `false`, `NULL` (if nullable)
- 1 byte storage
- Three-state logic when nullable

**Use cases:**
- Feature flags
- Yes/No questions
- Binary choices
- Optional flags (when nullable)

**AIX Note:** For binary active status, SMALLINT is preferred:
```sql
-- Preferred in AIX
a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0, 1))

-- Alternative
a BOOLEAN NOT NULL DEFAULT true
```

---

### 10007 - UUID
**PostgreSQL:** `UUID`  
**Java:** `UUID`  
**Description:** Universally unique identifier

```sql
-- Definition
CREATE TABLE example (
    col UUID DEFAULT gen_random_uuid()
);

-- Usage
INSERT INTO example VALUES ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
INSERT INTO example DEFAULT VALUES;  -- Auto-generated
```

**Properties:**
- 128-bit value
- 16 bytes storage
- Globally unique
- Standard format: 8-4-4-4-12 hex digits

**Use cases:**
- Distributed system IDs
- Security tokens
- External references
- Cross-system identifiers

---

### 10008 - BYTEA
**PostgreSQL:** `BYTEA`  
**Java:** `byte[]`  
**Description:** Binary data

```sql
-- Definition
CREATE TABLE example (
    col BYTEA
);

-- Usage
INSERT INTO example VALUES (E'\\xDEADBEEF');
INSERT INTO example VALUES (decode('DEADBEEF', 'hex'));
```

**Properties:**
- Variable length
- 1-4 bytes overhead + data
- Maximum ~1GB

**Use cases:**
- File uploads
- Images
- Binary documents
- Encrypted data

**Best Practice:** For large files (>1MB), consider external storage with URL reference.

---

## Temporal Types (10100-10199)

### 10101 - TIMESTAMP
**PostgreSQL:** `TIMESTAMP WITHOUT TIME ZONE`  
**Java:** `LocalDateTime`  
**Description:** Date and time without timezone

```sql
-- Definition
CREATE TABLE example (
    col TIMESTAMP
);

-- Usage
INSERT INTO example VALUES ('2025-01-19 15:30:00');
INSERT INTO example VALUES (NOW());
```

**Properties:**
- 8 bytes storage
- Microsecond precision
- No timezone information

**Use cases:**
- Event timestamps
- Audit trails
- Scheduled times

**AIX Standard:** Use BIGINT epoch milliseconds instead:
```sql
-- Preferred
d BIGINT NOT NULL DEFAULT (EXTRACT(EPOCH FROM NOW()) * 1000)::BIGINT

-- Convert for display
SELECT to_timestamp(d / 1000.0) FROM table;
```

---

### 10102 - TIMESTAMPTZ
**PostgreSQL:** `TIMESTAMP WITH TIME ZONE`  
**Java:** `ZonedDateTime`  
**Description:** Date and time with timezone

```sql
-- Definition
CREATE TABLE example (
    col TIMESTAMPTZ
);

-- Usage
INSERT INTO example VALUES ('2025-01-19 15:30:00+00');
INSERT INTO example VALUES (NOW());
```

**Properties:**
- 8 bytes storage
- Microsecond precision
- Timezone aware
- Stored in UTC, displayed in session timezone

---

### 10103 - DATE
**PostgreSQL:** `DATE`  
**Java:** `LocalDate`  
**Description:** Calendar date only

```sql
-- Definition
CREATE TABLE example (
    col DATE
);

-- Usage
INSERT INTO example VALUES ('2025-01-19');
INSERT INTO example VALUES (CURRENT_DATE);
```

**Properties:**
- 4 bytes storage
- Date only (no time component)
- Range: 4713 BC to 5874897 AD

**Use cases:**
- Birth dates
- Due dates
- Date ranges
- Calendar events

---

### 10104 - TIME
**PostgreSQL:** `TIME WITHOUT TIME ZONE`  
**Java:** `LocalTime`  
**Description:** Time of day only

```sql
-- Definition
CREATE TABLE example (
    col TIME
);

-- Usage
INSERT INTO example VALUES ('15:30:00');
INSERT INTO example VALUES (CURRENT_TIME);
```

**Properties:**
- 8 bytes storage
- Microsecond precision
- Time only (no date component)

**Use cases:**
- Business hours
- Scheduled times
- Time ranges

---

## Composite Types (20000-29999)

### 20001 - JSONB
**PostgreSQL:** `JSONB`  
**Java:** `JsonObject` (gson/jackson)  
**Description:** Binary JSON document

```sql
-- Definition
CREATE TABLE example (
    col JSONB DEFAULT '{}'::jsonb
);

-- Usage
INSERT INTO example VALUES ('{"key": "value", "count": 42}');

-- Query
SELECT * FROM example WHERE col->>'key' = 'value';
SELECT * FROM example WHERE col @> '{"key": "value"}';
```

**Properties:**
- Binary storage format
- Indexable
- Query operations supported
- More efficient than JSON type

**Use cases:**
- Flexible attributes
- Configuration data
- Dynamic properties
- Semi-structured data

**Best Practices:**
```sql
-- Index for queries
CREATE INDEX idx_attrs ON example USING gin(col);

-- Default empty object
col JSONB NOT NULL DEFAULT '{}'::jsonb
```

---

### 20002 - JSON
**PostgreSQL:** `JSON`  
**Java:** `String` (JSON string)  
**Description:** Text JSON document

```sql
-- Definition
CREATE TABLE example (
    col JSON
);

-- Usage
INSERT INTO example VALUES ('{"key": "value"}');
```

**Properties:**
- Text storage format
- Validates JSON on insert
- Preserves input formatting
- Less efficient than JSONB

**Note:** Prefer JSONB for most use cases.

---

### 20003 - ARRAY(INTEGER)
**PostgreSQL:** `INTEGER[]`  
**Java:** `int[]` or `List<Integer>`  
**Description:** Array of integers

```sql
-- Definition
CREATE TABLE example (
    col INTEGER[] DEFAULT '{}'
);

-- Usage
INSERT INTO example VALUES (ARRAY[1, 2, 3, 4, 5]);
INSERT INTO example VALUES ('{1,2,3,4,5}');

-- Query
SELECT * FROM example WHERE 3 = ANY(col);
SELECT * FROM example WHERE col @> ARRAY[1,2];
```

**Properties:**
- Variable length
- 1D or multidimensional
- Indexable with GIN

**Use cases:**
- Multiple IDs
- Tag lists
- Multiple selections
- Related items

---

### 20004 - ARRAY(TEXT)
**PostgreSQL:** `TEXT[]`  
**Java:** `String[]` or `List<String>`  
**Description:** Array of text values

```sql
-- Definition
CREATE TABLE example (
    col TEXT[] DEFAULT '{}'
);

-- Usage
INSERT INTO example VALUES (ARRAY['tag1', 'tag2', 'tag3']);

-- Query
SELECT * FROM example WHERE 'tag1' = ANY(col);
```

**Use cases:**
- Keywords
- Tags
- Multiple names
- String lists

---

## Special Types (30000-39999)

### 30001 - ENUM (via TypeX)
**PostgreSQL:** `INTEGER REFERENCES typex(i)`  
**Java:** `enum` or `int`  
**Description:** Enumerated type via TypeX catalog

```sql
-- Definition
CREATE TABLE example (
    status INTEGER REFERENCES aix.typex(i)
);

-- TypeX entries
INSERT INTO aix.typex (i, n, c, parent_group) VALUES
    (30001, 'Draft', 'DRAFT', 30000),
    (30002, 'Published', 'PUBLISHED', 30000),
    (30003, 'Archived', 'ARCHIVED', 30000);

-- Usage
INSERT INTO example VALUES (30001);  -- Draft

-- Query with name
SELECT e.*, t.n as status_name
FROM example e
JOIN aix.typex t ON e.status = t.i;
```

**Use cases:**
- Status values
- Categories
- Types
- Fixed value lists

---

### 30002 - REFERENCE (Foreign Key)
**PostgreSQL:** `INTEGER REFERENCES table(i)`  
**Java:** `int` (ID) or object reference  
**Description:** Foreign key reference

```sql
-- Definition
CREATE TABLE order_table (
    i INTEGER PRIMARY KEY,
    customer_f INTEGER NOT NULL REFERENCES customer(i)
);

-- Usage
INSERT INTO order_table (i, customer_f) VALUES (1, 123);

-- Query with join
SELECT o.*, c.n as customer_name
FROM order_table o
JOIN customer c ON o.customer_f = c.i;
```

**Properties:**
- Enforces referential integrity
- Prevents orphaned records
- Supports CASCADE options

**Naming Convention:**
- Single FK: `tablename_f`
- Multiple FKs: `descriptive_tablename_f`

---

## Type Mapping Tables

### PostgreSQL to Java

| PostgreSQL | Java | JCore ID |
|------------|------|----------|
| TEXT | String | 10001 |
| INTEGER | int | 10002 |
| BIGINT | long | 10003 |
| SMALLINT | short | 10004 |
| NUMERIC | BigDecimal | 10005 |
| BOOLEAN | boolean | 10006 |
| UUID | UUID | 10007 |
| BYTEA | byte[] | 10008 |
| TIMESTAMP | LocalDateTime | 10101 |
| DATE | LocalDate | 10103 |
| TIME | LocalTime | 10104 |
| JSONB | JsonObject | 20001 |
| INTEGER[] | int[] | 20003 |
| TEXT[] | String[] | 20004 |

### PostgreSQL to Dart/Flutter

| PostgreSQL | Dart | JCore ID |
|------------|------|----------|
| TEXT | String | 10001 |
| INTEGER | int | 10002 |
| BIGINT | int | 10003 |
| SMALLINT | int | 10004 |
| NUMERIC | double | 10005 |
| BOOLEAN | bool | 10006 |
| UUID | String | 10007 |
| BYTEA | Uint8List | 10008 |
| TIMESTAMP | DateTime | 10101 |
| DATE | DateTime | 10103 |
| TIME | String | 10104 |
| JSONB | Map<String, dynamic> | 20001 |
| INTEGER[] | List<int> | 20003 |
| TEXT[] | List<String> | 20004 |

---

## Type Selection Guide

### Decision Tree

```
What data are you storing?

├─ Text/String
│  ├─ Variable length → 10001 (TEXT)
│  ├─ Limited length → 10001 (TEXT) with constraint
│  └─ Fixed codes → 10001 (TEXT UNIQUE)
│
├─ Number
│  ├─ Integer
│  │  ├─ Small (-32K to 32K) → 10004 (SMALLINT)
│  │  ├─ Standard (-2B to 2B) → 10002 (INTEGER)
│  │  └─ Large/Timestamps → 10003 (BIGINT)
│  │
│  └─ Decimal
│     ├─ Currency → 10005 (NUMERIC(8,2))
│     └─ High precision → 10005 (NUMERIC(10,4))
│
├─ True/False
│  └─ Boolean → 10006 (BOOLEAN)
│
├─ Date/Time
│  ├─ Full timestamp → 10101 (TIMESTAMP)
│  ├─ Date only → 10103 (DATE)
│  ├─ Time only → 10104 (TIME)
│  └─ AIX standard → 10003 (BIGINT epoch ms)
│
├─ Unique ID
│  ├─ Sequential → 10002 (INTEGER) or 10003 (BIGINT)
│  ├─ Distributed → 10007 (UUID)
│  └─ AIX Algorithm 2 → 10003 (BIGINT)
│
├─ Flexible/Dynamic
│  ├─ Structured data → 20001 (JSONB)
│  ├─ Multiple values → 20003 (INTEGER[]) or 20004 (TEXT[])
│  └─ Configuration → 20001 (JSONB)
│
├─ Binary
│  └─ Files/Images → 10008 (BYTEA)
│
└─ References
   └─ Foreign key → 30002 (INTEGER REFERENCES)
```

---

## Examples

### System Columns

```sql
CREATE TABLE aix.customer (
    -- System columns with JCore types
    i INTEGER PRIMARY KEY,                    -- 10002
    d BIGINT NOT NULL,                        -- 10003 (epoch ms)
    e INTEGER REFERENCES aix.userx(i),        -- 30002
    a SMALLINT NOT NULL DEFAULT 1,            -- 10004
    n TEXT NOT NULL,                          -- 10001
    s INTEGER NOT NULL DEFAULT 0,             -- 10002
    v INTEGER NOT NULL DEFAULT 1              -- 10002
);
```

### Business Table

```sql
CREATE TABLE aix.product (
    -- System columns
    i INTEGER PRIMARY KEY,                    -- 10002
    d BIGINT NOT NULL,                        -- 10003
    e INTEGER NOT NULL,                       -- 10002
    a SMALLINT NOT NULL DEFAULT 1,            -- 10004
    n TEXT NOT NULL,                          -- 10001
    s INTEGER NOT NULL DEFAULT 0,             -- 10002
    v INTEGER NOT NULL DEFAULT 1,             -- 10002
    
    -- Business columns
    c1 TEXT UNIQUE NOT NULL,                  -- 10001 (SKU)
    c2 TEXT,                                  -- 10001 (Description)
    c3 NUMERIC(8,2) NOT NULL,                -- 10005 (Price)
    c4 INTEGER NOT NULL DEFAULT 0,            -- 10002 (Stock)
    c5 INTEGER REFERENCES aix.category(i),    -- 30002 (Category)
    c6 JSONB DEFAULT '{}'::jsonb,            -- 20001 (Attributes)
    c7 TEXT[] DEFAULT '{}',                   -- 20004 (Tags)
    c8 UUID DEFAULT gen_random_uuid()         -- 10007 (External ID)
);
```

### TypeX Registration

```sql
-- Register data types in TypeX
INSERT INTO aix.typex (i, n, c, parent_group) VALUES
    (10001, 'Text', 'TEXT', 10000),
    (10002, 'Integer', 'INTEGER', 10000),
    (10003, 'BigInt', 'BIGINT', 10000),
    (10004, 'SmallInt', 'SMALLINT', 10000),
    (10005, 'Decimal', 'NUMERIC', 10000),
    (10006, 'Boolean', 'BOOLEAN', 10000),
    (10007, 'UUID', 'UUID', 10000),
    (10008, 'ByteA', 'BYTEA', 10000),
    (10101, 'Timestamp', 'TIMESTAMP', 10100),
    (10103, 'Date', 'DATE', 10100),
    (10104, 'Time', 'TIME', 10100),
    (20001, 'JSONB', 'JSONB', 20000),
    (20003, 'Integer Array', 'INTEGER_ARRAY', 20000),
    (20004, 'Text Array', 'TEXT_ARRAY', 20000);
```

---

## Best Practices

### 1. Choose Appropriate Size
```sql
-- ✓ Correct
a SMALLINT          -- Binary status
i INTEGER           -- Standard ID
d BIGINT            -- Epoch timestamp

-- ✗ Wrong
a BIGINT            -- Wastes space
i BIGINT            -- Oversized for most IDs
```

### 2. Use Exact Types for Currency
```sql
-- ✓ Correct
price NUMERIC(8,2)  -- Exact decimal

-- ✗ Wrong
price FLOAT         -- Rounding errors!
```

### 3. Prefer JSONB over JSON
```sql
-- ✓ Correct
attributes JSONB NOT NULL DEFAULT '{}'::jsonb

-- ✗ Wrong
attributes JSON     -- Less efficient
```

### 4. Use Arrays for Multiple Values
```sql
-- ✓ Correct
tags TEXT[] DEFAULT '{}'

-- ✗ Wrong
tag1 TEXT, tag2 TEXT, tag3 TEXT  -- Inflexible
```

### 5. Index Foreign Keys
```sql
-- ✓ Correct
customer_f INTEGER REFERENCES customer(i);
CREATE INDEX idx_order_customer ON order_table(customer_f);
```

---

**Related Documentation:**
- [Column Types](COLUMN-TYPES.md)
- [Table Types](TABLE-TYPES.md)
- [TypeX Catalog](TYPEX-CATALOG.md)
- [Database Schema](../../db/reference/schema.md)
