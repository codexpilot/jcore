# ModelX composition and read mapping

**Design draft · 2026-11-19**

A ModelX describes one logical record. Its FieldX rows define its scalar properties. A model with active composition rules also has named object or array properties. The same ModelX registry and field adapter support direct table copies, joined results, and composite documents. MapX owns table and column linkage. ModelX and FieldX expose those links as previews.

## Model type

`ModelX.mtx` is a TypeX Group 6 reference in the range 300000-399999 with default `300000`. **Table-First is the only supported authority for sealed TableX ↔ ModelX mappings.** The effective mapping type is derived from distinct, active, usable direct TableX links in MapX:

| Type | Description |
|---:|---|
| `300000` | No usable direct table link |
| `310000` | Links directly to one distinct table |
| `330000` | Links directly to two or more distinct tables |
| `390000` | System-managed mapping |

An active `951400` rule with the model as `x1` makes the model structured. A model with zero such rules is flat, including when a getter joins several tables. QueryX defines the operation and whether its result is a single record, a list, or a page. `ModelX.ps` stores parent-model IDs and the signed `ModelX.f` stores provenance. [Model type specification](../reference/model-types.md)

## MapX responsibilities

| Scope | Rule | Responsibility |
| --- | --- | --- |
| 5 · Model ↔ Model | `951400` | Embed the `x2` component ModelX under a named property of the `x1` containing ModelX. |
| 5 · Model ↔ Model | `953000` | Map scalar values between ModelX records using `options.field_pairs`. |
| 7 · Table ↔ Model | `973000` | Map `ColumnX.i` to `FieldX.i` with `options.pairs` and its existing direction and conversion rules. |
| 9 · Model ↔ Query | `992100` | Bind `x1` ModelX as the result of `x2` QueryX. `options.fields` selects the root scalar fields. The getter includes the declared sections for this composed result. |

### Model and field linkage previews

| Preview column | Derived from |
| --- | --- |
| `ModelX.txis` | The distinct TableX IDs in `x1` of active, same-domain scope 7 rules for the model. |
| `FieldX.cxis` | The distinct ColumnX IDs associated with the field by active, same-domain MapX rules. |

