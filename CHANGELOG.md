## 3.1.2

- Complete removal of legacy 300000-series data type IDs from entire codebase.
- Remove all legacy documentation files containing outdated ID references.
- Update all tests, code examples, and current documentation to use registry IDs (10000-80000 series).
- Fix NUMERIC and TEXT parameterized type encodings in all examples.
- All 112 tests passing with zero analysis issues.

## 3.1.0

- Remove CUID from the data type registry and documentation.

## 3.0.9

- Add the data type registry, SMALLINT validation, and parameterized
  NUMERIC/TEXT IDs.
- Add exact scale-preserving Numeric arithmetic, JSONC number-mode output,
  and the existing value validation behavior.
- Move the Dart package to /dart while retaining the jcore package name and
  public import.
- Gather documentation under /docs and add the requested language folder
  structure, with unimplemented language ports marked as coming soon.
- Expose registry operations through DataTypeRegistry without changing the
  assigned IDs or behavior.
- Keep JUX, JSYNC, and other language implementations planned.

## 2.0.0

- Enforce numeric precision and scale, and signed INT32 and INT64 ranges.
- Convert INT64 values according to JSONC number-format modes and preserve
  those modes when merging data with schemas.
- Document PostgreSQL response handling and the package version policy.

## 1.0.0

- Initial version.
