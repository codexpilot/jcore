# MapX Design Specification

**Version 2.0** · 2026-11-18 · AIX Team

MapX is the registry for constraints, relationships, and value mappings in the fresh AIX schema. Each MapX row defines one rule with one or two TableX, ModelX, or QueryX containers. [MapX SQL](../../../db/aix/tables/mapx.sql)

The scope determines the container types stored in `x1` and `x2`. The operation determines the shape of `options`, which holds the columns, fields, parameters, and other items used by the rule. This gives a single-table uniqueness rule the same structure whether it covers one column or several.

Column Type (`ctx`) describes a column's capabilities. MapX defines concrete rules, such as the target of a foreign key or the members of a composite unique constraint. The generator uses each source for its part of the table definition and emits each constraint once.

## Type encoding

The six-digit MapX type code is `9SOOBN`.

| Part | Meaning |
| --- | --- |
| `9` | Fixed MapX identifier |
| `S` | Scope digit, 1–9 |
| `OO` | Two-digit operation code |
| `B` | Number of operation parameters, 0–3 |
| `N` | Reserved digit, initially 0 |

Decode the scope as `(mpx / 10000) % 10`, the operation as `(mpx / 100) % 100`, the parameter count as `(mpx / 10) % 10`, and the reserved digit as `mpx % 10`. These expressions use integer division.

TypeX Group 12 covers `900000–999999` under the current catalog formula. For a MapX code, the TypeX key is `k = mpx - 900000`. Register Group 12 in TypeG and seed the supported MapX codes in TypeX. The MapX scope range starts at `910000`.

### Scopes and container IDs

| `S` | Scope | `x1` | `x2` | Example use |
| ---: | --- | --- | --- | --- |
| 1 | Table | TableX.i | 0 | Unique key or check within a table |
| 2 | Model | ModelX.i | 0 | Required fields or a model validation rule |
| 3 | Query | QueryX.i | 0 | A query parameter used for pagination |
| 4 | Table ↔ Table | First TableX.i | Second TableX.i | Foreign key or join relationship |
| 5 | Model ↔ Model | First ModelX.i | Second ModelX.i | Model relationship or value mapping |
| 6 | Query ↔ Query | First QueryX.i | Second QueryX.i | Binding one query's output to another's input |
| 7 | Table ↔ Model | TableX.i | ModelX.i | Table linkage and column-to-field mapping |
| 8 | Table ↔ Query | TableX.i | QueryX.i | A table occurrence, filter, or write target |
| 9 | Model ↔ Query | ModelX.i | QueryX.i | A model input or output binding |

`x1` is always positive. Scopes 1–3 use `x2 = 0`. Scopes 4–9 require a positive `x2` and use the container order in the table. Both positions can hold the same container ID for a self-relationship when the operation allows it. Each operation defines the roles and direction of the two positions.

ParamX belongs to QueryX through `ParamX.qxi`. A parameter use belongs within the options of the relevant scope. For example, a page-size parameter can be used in scope 3, and a parameter bound to a table column can be used in scope 8.

### Operation catalog

The operation ranges below are reserved by category. Every usable `mpx` must have a TypeX entry and a matching validator. The initial JCore catalog supports the codes below; other codes remain unregistered until their option shape and validation are defined.

| `OO` | Category | Provisional assignments |
| --- | --- | --- |
| 00–09 | Constraints | 00 unique, 01 check, 02 foreign key, 03 exclusion, 04 not null |
| 10–19 | Relationships | 10 shared identity, 11 one-to-one, 12 one-to-many, 13 many-to-many |
| 20–29 | Bindings | 20 input, 21 output, 22 filter, 23 join |
| 30–39 | Value mappings | 30 standard, 31 partial, 32 computed |
| 40–99 | Reserved | Available for future operations |

`B` counts the entries of the optional `options.parameters` array. An omitted array counts as zero, and JCore checks the encoded count. Parameters are ParamX IDs owned by the QueryX selected by the scope. Mapping items such as column pairs and settings such as `on_delete` have their own keys. A composite key can therefore use any number of columns with `B = 0`.

