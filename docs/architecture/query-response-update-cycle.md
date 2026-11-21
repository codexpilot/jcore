# JCore query response update cycle

> **⚠️ LEGACY DOCUMENTATION**: This document describes the JsonC format and base-plus-eight encoding scheme (`jnf = base + 8 * dateMode`) which has been removed from JCore. The current implementation uses JX with four-digit encoding (`encoding = J × 1000 + N × 100 + L × 10 + D`). See [JX body encoding](query-request-and-jsonc-encoding.md) for current architecture.

## Scope and baseline

Define one versioned query response for AIXHub and APIHub that ContextStudio and Dataset can decode through JCore. Carry the framework release, app release, data schema version, UX schema version, result identity, and one `jnf` value that controls numeric and temporal encoding. Deliver JCore’s contract, codec, and shared fixtures first. MJUX, the hubs, and the apps adopt that release in the order below.

Checked baselines for this handoff are JCore `d93c80f`, MJUX `075577c`, and AIX `325585f`. Merge against the current main branches when the implementation cycle starts. The wire names, offset of eight, and negotiation details below are the proposed defaults for implementation review.

## Response metadata

| Field | Meaning and source |
| --- | --- |
| `frameworkVersion` | One opaque framework release ID. Its release manifest pins the exact JCore and MJUX Git revisions and records their package versions. The response reports the compatible release selected for the app, using explicit compatibility rules. |
| `appVersion` | The selected ContextStudio or Dataset release and build, such as `0.1.0+1`. Scope it to the app identity in the verified client context. Keep the installed client build available independently for compatibility checks. |
| `jv` | The selected result schema’s integer revision. Preserve the existing epoch-seconds representation. Reserve each revision atomically per result identity. If a different schema already holds the current second, fail publication and retry in a later second. |
| `uxSchemaVersion` | The format version accepted by the `uidef` parser. The current value is `1`. Publish a separate `uxRevision` with the UX artifact and return it when serving a specific artifact, so content changes within the same format can trigger a refresh. |
| `jid` | Stable identity of the declared result schema across responses and request instances. Keep it a JSON integer in the JavaScript-safe range for the current Dart codec. |
| `jnf` | The selected encoding for typed number and temporal cells. Preserve base modes `0`–`5`, with `2` as the default when omitted. Encoding changes can share the same `jid` and `jv`. |

The QueryX projection is selected by its own published text version in JDB. Associate that projection with the resulting `(jid, jv)` in the published operation descriptor. Apply `jnf` to typed data cells only. The response version fields and IDs keep their own wire types.

In a tabular success, emit response metadata alongside the JSONC fields so the top-level shape extends the current JSONC object. Parse the common metadata at the response boundary and hand the tabular payload to `JsonC`. The operation descriptor declares tabular or composed output. A composed result carries its published object, array, or null under `data` with the same version metadata. Transform composed fields only where its published projection supplies the semantic type.

