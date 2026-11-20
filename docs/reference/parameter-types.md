# Parameter types

`ParamX.ptx` references TypeX Group 9 and identifies a parameter's purpose. `ParamX.dtx` identifies its value type through TypeX Group 3. `qxi` identifies the owning query, and `c` names the argument within that query. [ParamX schema](../../../db/aix/tables/paramx.sql) · [Data types](data-types.md)

| `ptx` | Purpose |
| --- | --- |
| 600001–600012 | Operation, mode, limit, offset, order-by, sort direction, include, fields, validate only, return full, count, and upsert controls, in ID order |
| 600100–600112 | Filter, search, ID, foreign key, range start, range end, boolean, enum, array, JSON, date, timestamp, and calculated data parameters, in ID order |

The default `ptx` is `600100` (filter). `direction` defaults to `input` and also accepts `output` and `both`. `req` is independent of purpose and defaults to false. `metadata` is a JSON object for defaults and operation-specific constraints such as an enum or range. [Parameter seed](../../../db/aix/functions/typex_group9_param_types.sql) · [ParamX CRUD](../../../db/aix/functions/paramx_crud.sql)

An operation chooses its accepted arguments and their types. A MapX rule may refer to ParamX IDs in that operation's scope. In the proposed runtime request, input values appear in the `op` object under the declared argument codes. [MapX specification](mapx-design.md) · [QueryX request body](../architecture/queryx-redesign.md#request-body)
