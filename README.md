# JCore

JCore is a multi-language foundation for data types, exact numeric values,
jsonc, UI bindings, catalogs, and synchronization. It serves as the **source of truth** for AIX MetaX taxonomy and type definitions.

**Current jcore version:** `v4.1.0`

## Current implementation

The Dart `jcore` package lives at [`dart`](dart). Its public package name and
import remain `jcore` and `package:jcore/jcore.dart`; jdata is implemented
there. The Go MetaX models live at [`go/metax`](go/metax) and are published
through the [`go`](go) module. jux, jsync, and other language implementations
remain planned.

## Language folders

- `dart` — current jdata implementation.
- `go` — current MetaX model implementation.
- `pgsql`, `javascript`, `java`, `swift`, `csharp`, and `cplusplus` — coming
  soon.

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
[architecture overview](docs/architecture/README.md). For the Go MetaX
models, see the [Go package README](go/metax/README.md).
Browse the documentation index in [docs/README.md](docs/README.md).
Contributor credit is listed in [CONTRIBUTORS.md](CONTRIBUTORS.md).

## MetaX Taxonomy

JCore defines the canonical taxonomy for AIX MetaX systems:

**10 Core MetaX Types:**
1. **DomainX** - Domain hierarchy and scope configuration
2. **TypeG** - Type group catalog (organizes types into semantic categories)
3. **TypeX** - Type catalog (all system types with group-based ID construction)
4. **TableX** - Physical table metadata
5. **ColumnX** - Physical column metadata
6. **ModelX** - Logical model metadata
7. **FieldX** - Logical field metadata
8. **QueryX** - Query operation metadata
9. **ParamX** - Query parameter metadata
10. **SqlX** - SQL template metadata

**Taxonomy Documentation:**
- **[ID Patterns](docs/taxonomy/ID-PATTERNS.md)** - Singular/plural ID naming (dxi/dxis, mxi/mxis, etc.)
- **[System Columns](docs/taxonomy/SYSTEM-COLUMNS.md)** - Standard column definitions (i, d, e, a, etc.)
- **[Parent Rules](docs/taxonomy/PARENT-RULES.md)** - Self-referential p/ps architectural rules
- **[Type Patterns](docs/taxonomy/TYPE-PATTERNS.md)** - Type suffix patterns (dtx, ttx, ctx, etc.)

These definitions are the **source of truth** for all AIX implementations.

## Verification

```bash
cd dart
dart test
dart analyze --fatal-infos
```
