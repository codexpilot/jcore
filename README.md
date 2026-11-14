# JCore

JCore is a multi-language foundation for data types, exact numeric values,
JSONC, UI bindings, catalogs, and synchronization.

## Current implementation

The Dart `jcore` package lives at [`dart`](dart). Its
public package name and import remain `jcore` and
`package:jcore/jcore.dart`. JData is implemented there. JUX, JSYNC, and other
language implementations remain planned.

## Language folders

- `dart` — current JData implementation.
- `pgsql`, `javascript`, `java`, `swift`, `csharp`, `cplusplus`, and `go` —
  coming soon.

Consumers that depend on JCore through Git should select the Dart package
subdirectory:

```yaml
dependencies:
  jcore:
    git:
      url: https://github.com/codexpilot/jcore.git
      ref: main
      path: dart
```

For the data type registry, package APIs, and Numeric behavior, see the
[Dart package README](docs/dart/README.md). For module boundaries and
future language organization, see the
[architecture overview](docs/architecture/README.md).
Browse the documentation index in [docs/README.md](docs/README.md).
Contributor credit is listed in [CONTRIBUTORS.md](CONTRIBUTORS.md).

## Verification

```bash
cd dart
dart test
dart analyze --fatal-infos
```
