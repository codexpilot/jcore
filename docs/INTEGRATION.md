# JCore integration

The Dart package root is dart. The package name stays jcore, so
applications continue to use import 'package:jcore/jcore.dart'.

Data, including the data type registry, Numeric, JNLD codec, and validation,
is implemented in Dart. JUX, JSYNC, and other language implementations remain
planned.

## Add the Dart package

For a local checkout beside an application:

~~~yaml
dependencies:
  jcore:
    path: ../jcore/dart
~~~

For a Git dependency:

~~~yaml
dependencies:
  jcore:
    git:
      url: https://github.com/codexpilot/jcore.git
      ref: main
      path: dart
~~~

The Git dependency path requires a repository revision at the selected ref
that contains dart/pubspec.yaml.

## Use the data type registry

~~~dart
import 'package:jcore/jcore.dart';

final smallintId = DataType.smallint.id; // 20000
final numericId = DataTypeRegistry.encodeNumeric(precision: 10, scale: 2); // 61002
final textId = DataTypeRegistry.encodeText(length: 100); // 70100

assert(DataTypeRegistry.isValid(smallintId));
assert(DataTypeRegistry.postgresType(numericId) == 'numeric(10,2)');
assert(DataTypeRegistry.postgresType(textId) == 'varchar(100)');
~~~

To import only the data layer:

~~~dart
import 'package:jcore/data.dart';
~~~

The previous `package:jcore/jdata.dart` entry point is deprecated and
re-exported for compatibility.

`DataType` represents the base types in the current catalog. Its first decimal
digit identifies an ordered storage-size class, not always a literal byte
count. Parameterized IDs use 60000 + precision * 100 + scale for NUMERIC and
70000 + length for TEXT. SMALLINT accepts values from -32768 through 32767.

The existing AIX Group 3 APIs remain available separately. JCore does not
translate Group 3 IDs to current catalog IDs or migrate persisted schemas.

## Scope record access to a database session

Create a `DbContext(queryService: service)` for each active session and inject
it into the consumers. Call `activate` with validated models and schemas. For
composed queries, pass a `JxResultProjection` keyed by the effective QueryX ID
for each fetch or save. Supply its published version, ordered fields, and
section tree. Each occurrence has its own schema and cardinality. The host
supplies this metadata before issuing a query.

Use `context.openForEdit(row, modelId: id)` or
`context.openForCreate(modelId: id)` for a session-bound draft. An edit uses the
record identity and version returned by the query. Capture the version as an
integer in the response's `v` field when the server supports optimistic
concurrency. Changing the service, replacing metadata, or clearing the context
invalidates pending results and bound drafts.

Use `context.models.byCode(code)` for stable model lookup and
`row.byCode(code)` for a wire-keyed column. `row.byId(id)` uses the FieldX or
ColumnX metadata ID, and `row.byName(name)` uses the exact display name.
`row[0]` still reads by position. A missing column and an explicit null both
return null through the named lookup methods. Use the schema's `indexByCode`
when the distinction matters. The schema and row constructors copy their
ordered collections.

## Read a flat query as a table

Use `JxQueryService` for a transport that can return a raw tabular JX
response. In its `executeJxQuery` method, return a `JxQueryResponse` with the
original response text and the selected JX encoding. Pass the HTTP body text
through before JSON decoding so the JX codec can preserve exact numbers.

Use `db.fetchTable` to decode and hold one result in a `JxTable`. It owns
one ordered `JxSchema` and one positional row matrix. Use the schema from the
active query projection or pass the exact ordered schema for a query without
one. The caller controls the table's lifetime.

~~~dart
final table = await db.fetchTable(
  queryId: queryId,
  schema: resultSchema,
  params: {'limit': 100},
);

for (var row = 0; row < table.rowCount; row++) {
  final amount = table.byCode(row, 'total_amount');
  // Render the cell.
}
~~~

`cellAt(rowIndex, columnIndex)` reads by position. `byId`, `byCode`, and
`byName` resolve the column with the shared schema. `rows` exposes a read-only
view of the matrix. Use `fetchRecord` for individual and composed records and
for opening an edit draft.

## Develop and verify JCore

From the repository root:

~~~bash
cd dart
dart test
dart analyze --fatal-infos
~~~

The full package layout and module status are documented in the
[architecture overview](architecture/README.md).