Sources for this contract are the [JSONC codec](../../dart/lib/src/data/jsonc.dart), [UIDef format](../../dart/lib/src/jux/uidef.dart), [QueryX request](queryx-redesign.md#runtime-request), and [published result projection](modelx-composition.md#publish-a-result-projection).

## JNF number and date encoding

Use one integer. The base retains the existing layout classification and number rules. The date axis selects the temporal wire representation.

~~~text
jnf = base + 8 * dateMode
base = jnf % 8
dateMode = jnf ~/ 8
~~~

| Base | Integer and decimal behavior | Integer dates and times | Text dates and times |
| --- | --- | ---: | ---: |
| 0 | Formal mode, INT64 and NUMERIC strings | 0 | 8 |
| 1 | Formal mode, both JSON numbers | 1 | 9 |
| 2 | JSONC, both JSON numbers | 2 | 10 |
| 3 | JSONC, INT64 strings | 3 | 11 |
| 4 | JSONC, NUMERIC strings | 4 | 12 |
| 5 | JSONC, INT64 and NUMERIC strings | 5 | 13 |

Accept `0`–`5` and `8`–`13`. Treat `6`, `7`, higher date modes, negative values, and nonintegers as invalid. In legacy JSONC, an omitted or null `jnf` selects mode `2`. The existing `JsonC` codec uses the JSONC object in all six modes, including the two classified as formal. Retain that object on the common route and preserve the existing classification accessors by applying them to the decoded base mode.

| Type | Date mode 0 | Date mode 1 |
| --- | --- | --- |
| `DATETIME` `40001` | UTC Unix epoch milliseconds as an integer | UTC RFC 3339 with exactly three fractional digits and `Z` |
| `TIME` `40002` | Integer milliseconds since midnight, `0`–`86399999` | `HH:mm:ss.SSS` with no timezone and hour `00`–`23` |

Apply both directions using schema type IDs. In Dart, normalize valid temporal wire values to integer milliseconds before passing records to JConverter or MJUX. Reject malformed text, impossible dates, invalid clock fields, and non-lossless conversions. Use Gregorian years `0001` through `9999` for date mode `1`. Reject leap seconds, offsets, missing millisecond digits, and `24:00`. Preserve the legacy integer representation for date mode `0`. Keep locale and timezone display policy in the UI. Calendar-only dates require a distinct semantic type in a later catalog change.

The test values `1704067200123` and `45296123` correspond to `2024-01-01T00:00:00.123Z` and `12:34:56.123`. The checked [type catalog](../reference/type-catalogs.md#date-and-time-storage) defines the canonical storage forms. The [existing JNF spec](../dart/JNF_ENCODING_SPEC.md) defines the base encodings.

## Common query route and negotiation

Both hubs use `POST /api/query/{q}` and bearer credentials. The optional `qn` selects an authorized direct child of the root. Forward the operation body with its declared `op`, `row`, or `rows` and preserve exact JSON numbers. AIXHub dispatches approved metadata or preview operations under its domain and operation permissions. APIHub dispatches installed JDB operations through the authenticated QueryHub contract.

The proposed request headers are `X-Framework-Version`, `X-App-Version`, `X-UX-Schema-Version`, optional `X-Data-Schema-Version` when the client requests a known schema revision, and optional `X-JNF` for the requested wire mode. The app identity and authorization come from verified context. The response reports the selected values. Omitted `X-JNF` uses `2` for compatibility. Web clients can request `5` for exact numbers or `13` for exact numbers plus text temporal fields. Extended modes require an upgraded client that explicitly requests one. Add browser preflight support for the headers and `qn`.

Reject an invalid or unsupported requested mode with HTTP 400 and the common structured error body. An unavailable requested version returns HTTP 409 and identifies the compatibility dimension in the error code. Use the existing AIXHub error shape with `code`, `message`, and `correlation_id`. Preserve the authorized operation’s payload and the selected version metadata through the HTTP adapter.

## Ordering and schema reuse

For tabular responses, publish an explicit ordered `columns` array alongside the typed `schema` map and build positional rows from that sequence. A new decoder verifies that `columns` contains each schema field exactly once. For older payloads without `columns`, use the existing serialized schema order. Keep legacy producer ordering aligned with the row sequence whenever legacy readers may receive the result.

Cache immutable schemas by `(authority, jid, jv)`, with domain or deployment scope when an authority can reuse IDs across domains. Reject a conflicting schema for the same tuple. A data-only response carries `jid`, `jv`, and `jnf` and must locate the exact cached schema before applying typed conversion. On a cache miss, retrieve the full or schema-only result and then decode the saved rows. Update `JBase.mergeWithSchema` and `JConverter.merge` together so they enforce the same identity and version checks.

## Reference response

This illustrative tabular response uses JSONC base `5` and text temporal encoding. The schema order deliberately differs from lexical key order.

~~~json
{
  "frameworkVersion": "2026.11.21.1",
  "appVersion": "0.1.0+1",
  "uxSchemaVersion": 1,
  "jv": 1795219200,
  "jid": 5011,
  "jnf": 13,
  "columns": ["observed_at", "id", "time", "amount"],
  "schema": {"observed_at": 40001, "id": 40000, "time": 40002, "amount": 60000},
  "data": [["2024-01-01T00:00:00.123Z", "9007199254740993", "12:34:56.123", "1234.56789"]]
}
~~~

The [shared JNF vectors](query-response-vectors.json) provide exact expected wire cells for all twelve modes, the default, temporal boundary values, and invalid input. The companion mode `5` row is `[1704067200123, "9007199254740993", 45296123, "1234.56789"]` with the same identity and versions. Also publish a reordered schema map with the same `columns` and rows to verify that typed decoding uses the declared order.

## Implementation sequence

1. **JCore.** Record the selected wire contract in the JNF and QueryX specs. Centralize mode decoding in `dart/lib/src/data/jsonc.dart` and apply it to numeric flags, layout classification, parsing, serialization, and validation. Carry the metadata and ordered schema through the common response parser. Audit construction, copies, `JConverter` validation and split/merge, and `JBase` register/resolve paths. Add golden fixtures and a Go codec with exact-number support under the JCore Go module. Keep shared fixtures available to all producers, including PostgreSQL-backed ones.
2. **MJUX.** Update `lib/src/mapping/jsonc_form_binding.dart` to accept JCore’s expanded modes and round-trip normalized DATETIME and TIME. Use JCore’s mode parser for validation and preserve `jnf` and schema order across form snapshots and saves. Pin the verified JCore revision and regenerate the package and example dependency resolution using portable paths.
3. **AIXHub and APIHub.** Adopt the same response contract for the new route where each service supports it. Replace the stale route executors with authorized service-specific dispatch. Keep the legacy `number_format` session enumeration independent from `jnf` and migrate the legacy `dataspec` / `frameworkspec` client explicitly. Validate JSONC column order through the actual database and HTTP path.
4. **ContextStudio and Dataset.** Share the response decoder. Resolve framework compatibility from the release manifest, app compatibility from the app version, UX refresh from the UX artifact, and data-schema refresh from `(authority, jid, jv)`. Verify one authorized AIXHub preview and one APIHub published read through their normal entry points. Publish and pin the exact JCore/MJUX pair and verify that both consumer lockfiles resolve it.

The AIX baseline has ContextStudio locked to JCore `a362b63` and MJUX `075577c`. Dataset’s lock resolves JCore `2718fe5` and its manifest lacks MJUX. The checked MJUX manifest points to JCore `main` and its lockfiles still contain an absolute local JCore path. Use clean dependency resolution to verify the proposed release pair. These baselines are inspectable in each repository’s `pubspec.yaml` and `pubspec.lock` at the revisions above.

## Acceptance checks

- **Legacy fixtures.** With `jnf` omitted and in all six base modes, sample input and output preserve the current JSONC shape, exact number rules, and temporal integers. Existing app and package tests still pass on their pinned versions.
- **Extended fixtures.** Every base mode paired with date mode `1` preserves the same numeric behavior. Cover INT64 above JavaScript’s safe integer range, exact NUMERIC, the reference response, negative epoch time, leap-day values, midnight, the last millisecond of day, and malformed temporal values. Assert the same decoded values in Dart VM, Dart web, and Go.
- **Strict input.** Reject `-1`, `6`, `7`, `14`, unknown date modes, noninteger mode values, invalid dates, and out-of-range TIME. Verify empty data, schema-only data, mixed typed rows, and that temporal formatting preserves the existing null policy.
- **Schema revisions.** Decode two versions under one `jid`, reject mismatched schema merge and conflicting registration, recover a data-only cache miss, and prove that out-of-order delivery does not replace a valid older schema. Prove that schema-key reordering leaves field bindings correct with explicit columns.
- **Transport.** Verify both hubs return identical contract semantics for success, empty results, and structured errors. Test an authorized root and child, denied access, malformed JSON, old-client mode selection, browser preflight, and the end-to-end precision fixture.
- **Release.** Compare release manifests and clean-lockfile resolutions against the exact pair. Test independently changing the framework, app, UX artifact, and result schema. Confirm every refresh or compatibility action uses its own version.

Run `dart analyze` and `dart test` from JCore `dart/`, `go test ./...` from JCore `go/` and each hub module, and `flutter analyze` and `flutter test` from MJUX, ContextStudio, and Dataset. Run an actual browser test for the numeric and temporal wire vectors and a database-backed test of both common routes. Record command output and exact resolved Git revisions in the cycle handoff.
