# Table Types Reference

**Version:** 3.0 (SXB Encoding)  
**Last Updated:** 2026-11-24  
**Type Range:** 100000-199999 (TypeX Group 4)  
**Encoding:** SXB Format

Table types define storage settings for generated database tables using the SXB encoding scheme.

---

## SXB Encoding Structure

**Formula:** `ttx = 100000 + 100×S + 10×X + B`

```
100SXB
   │││
   ││└─ B: Logging and recursion (0-3)
   │└── X: ID algorithm and format packed (0-8)
   └─── S: Sync policy (0-3)
```

### S - Sync Policy (0-3)

| Value | Policy | Meaning |
| ---: | --- | --- |
| `0` | Private | Local-only data, no synchronization |
| `1` | Protected | Protected from external sync |
| `2` | Synced | Participates in synchronization |
| `3` | Main | Main sync node (requires logging) |

### X - Algorithm and Format Packed (0-8)

**Formula:** `X = 3×algorithm + (format-3)`

**Decode:**
- `algorithm = X ÷ 3` (integer division)
- `format = 3 + (X mod 3)`

| X | Algorithm | Format | Description |
| ---: | --- | --- | --- |
| `0` | Custom/Supplied (0) | INTEGER (3) | Caller supplies INTEGER ID |
| `1` | Custom/Supplied (0) | BIGINT (4) | Caller supplies BIGINT ID |
| `2` | Custom/Supplied (0) | UUID (5) | Caller supplies UUID |
| `3` | Auto-increment (1) | INTEGER (3) | Database auto-increment INTEGER |
| `4` | Auto-increment (1) | BIGINT (4) | Database auto-increment BIGINT |
| `5` | Auto-increment (1) | UUID (5) | Invalid combination |
| `6` | Epoch Server Serial (2) | INTEGER (3) | Invalid combination |
| `7` | Epoch Server Serial (2) | BIGINT (4) | Epoch/server/serial BIGINT |
| `8` | Epoch Server Serial (2) | UUID (5) | Epoch/server/serial UUID |

### B - Logging and Recursion (0-3)

**Formula:** `B = 2×logging + recursion`

**Decode:**
- `logging = B ÷ 2` (integer division)
- `recursion = B mod 2`

| B | Logging | Recursion | Description |
| ---: | ---: | ---: | --- |
| `0` | 0 | 0 | Flat, logging off |
| `1` | 0 | 1 | Recursive, logging off |
| `2` | 1 | 0 | Flat, logging on |
| `3` | 1 | 1 | Recursive, logging on |

---

## Common Table Types

| Type | S | X | B | Description |
| ---: | ---: | ---: | ---: | --- |
| `100040` | 0 | 4 | 0 | Private · Auto-increment BIGINT · Flat, log off (default) |
| `100042` | 0 | 4 | 2 | Private · Auto-increment BIGINT · Flat, log on |
| `100340` | 3 | 4 | 0 | Main · Auto-increment BIGINT · Flat, log off (invalid: Main requires logging) |
| `100342` | 3 | 4 | 2 | Main · Auto-increment BIGINT · Flat, log on |
| `100010` | 0 | 1 | 0 | Private · Custom BIGINT · Flat, log off (inherited ID) |
| `100248` | 2 | 4 | 8 | Synced · Auto-increment BIGINT · Invalid (B=8 out of range) |

**Default:** `100040` (Private, auto-increment BIGINT, flat with logging off)

---

## Validation Rules

1. **Main requires logging:** If `S=3`, then `logging=1` (B must be 2 or 3)
2. **Synced/Main require BIGINT or UUID:** If `S≥2`, then `format≠3`
3. **Auto-increment requires INTEGER or BIGINT:** If `algorithm=1`, then `format≠5`
4. **Epoch Server Serial requires BIGINT or UUID:** If `algorithm=2`, then `format≠3`

---

## Format Code Mapping to DataTypeX

Table type format codes map to DataTypeX IDs:

| Format | Name | DataTypeX ID | SQL Type |
| ---: | --- | ---: | --- |
| `3` | INTEGER | `2` | INTEGER (INT32) |
| `4` | BIGINT | `3` | BIGINT (INT64) |
| `5` | UUID | `6` | UUID |

---

## Encoding Examples

### Example 1: Private Auto-increment BIGINT
```
S = 0 (Private)
algorithm = 1 (Auto-increment)
format = 4 (BIGINT)
logging = 0, recursion = 0

X = 3×1 + (4-3) = 4
B = 2×0 + 0 = 0

ttx = 100000 + 100×0 + 10×4 + 0 = 100040
```

### Example 2: Main Auto-increment BIGINT with Logging
```
S = 3 (Main)
algorithm = 1 (Auto-increment)
format = 4 (BIGINT)
logging = 1, recursion = 0

X = 3×1 + (4-3) = 4
B = 2×1 + 0 = 2

ttx = 100000 + 100×3 + 10×4 + 2 = 100342
```

### Example 3: Private Custom BIGINT (Inherited ID)
```
S = 0 (Private)
algorithm = 0 (Custom/supplied)
format = 4 (BIGINT)
logging = 0, recursion = 0

X = 3×0 + (4-3) = 1
B = 2×0 + 0 = 0

ttx = 100000 + 100×0 + 10×1 + 0 = 100010
```

---

## Migration from SDALF

**Previous encoding included Direction digit (removed in SXB):**

The old SDALF format was `S×1000 + ((D-1)×3 + A)×100 + L×10 + F` which included a Direction digit for Model-First vs Table-First authority. The new SXB format removes Direction entirely because **Table-First is now the only supported authority**.

---

**Related Documentation:**
- [Model Types](model-types.md)
- [Data Types](data-types.md)
- [TypeX Catalog](typex-catalog.md)