Most option keys have a type fixed by their operation. An expression that accepts more than one kind of object uses a typed reference. The agreed codes for those references are 0 none, 1 TableX, 2 ModelX, 3 QueryX, 4 ColumnX, 5 FieldX, 6 ParamX, 7 variable, and 8 ConstX. Variable identity and storage remain open.

Initial registered rules:

| `mpx` | Scope | Operation | Required options |
| ---: | --- | --- | --- |
| 910000 | Table | Unique | `columns` |
| 910100 | Table | Check | `expression` |
| 920000 | Model | Required fields | `fields` |
| 930000 | Query | Parameter set | `params` |
| 940200 | Table ↔ Table | Foreign key | `column_pairs` |
| 941000 | Table ↔ Table | Shared identity | `column_pairs` |
| 941100 | Table ↔ Table | One-to-one | `column_pairs` |
| 941200 | Table ↔ Table | One-to-many | `column_pairs` |
| 941300 | Table ↔ Table | Many-to-many bridge | `bridge_table`, `bridge_pairs` |
| 953000 | Model ↔ Model | Field mapping | `field_pairs` |
| 962000 | Query ↔ Query | Parameter binding | `parameter_pairs` |
| 973000 | Table ↔ Model | Field mapping | `pairs` |
| 982200 | Table ↔ Query | Filter | `column`, `param`, `operator`, `table_occurrence` |
| 982300 | Table ↔ Query | Join | `mapx_id`, `table_occurrence` |
| 992000 | Model ↔ Query | Input binding | `fields` |
| 992100 | Model ↔ Query | Output binding | `fields` |

### Proposed model composition

Add `951400` (`9 | 5 | 14 | 0 | 0`) as the ModelX composition operation. `x1` holds the containing ModelX ID, `x2` holds the component ModelX ID, and `options` contains `key` and `cardinality` (`one` or `many`). TypeX Group 12 uses `k = 51400` and code `mapx_model_composition`.

