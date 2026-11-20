# Field Types Reference

**Version:** 2.0  
**Last Updated:** 2025-01-19  
**Type Range:** 400000-499999

Field types define the purpose and validation rules for fields in ModelX definitions.

---

## Core Field Types

### 400001 - Business Field
Standard business data field.

**Properties:**
- User-editable
- Included in CRUD operations
- Standard validation

### 400002 - Computed Field
Calculated from other fields.

**Properties:**
- Generated value
- Read-only
- Not stored (or stored if materialized)

### 400003 - System Field
Required system column.

**Properties:**
- Auto-managed
- Not user-editable
- Standard semantics

---

## Validation Types

### 400010 - Required Field
Must have non-null value.

### 400011 - Unique Field
Must be unique within table.

### 400012 - Indexed Field
Has database index for performance.

---

## Usage

Set via FieldX.ftx:
```sql
UPDATE aix.fieldx SET ftx = 400001 WHERE i = 1000;
```

---

**Related Documentation:**
- [Column Types](COLUMN-TYPES.md)
- [Data Types](DATA-TYPES.md)
