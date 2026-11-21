# JNLD JSONC body encoding

Draft for the JCore codec used by Context Studio and Dataset. JCore is a shared library within the query architecture. The Database, Backend, and FrontEnd responsibilities and HTTP headers are defined in the AIX developer note at `docs/apihub/architecture/query-response-developer-note.md`.

## Codec inputs and body

The caller supplies the effective encoding and, for data-only compact results, the exact result schema. The body is `{"data": [...]}` or `{"meta": [...], "data": [...]}` according to the selected JNLD structure.

A scalar is one row with one cell. A single record is one row. Multiple records are multiple rows. For compact encodings, a scalar such as `42` is `{"data": [[42]]}`. For full JSON, it is `{"data": [{"count": 42}]}` using the operation's declared field code or name. An empty result is `"data": []`.

## JNLD encoding

The codec takes a four-digit `encoding` value. The default is `8000`, which selects full objects keyed by code, NUMERIC and INT64 strings, and ISO UTC timestamps.

~~~text
encoding = J × 1000 + N × 100 + L × 10 + D
~~~

### J — JSON structure

| J | Row structure | Metadata or keys |
| ---: | --- | --- |
| `1` | Compact positional rows | The codec uses the exact result schema supplied by the caller. |
| `2` | Compact rows with metadata | `FieldX.i` or `ColumnX.i` mapped to `TypeX.i`. |
| `3` | Compact rows with metadata | `FieldX.c` or `ColumnX.c` mapped to `TypeX.n`. |
| `4` (proposed) | Compact rows with metadata | `FieldX.n` or `ColumnX.n` mapped to `TypeX.n`. Names must be unique within the result. |
| `8` | Full JSON objects | Object keys use `FieldX.c` or `ColumnX.c`. |
| `9` | Full JSON objects | Object keys use `FieldX.n` or `ColumnX.n`. Names must be unique within the result. |

The operation's result schema determines whether to use FieldX or ColumnX. Compact metadata must retain the same order as the cells. The `meta` array is present for `J=2`, `J=3`, and proposed `J=4`. Each entry describes the corresponding column. The entry representation remains open. `J=1`, `J=8`, and `J=9` return only the `data` key. `J=4` is proposed because both metadata variants were originally assigned `3`. Full object results require unique keys within each object.

### N and L — Numeric values

| Digit | N for NUMERIC | L for INT64 |
| ---: | --- | --- |
| `0` | Decimal string | Integer string |
| `1` | JSON number | JSON integer |

Generate decimal strings from exact NUMERIC values. Generate INT64 numbers or strings using the exact signed value. Clients that parse JSON numbers with floating point can lose precision under `N=1` or `L=1`.

### D — Dates and times

| D | DATETIME wire representation |
| ---: | --- |
| `0` | ISO UTC timestamp with `Z`. |
| `1` | ISO timestamp in the server's local timezone, with its UTC offset. |
| `2` | ISO timestamp in the client's local timezone, with its UTC offset. |
| `8` | UTC Unix epoch milliseconds as a JSON integer. |

For `D=2`, the encoder needs the client's timezone. Resolve the offset for the timestamp being formatted. TIME represents a clock time. The proposed representation is `HH:mm:ss.SSS` in text modes and integer milliseconds since midnight in mode `8`. [JCore temporal storage types](../reference/type-catalogs.md#date-and-time-storage)

## Example body

For `8000`, the following body uses full objects keyed by code.

~~~json
{
  "data": [
    {
      "id": "9223372036854775807",
      "amount": "1234.50",
      "observed_at": "2024-01-01T00:00:00.123Z"
    }
  ]
}
~~~

For a native client, `encoding: 8018` keeps the same object keys, encodes NUMERIC as strings and INT64 as JSON integers, and sends timestamps in epoch milliseconds.

## Codec checks

- Verify scalar, single-row, multirow, and empty results all use the `data` array, and only metadata encodings add the ordered `meta` array.
- Verify `8000` and `8018` preserve the expected exact NUMERIC and INT64 representations. Verify timezone offsets, duplicate object keys, and the required schema for compact data-only results.
- JNLD replaces the earlier base-plus-eight proposal for this shared route. Update the encoder, decoder, and fixtures together. [Existing JSONC draft](../dart/JSONC_UPDATE_SPEC.md)
