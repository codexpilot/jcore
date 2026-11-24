# ModelX Types Reference

**Version:** 3.0 (Table-First Only)  
**Last Updated:** 2026-11-24  
**Type Range:** 300000-399999 (TypeX Group 6)

ModelX types describe how a model maps to tables. **Table-First is the only supported authority for a sealed TableX ↔ ModelX mapping.** The effective mapping type is derived from distinct, active, usable direct TableX links in MapX.

---

## Table-First Authority

1. Create TableX and ModelX independently, in either order
2. Match definitions through MapX (Scope 7: table associations and column-to-field mappings)
3. Seal the configuration as **Table-First** once validated
4. TableX supplies the physical schema contract; ModelX follows that contract

---

## ModelX Type Catalog

| Type ID | Model Type | Meaning |
| ---: | --- | --- |
| `300000` | No Map | The model has no usable direct table link. It may still have inherited sources. |
| `310000` | Single Table Mapped | The model links directly to one distinct table. |
| `330000` | Multiple Tables Mapped | The model links directly to two or more distinct tables. |
| `390000` | System Mapped | The model has an explicitly system-managed mapping. Its table count is still available separately. |

The effective type is **read-only** and derived from MapX associations. An explicit system-managed marker (390000) takes precedence over the table count. The table list is available in `ModelX.txis` preview field.

---

## Retired Types

**Model-First workflow has been retired.** The following types are no longer supported:

- `320000` - Model Claimed Table (deprecated)
- `340000` - Model Claimed Tables (deprecated)

All mappings use **Table-First authority** where TableX defines the physical schema contract.

---

## DNA Linkage

MapX records inheritance and coalition as DNA mapping kinds:

| Kind | Child Key Rule | Meaning |
| --- | --- | --- |
| Inheritance | `child.i` references `parent.i` | Direct cloning of identity. Child receives exact parent ID. |
| Coalition | Child's business `f` is unique and references `parent.i` | Parent can resolve to concrete variant through `f`. |
| Ordinary 1:1 | Child has own identity, mapped reference is unique | Relation with at most one matching child. |
| Ordinary 1:N | Child has own identity, multiple children may share reference | Relation with multiple possible children. |

Inheritance and coalition apply within families:
- TableX ↔ TableX uses MapX scope 4
- ModelX ↔ ModelX uses MapX scope 5

---

## Chain Roots and Generations

- A chain has one root at generation 0
- Each DNA parent link adds one step
- Maximum: **8 steps per chain** (9 generations including root)
- A member has at most one designated parent per chain
- Cycles in DNA parent links are rejected
- When table chain and model chain have root-to-root mapping, the table root supplies authority at seal

---

## Local Extensions

A domain can import a model with its mapping, then create a native child that:
- Inherits from the protected parent
- Maps directly to its own native table
- Shows effective type **Single Table Mapped**
- Preserves parent's fields, type, and transferred mappings

The native child owns its own DNA link, columns/fields, and MapX rules in the destination domain.

---

**Related Documentation:**
- [Table Types](table-types.md)
- [MapX Design](mapx-design.md)
- [TypeX Catalog](typex-catalog.md)
