# Composed Model Type

**TypeX Group 6 · 37xxxx Family**

## Type Definition

| Property | Value |
|----------|-------|
| TypeX ID | `370000` |
| TypeX Code | `composed` |
| TypeX Name | `Composed Model` |
| Group | 6 (Model Type) |
| Family | `37xxxx` |
| Claim Type | 7 |
| Key | `70000` |

## Composition Contract

A composed model type (`mtx = 370000`) defines **one-level composition only**:

- The composed model contains only **non-composed child models**
- Child models must have `mtx != 370000` (not themselves composed)
- No recursive composition allowed at this type level
- Composition structure is defined through MapX `951400` rules

## ModelX.mxis Field

`ModelX.mxis` is a **system-managed, read-only array** containing:

- Sorted, distinct IDs of direct child models
- Populated from active MapX `951400` rules where this model is `x1`
- Empty array `[]` for non-composed models
- Updated automatically when composition rules change

## Usage Example

```json
{
  "i": 500,
  "mtx": 370000,
  "c": "sale_invoice",
  "n": "Sales Invoice",
  "mxis": [501, 502, 503]
}
```

Where child models might be:
- `501`: InvoiceHeader (mtx: 310000, single-table non-composed)
- `502`: InvoiceLineItem (mtx: 310000, single-table non-composed)
- `503`: InvoicePayment (mtx: 310000, single-table non-composed)

## Validation Rules

1. Models with `mtx = 370000` MUST NOT reference other composed models as children
2. Circular references are prohibited at all levels
3. Child model IDs in `mxis` must reference active ModelX records
4. Section keys from MapX rules must not conflict with scalar FieldX codes

## Related Documentation

- [ModelX Composition Architecture](../architecture/modelx-composition.md)
- [Model Types Reference](model-types.md)
- [MapX Design](mapx-design.md)