Both previews are read-only arrays and can be empty. Authors edit the links in MapX. The getter uses the rules selected for its operation, including their directions, conversions, and operand order. [ModelX linkage preview](../reference/mapx-design.md#modelx-linkage-preview) · [FieldX linkage preview](../reference/mapx-design.md#fieldx-linkage-preview)

## Composition rule

`951400` decodes as `9 | 5 | 14 | 0 | 0`. Operation `14` is in the relationship band. TypeX Group 12 registers it with `k = 51400` and `c = mapx_model_composition`. `B = 0` because the operation uses no ParamX references.

The following rule adds `items` to `SaleOrder` (`400`) using the `SaleItem` model (`401`).

```json
{
  "mpx": 951400,
  "x1": 400,
  "x2": 401,
  "options": {"key": "items", "cardinality": "many"}
}
```

`options.key` is a nonempty, trimmed JSON property name. Match keys case-sensitively. Each active section key is unique within `(dxi, x1)` and must differ from every active scalar `FieldX.c` on the containing model. The same `x2` may be used more than once with different keys, such as `billingAddress` and `shippingAddress`.

`options.cardinality` is required and accepts `one` or `many`.

| Cardinality | Zero matches | One match | Multiple matches |
| --- | --- | --- | --- |
| `one` | `null` | Object | Getter fails with a cardinality error |
| `many` | `[]` | Array with one object | Array in the getter's declared order |

Both endpoints must be active ModelX records in the rule's domain. Reject self-edges and any cycle in the active composition graph. Enforce active section-key uniqueness in the database and check conflicts on MapX and FieldX writes, including reactivation. Protect these checks and cycle validation against concurrent writes. Revalidate dependent result bindings when an active section is changed or removed.

## Getter and adapter

The main getter owns the result. QueryHub authorizes and dispatches the operation. A composed operation selects exactly one `992100` binding for the effective QueryX, including the selected child where applicable. Its `options.fields` lists distinct, active, output-capable FieldX IDs owned by the root ModelX. An empty array produces a root object with section properties only. The getter walks the composition graph and passes the selected scalar fields for each model occurrence to the shared adapter. Array element ordering and result multiplicity belong to the getter. [QueryX redesign](queryx-redesign.md)

- **QueryX and its getter** choose the data sources, joins, parent keys, and exposed component fields for each section. If the same table appears twice, the query identifies the source occurrence for each mapped value.
- **The shared adapter** reads the physical keys using `ColumnX.c` and emits logical keys using `FieldX.c`. It applies the selected scope 7 mappings and any declared value conversions the adapter supports.
- **The main getter** assembles the adapted object and its sections. Build each detail collection by its parent key before combining collections. This preserves the item count when an invoice has both multiple items and multiple payments.

| Model use | How the getter builds it |
| --- | --- |
| Direct table copy | Read one table and adapt each row with its scope 7 mapping. |
| Flat result from multiple tables | Join the selected sources and adapt one record per result key. |
| Sale order | Build the header and attach `items[]` from matching detail rows. |
| Sale invoice | Assemble named sections such as `header`, `items`, `taxes`, and `totals`. Reuse the field adapter for each section. |

A physical table getter can return rows keyed by their actual column names. ModelX result formatting is part of the registered operation. A query can return one adapted object or a collection of those objects using the same ModelX definition.

### Publish a result projection

Call `publish_queryx_result_contract(qxi, version, binding_id, sections)` after selecting the output binding in `QueryX.mapx_ids`. The version is a nonempty text value. Publish a new version when the output changes. Existing versions keep their published field codes, section keys, cardinalities, source occurrences, correlation columns, and ordering.

- Each item in `sections` has a `path`, a `sources` object, and a `fields` array. The root path is `[]`. Other paths list the `951400` rule IDs along the tree. In `sources`, each key names a table occurrence and each value is its TableX ID.
- A mapped field uses `{field, map, source, column}` with a readable `973000` pair. An item with only `field` declares a value computed by the authored getter. The root field IDs must match the selected `992100` binding.
- Nested sections supply `correlation` pairs with `parent` and `child` column references. Each reference has `source` and `column`. A `many` section supplies `order_by` with occurrence-qualified columns and an optional `asc` or `desc` direction.

An installed JDB getter reads the snapshot with `metax.get_queryx_result_contract(qxi, version)`. [Publication SQL](../../../db/aix/migrations/queryx_result_contract.sql) · [JDB export](../../../db/jdx/jdx_export.sql)

## Implementation boundaries

- The fresh AIX schema authors table links through scope 7, including base-only links with `971600`. ModelX CRUD, storage generation, and import planning read the MapX contract. [ModelX CRUD](../../../db/aix/functions/modelx_crud.sql) · [Storage snapshot](../../../db/aix/functions/model_storage_snapshot.sql)
- Scope 9 uses QueryX as its `x2` endpoint. Publication checks the selected `992100` binding against the effective QueryX, the result model, and the root projection. [MapX validator](../../../db/aix/tables/mapx.sql) · [QueryX validator](../../../db/aix/functions/metax_query_validation.sql)
- QueryHub must return the composed payload intact once the authorized runtime dispatch contract is implemented. JDB receives the published per-section mapping plan with the query registry. [QueryX redesign](queryx-redesign.md) · [JDB export](../../../db/jdx/jdx_export.sql)
- Metadata import follows active outgoing `951400` rules and rewrites both model endpoints to the target domain's IDs. Section keys and cardinality carry over as-is. Model provenance uses `f`. [Import dependency planner](../../../db/aix/functions/metax_import_plan.sql)

The AIX fresh schema installs MapX linkage previews, the `951400` operation, and versioned result publication. The authored runtime getter owns section assembly. Durable runtime identity and composite writes remain separate design decisions.