The getter uses active composition rules to assemble named sections. `953000` retains its field pairs, `973000` supplies column-to-field pairs, and `992100` selects the output model and its root scalar fields. The new operation uses scope 5 in the existing schema. [Composition rule and validation](../architecture/modelx-composition.md#composition-rule)

## Database schema

This draft DDL shows the replacement table. The operation and reference checks below supplement the table constraints.

```sql
CREATE TABLE mx.mapx (
    i BIGINT PRIMARY KEY CHECK (i > 0),
    d BIGINT NOT NULL,
    e INT NOT NULL,
    a SMALLINT NOT NULL DEFAULT 1 CHECK (a IN (0, 1)),
    dxi INT NOT NULL REFERENCES mx.domainx(i),
    n TEXT NOT NULL,
    c TEXT NOT NULL UNIQUE,

    mpx INT NOT NULL REFERENCES cox.typex(i),
    x1 BIGINT NOT NULL CHECK (x1 > 0),
    x2 BIGINT NOT NULL DEFAULT 0 CHECK (x2 >= 0),
    options JSONB NOT NULL DEFAULT '{}'::jsonb
        CHECK (jsonb_typeof(options) = 'object'),

    CONSTRAINT mapx_id_domain_key UNIQUE (i, dxi),
    CONSTRAINT mapx_code_shape CHECK (
        mpx BETWEEN 910000 AND 999999
        AND ((mpx / 10) % 10) BETWEEN 0 AND 3
        AND mpx % 10 = 0
    ),
    CONSTRAINT mapx_scope_shape CHECK (
        (((mpx / 10000) % 10) BETWEEN 1 AND 3 AND x2 = 0)
        OR (((mpx / 10000) % 10) BETWEEN 4 AND 9 AND x2 > 0)
    )
);

CREATE INDEX mapx_domain_idx ON mx.mapx(dxi);
CREATE INDEX mapx_type_idx ON mx.mapx(mpx);
CREATE INDEX mapx_x1_idx ON mx.mapx(x1);
CREATE INDEX mapx_x2_idx ON mx.mapx(x2) WHERE x2 > 0;
CREATE INDEX mapx_options_idx ON mx.mapx USING gin(options);
```

The MetaX fields record rule identity (`i`), last edit time in epoch milliseconds (`d`), editor (`e`), active status (`a`), domain (`dxi`), display name (`n`), and canonical code (`c`). Individual rules have their own `i` and `c` values, so the same two containers can have separate billing and shipping relationships.

## Rule examples

These examples use provisional operation codes and JSON keys.

### Table uniqueness

`910000` decodes as `9 | 1 | 00 | 0 | 0`.

```json
{
  "mpx": 910000,
  "x1": 100,
  "x2": 0,
  "options": {
    "columns": [101, 102, 103]
  }
}
```

ColumnX 101, 102, and 103 form one composite unique constraint on TableX 100. The array must be nonempty and contain distinct columns from that table. A one-column constraint uses a one-element array.

### Table ↔ Table foreign key

`940200` decodes as `9 | 4 | 02 | 0 | 0`.

```json
{
  "mpx": 940200,
  "x1": 200,
  "x2": 300,
  "options": {
    "column_pairs": [
      {"x1_column": 201, "x2_column": 301},
      {"x1_column": 202, "x2_column": 302}
    ],
    "on_delete": "restrict",
    "on_update": "cascade"
  }
}
```

TableX 200 references TableX 300. Each entry in `column_pairs` associates one referencing column with its target, and the array preserves pair order. Validate column ownership, type compatibility, the referenced key, and the allowed referential actions.

### Table ↔ Table relationship

For a one-to-many relationship, the operation can assign `x1` the one role and `x2` the many role. For example, one order can have zero or more order lines, and each order line belongs to one order. The options record the matching column pairs and the minimum participation on each end. Shared identity (`1~1`) and independent identity (`1:1`) have separate operation definitions.

A many-to-many bridge keeps the two main tables in `x1` and `x2`. Its options carry the bridge TableX ID and ordered column pairs for each hop from an endpoint to the bridge. A relationship can declare its referential requirement through the operation definition.

### Table ↔ Model value mapping

`973000` decodes as `9 | 7 | 30 | 0 | 0`.

```json
{
  "mpx": 973000,
  "x1": 300,
  "x2": 400,
  "options": {
    "pairs": [
      {"column": 301, "field": 401, "direction": "read_write"},
      {
        "column": 303,
        "field": 403,
        "direction": "read",
        "transform": {"type": "cast", "target": "text"}
      }
    ]
  }
}
```

The pairs associate ColumnX IDs of TableX 300 with FieldX IDs of ModelX 400. Each pair can carry its own read or write direction and transformation. The operation must specify the allowed directions and how it validates the transform.

### ModelX linkage preview

Scope 7 MapX rules own the links between TableX and ModelX. Each rule puts the TableX ID in `x1`, the ModelX ID in `x2`, and the link details in `options`. `ModelX.txis` is a read-only `BIGINT[]` preview of the distinct `x1` IDs of usable scope 7 rules with `x2 = ModelX.i`. The database returns IDs in ascending order and uses `[]` when there are no links. Authors edit links in MapX.

For example, active rules linking TableX `100` and `200` to ModelX `400` yield `"txis": [100, 200]`. Multiple rules linking the same table and model contribute one ID. QueryX selects the rules, table occurrences, and joins for each operation.

Use `973000` for links with one or more column-to-field pairs. Use `971600` with `options = {}` for a table association without field pairs. PostgreSQL allows one active `971600` rule per table and model pair. [ModelX implementation boundaries](../architecture/modelx-composition.md#implementation-boundaries)

### FieldX linkage preview

MapX owns column-to-field links and their mapping details. `getfieldx` returns `FieldX.cxis` as a read-only preview of distinct usable `ColumnX.i` values in the same domain, ordered by ID. It returns `[]` when there are no usable links. Authors edit links in MapX, and the next field read reflects the change.

The preview can include columns from several rules. QueryX selects the applicable rule and source occurrence. The selected rule defines direction, transformations, and any operand order. For example, a future computed rule for `name` could use `firstname` (`101`) followed by `lastname` (`102`) with a space as the separator. The preview would show `[101, 102]`, and the ordered expression would live in the rule's `options`. The registered `973000` operation describes individual column-to-field pairs. A getter can calculate `name` directly until a reusable multi-column operation is defined.

The fresh SQL schema refreshes the stored `cxis` preview from the canonical rules. Import planning follows MapX to discover dependencies. [FieldX CRUD](../../../db/aix/functions/fieldx_crud.sql) · [Import dependency planner](../../../db/aix/functions/metax_import_plan.sql)

### Model ↔ Query input binding

`992000` decodes as `9 | 9 | 20 | 0 | 0`. Here ModelX 400 supplies two input fields to QueryX 500. The input operation defines how selected fields are exposed and how they are bound to query uses.

```json
{
  "mpx": 992000,
  "x1": 400,
  "x2": 500,
  "options": {"fields": [401, 403]}
}
```

## QueryX uses

QueryX selects the MapX rules it uses. It owns the table occurrences, aliases, and join types for the operation. A query binding needs a stable way to reference the intended table occurrence as well as the column.

For example, `getOrderSummary(orderId)` can join Customer once for billing and once for shipping. QueryX selects the shipping relationship and associates it with a distinct occurrence such as `shipping_customer`. The projection reads `Customer.name` through that occurrence to populate `OrderSummary.shippingCustomerName`. A filter on `Order.id` uses the query's `orderId` ParamX and records the target occurrence, target ColumnX, and comparison operator. The storage and reference format for occurrence IDs remains a QueryX design decision. [Mapping and QueryX discussion](../../aix/architecture/2026-11-18-mapping-and-queryx.md)

## Validation and CRUD

The replacement write path validates the complete resulting rule before saving it. A consumer also checks that its references are active and usable before generating SQL or applying the rule.

- Resolve each positive container ID against the catalog specified by `S` and enforce domain access.
- Require a registered MapX code and an operation definition for its scope. Validate the required option keys, JSON value types, and parameter count.
- Validate the ownership of rule items through their containers, including `ColumnX.txi`, `FieldX.mxi`, and `ParamX.qxi`. Apply the catalog's visibility rules to shared ConstX values.
- Check ordered pairs, data type compatibility, referenced keys, and duplicates as required by the operation. Named rules with different join pairs may use the same containers.
- Define dependent-rule handling for changes to a container or mapped item. Changes to a referenced rule's meaning require a new rule ID or an atomic update and revalidation of its dependents.

`getmapx(jsonb)` should support lookup by rule ID or canonical code, listing by domain, scope, exact `mpx`, or container, and a capability probe for clients. Container filters use the expected type and position from the scope. Define item lookup for each operation's option paths so callers can find rules by ColumnX, FieldX, or ParamX.

`setmapx(jsonb)` uses `i = 0` for creation and a positive `i` for updates. Creation allocates the rule ID and canonical code through the MetaX write path. Updates preserve omitted fields and validate the resulting rule. Write the row and its options atomically, derive the editor from the authenticated context, and enforce domain authorization.

## Implementation status

Fresh JCore installs now create `mx.mapx`, register TypeX Group 12 and the initial operations above, validate typed JSONB items, expose `getmapx`/`setmapx`, and store QueryX rule selections as `mapx_ids`. Authorization and import dependency inspection use MapX.

The initial validators cover the registered operations. Query occurrence identity and complete SQL emission semantics still need a separate design pass before every rule can generate production SQL. This is a fresh-install replacement; it does not migrate existing data.

## Related documentation

- [JCore reference index](../README.md)
- [Column Type reference](column-types.md)
- [TypeX catalog](typex-catalog.md)
- [Query system](../architecture/query-system.md)
- [ModelX composition and read mapping](../architecture/modelx-composition.md)
- [JCore taxonomy](../architecture/taxonomy.md)

## Changelog

- **2.0, 2026-11-18** — Defines the unified MapX registry, six-digit encoding, nine ordered container scopes, and JSONB operation payload.
- **1.0 draft, 2025-01-20** — Introduced the unified mapping registry and the original nine-digit proposal.
