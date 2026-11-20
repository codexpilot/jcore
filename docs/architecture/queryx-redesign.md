# QueryX redesign

**Design draft · 2026-11-19**

The target runtime uses QueryX as the operation registry in JDB. APIHub exposes `/api/query/{q}` for registered operations. PostgreSQL’s `query_hub` resolves the route, checks access, and calls the registered PostgreSQL function. Each distinct operation has its own QueryX ID, function name, and ParamX contract.

## Registry hierarchy

| Field | Meaning |
| --- | --- |
| `i` | Positive QueryX ID. The URL supplies the main query ID `q`. The optional header supplies the child ID `qn`. |
| `c` | Name of the installed PostgreSQL function for this QueryX. |
| `p` | Parent QueryX ID. `0` marks a root operation. A subquery stores its immediate parent’s `i`. |

Every TableX has a root `get_<tablex.c>` for retrieval and a root `set_<tablex.c>` for inserts and updates. Both have `p = 0`. A table can use these functions on their own or add named subqueries for operations that need different inputs or behavior.

| `i` | `c` | `p` | Operation |
| ---: | --- | ---: | --- |
| `100` | `set_customers` | `0` | Standard customer mutation |
| `101` | `upsert_customers_by_code` | `100` | Upsert using a unique customer code |
| `102` | `deactivate_expired_customers` | `100` | Update customers matching an expiry condition |
| `200` | `get_customers` | `0` | Standard customer retrieval |

This is overloading at the API route level. `/api/query/100` exposes the default mutation and the named operations selected by `qn`. A nonzero `qn` is the child’s actual `QueryX.i`. The parent field can represent nested relationships. The HTTP contract in this draft resolves a root and at most one direct child per request.

## Runtime request

1. **HTTP client** calls `/api/query/{q}`. It can send a `qn` header to select a subquery. An omitted header or `qn = 0` selects the main query’s default behavior.
2. **APIHub (Go)** extracts `q` from the URL and collects the credential, framework version, app version, data contract version, UX contract version, terminal number, and requested `qn` as `user_context`. It passes `q`, `user_context`, and the whole request body as separate inputs in one PostgreSQL call.
3. **JDB `query_hub`** authenticates the caller and resolves the active root and optional child in one QueryX statement. An explicit nonzero `qn` must resolve to an active QueryX in the same domain with `p = q`. An invalid selection fails before execution. QueryHub authorizes access to the selected route, including the child where present, and adds verified caller and route information to `user_context`. For a child, that includes its resolved ID and function name from QueryX.
4. **The main PostgreSQL function** receives the updated `user_context` and the whole body. QueryHub invokes the function named by the main query’s `c`. The main function interprets the body and handles the selected operation or calls an internal function as needed. The resolved child information is already in context.

For `/api/query/100` with `qn = 101`, QueryHub resolves `100` and `101`, then invokes `set_customers`. That function uses the authorized child in context to handle the upsert. APIHub and QueryHub pass the body through as a whole. The table function owns extraction and validation of operation arguments.

### Request body

| Key | Meaning |
| --- | --- |
| `op` | Optional named ParamX values for the selected operation. For example, an expiry mutation can declare a `cutoff_date` argument. |
| `row` | One row object, with keys matching the actual database column names. |
| `rows` | An array of row objects in the same shape. |

ParamX defines the operation’s accepted arguments. ColumnX defines column names and types for table row data. A batch can be described as one structured input. The dedicated function reads the fields it needs. A mutation that selects rows by a condition can declare its own typed ParamX inputs and accept `op` without row data.

## Standard table mutation

- A zero numeric ID or the all zero UUID (`00000000-0000-0000-0000-000000000000`) requests an insert, according to the table’s ID type.
- A nonzero ID identifies the existing row to update.
- TableX’s table type determines how to generate a new ID. The policy can use an identity or sequence, a supported ID algorithm, or a configured query or custom generator through the main ID generation function.
- An explicit upsert matches a declared unique business key. A match updates the existing row and keeps its ID. Without a match, the mutation creates a row using the table’s ID generation policy. For example, `upsert_customers_by_code` can match a declared unique customer code.
- Some operations accept a single row per request. Others support a batch, including batch updates by ID.

These examples use a table whose ID and name columns are `i` and `name`. The first request inserts one row on the default route.

```json
{
  "row": {"i": 0, "name": "New customer"}
}
```

The second request updates two rows by ID using a setter that supports batches.

```json
{
  "rows": [
    {"i": 42, "name": "Updated customer"},
    {"i": 43, "name": "Another customer"}
  ]
}
```

## Open decisions

| Area | Question or initial proposal |
| --- | --- |
| Context and signature | Finalize the exact PostgreSQL function signature, the context fields shared by all operations, and any additional context fields. The header carries `qn` as routing metadata. |
| Row shape | For the default setter, require exactly one of `row` or a nonempty `rows`, and treat `row` as a batch of one internally. Confirm missing or null ID handling and how omitted fields and explicit nulls behave on updates. |
| Batch policy | Define where the row limit is stored and whether a batch can mix inserts and updates. The initial proposal is one transaction per request. |
| Upsert and results | Define how an operation declares its match key, its conflict behavior, and the response format for generated IDs and batch errors. |
| Registry publication | Confirm that the authorized dispatcher uses the exported QueryX hierarchy and ParamX registry and selects the published projection for the requested data-contract version. |

The AIX registry stores `p = 0` for roots and checks that a child has a same-domain parent. AIX publishes immutable ModelX result projections, and the JDB export installs their versioned lookup. The runtime context and authorized dispatch signature remain open decisions. [QueryX schema](../../../db/aix/tables/queryx.sql) · [JDB export](../../../db/jdx/jdx_export.sql)

## Runtime acceptance

- An authorized request reaches the root getter with its verified context and exact business body. Authentication, authorization, and child selection fail before execution for invalid credentials, denied access, or an unavailable or unrelated `qn`. Header selection reaches the root as verified child metadata.
- The flat getter returns its declared ModelX output through the same runtime route.
- A sale order returns `items: []` when it has no items and one item per matching row when it has multiple items. Other collections leave those item counts unchanged.
- A `one` section yields its object for one match and `null` for zero matches. A second match raises a cardinality error.
- Two sections can reuse the same component ModelX, such as billing and shipping addresses. Each resolves its own source occurrence and correlation.
- An edit to live MapX leaves the published result shape stable for callers requesting an existing version. Republishing under a new version changes the selected projection only for requests for that version. QueryHub returns the composed payload intact.

## Related documentation

- [Query system](query-system.md)
- [ModelX composition and read mapping](modelx-composition.md)
- [MapX design](../reference/mapx-design.md)
- [Mapping and QueryX discussion](../../aix/architecture/2026-11-18-mapping-and-queryx.md)
