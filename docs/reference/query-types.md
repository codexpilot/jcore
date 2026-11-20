# Query types

TypeX Group 8 classifies QueryX operations by target family and Get/Set behavior. The fresh AIX schema accepts the following IDs. [Type seed](../../../db/aix/seed/seed.sql) · [QueryX schema](../../../db/aix/tables/queryx.sql)

| `qtx` | Code | Target kind | Behavior |
| ---: | --- | --- | --- |
| 500000 | `system_get` | `system` | Read domain-scoped system data |
| 500001 | `system_set` | `system` | Write domain-scoped system data |
| 510000 | `table_get` | `table` | Read a TableX |
| 510001 | `table_set` | `table` | Write to a TableX |
| 520000 | `model_get` | `model` | Read through a ModelX |
| 520001 | `model_set` | `model` | Write through a ModelX |

The result shape uses QueryX operation metadata and, for published model output, a versioned result projection. Named subqueries use their own QueryX IDs and point to their parent through `p`. [Query system](../architecture/query-system.md) · [ModelX result projections](../architecture/modelx-composition.md#publish-a-result-projection)
