# ModelX types

`ModelX.mtx` references a TypeX Group 6 entry in `300000–399999`. The stored value is an integer, the TypeX key is `mtx - 300000`, and the default is `320000`. New assignments reference active Group 6 entries. [ModelX schema](../../../db/aix/tables/modelx.sql) · [TypeX seed](../../../db/aix/seed/seed.sql)

## Claim type encoding

The encoding is `3xnnnnn`. The claim type digit `x` is the only semantic dimension, describing the ownership relationship between models and tables. The `nnnnn` portion is sequential numbering (00000-09999) with no additional semantic meaning.

| `x` | Family | Claim relationship |
| ---: | --- | --- |
| 0 | `30xxxx` | Unclaimed model. No table ownership claim. |
| 1 | `31xxxx` | Table-claimed-model. Table owns/claims the model. |
| 2 | `32xxxx` | Model-claimed-table. Model owns/claims the table. |
| 3 | `33xxxx` | Tables-claimed-model. Multiple tables claim the model. |
| 4 | `34xxxx` | Model-claimed-tables. Model claims multiple tables. |
| 9 | `39xxxx` | System model. System/framework models. |

QueryX's explicit type and bindings determine operation direction. Automatic model-first storage supports `320000`. [ModelX validation](../../../db/aix/functions/modelx_mt_validation.sql) · [ModelX CRUD](../../../db/aix/functions/modelx_crud.sql) · [Query types](query-types.md)

The getter and its MapX rules determine the number of table sources. Active `951400` rules determine whether a ModelX has named sections. Each rule specifies the section cardinality. QueryX defines the operation and the top-level result multiplicity. [ModelX composition and read mapping](../architecture/modelx-composition.md)

## Seeded claim type examples

| `mtx` | TypeX name | TypeX code | Claim type |
| ---: | --- | --- | --- |
| 300000 | Unclaimed Model | `claim_0` | 0 |
| 310000 | Table Claimed Model | `claim_1` | 1 |
| 320000 | Model Claimed Table | `claim_2` | 2 |
| 330000 | Tables Claimed Model | `claim_3` | 3 |
| 340000 | Model Claimed Tables | `claim_4` | 4 |
| 390000 | System Model | `claim_9` | 9 |

The TypeX names are the seeded display labels. ModelX type validation checks catalog membership and activity. MapX and the selected QueryX determine storage associations, sections, and result shape. [Type validation](../../../db/aix/functions/modelx_mt_validation.sql) · [ModelX composition](../architecture/modelx-composition.md)
