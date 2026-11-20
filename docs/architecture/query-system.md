# AIX query system

AIX authors operation metadata in QueryX, argument definitions in ParamX, SQL implementations in SQLX, and explicit bindings in MapX. JDB receives registry metadata and published result projections through JDX. The [QueryX redesign](queryx-redesign.md) specifies the target APIHub and PostgreSQL runtime flow.

## QueryX registry

| Member | Contract |
| --- | --- |
| `i`, `dxi` | Positive operation ID and domain |
| `c` | Immutable PostgreSQL function name. The registry accepts lowercase, unqualified names that fit a PostgreSQL identifier. |
| `p` | `0` for a root. A child stores its immediate parent's positive QueryX ID. The parent must already exist in the same domain, and the parent assignment is immutable. |
| `target_kind` | `system`, `table`, or `model`, paired with a matching Group 8 `qtx`. |
| `table_id`, `model_id` | The applicable same-domain target ID. A system query has neither. |
| `role` | Optional designation `table_input`, `table_output`, `model_output`, or `operation`. Only one active query holds each designated input/output role per target. |
| `mapx_ids` | Explicit MapX rule IDs selected for the operation. |
| `input_fields`, `output_fields` | FieldX IDs for a model operation's input and output, checked against field capabilities. |
| `is_single`, `is_paged`, `requires_id` | Operation shape and argument requirements. |

The query type identifies system, table, or model Get/Set behavior. A separate QueryX child can describe a specialized operation, such as business-key upsert. The proposed HTTP header `qn` selects at most one direct child of the root in the URL. [QueryX schema](../../../db/aix/tables/queryx.sql) · [QueryX CRUD](../../../db/aix/functions/queryx_crud.sql) · [Query types](../reference/query-types.md) · [QueryX redesign](queryx-redesign.md#registry-hierarchy)

## ParamX and SQLX

A ParamX belongs to one QueryX through `qxi`. AIX enforces same-domain ownership and unique argument code `c` within that query. The setter derives the domain from QueryX. `ptx` records the argument's purpose, `dtx` its value type, `direction` its flow, and `req` whether it is required. `metadata` is an object for defaults and operation-specific constraints. The dedicated operation interprets these declarations through the runtime contract. [ParamX schema](../../../db/aix/tables/paramx.sql) · [ParamX CRUD](../../../db/aix/functions/paramx_crud.sql) · [Parameter types](../reference/parameter-types.md)

SQLX stores the SQL body in `s`. Its key `(qxi, dbt)` selects one implementation for the QueryX and database type. QueryX's `c` names the function used by the proposed dispatch contract. [SQLX schema](../../../db/aix/tables/sqlx.sql)

## MapX dependencies and published output

A QueryX selects MapX dependencies through `mapx_ids`. Table queries can bind columns to parameters or select table joins. A model query can bind input fields with `992000` and output fields with `992100`. A model's section structure uses explicit `951400` rules, and its field mappings use `973000`. [Query dependency validation](../../../db/aix/functions/queryx_helpers.sql) · [MapX operations](../reference/mapx-design.md)

An active model getter (`qtx = 520000`) can publish a projection through `publish_queryx_result_contract(qxi, version, binding_id, sections)`. The selected `992100` rule must name that operation and its result model. A published snapshot pins the output fields, section paths, source occurrences, correlation columns, and collection order. JDX exports the snapshots to JDB, where an authored getter can read one with `metax.get_queryx_result_contract(qxi, version)`. [Projection publication](../../../db/aix/migrations/queryx_result_contract.sql) · [ModelX result projections](modelx-composition.md#publish-a-result-projection) · [JDB export](../../../db/jdx/jdx_export.sql)

## Proposed runtime dispatch

The runtime design passes the credentials, versions, terminal number, optional child QueryX ID, and unmodified body from APIHub to PostgreSQL. QueryHub authenticates the request, resolves the root and optional child, and invokes the root function with verified context. The getter or setter interprets operation arguments and owns its payload. The dispatch signature, shared runtime context, write conflict and batch policies, and authored composed getter implementations remain runtime work. [QueryX runtime contract](queryx-redesign.md#runtime-request)
