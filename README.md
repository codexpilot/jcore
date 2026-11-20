# JCore

JCore is a multi-language foundation for data types, exact numeric values,
jsonc, UI bindings, catalogs, and synchronization. It serves as the **source of truth** for AIX MetaX taxonomy and type definitions.

**Current jcore version:** `v4.4.0`

## What's New in 4.4.0

**Data Module Migration** - The former `jdata` Dart module is now named `data`.
Use `package:jcore/data.dart` for direct data API imports. The legacy
`package:jcore/jdata.dart` entry point remains as a deprecated compatibility
re-export.

## What's New in 4.2.0

**JUX UI/UX Framework** - Complete metadata-driven UI framework with reactive ViewModels that work with dynamic schemas without code generation. See [JUX Framework](#jux-framework) below.

## Current implementation

The Dart `jcore` package lives at [`dart`](dart). Its public package name and
import remain `jcore` and `package:jcore/jcore.dart`.

**Implemented:**
- **data** - Data types, exact numeric values, JSONC, and QueryService interface
- **metax** - MetaX models (Go and Dart implementations)
- **jux** - UI/UX framework with reactive ViewModels (Dart)

**Planned:**
- jsync and other language implementations

The Go MetaX models live at [`go/metax`](go/metax) and are published
through the [`go`](go) module.

## Language folders

- `dart` — current data implementation.
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

## JUX Framework

**JUX** (JCore UI/UX) is a metadata-driven UI framework that enables building reactive interfaces for dynamic schemas without code generation.

### Architecture

```
JUX (Presentation) → Data → Backend
   ViewModels         QueryService    HTTP/DB
```

### Core Components

**1. QueryService (data)**
- Abstract interface for data operations
- Applications implement for their specific backends
- Query-based pattern: operations identified by integer IDs

**2. ViewModels (jux)**

Three reactive ViewModels that work with ANY model defined through MetaX:

- **ViewModel** (Base) - Reactive state management
  - Loading and error states
  - ChangeNotifier for automatic UI updates
  - Pure Dart (testable without Flutter)

- **JuxFormViewModel** - Edit views
  - Validation and dirty tracking
  - Metadata-driven type coercion
  - Save/discard operations

- **JuxCollectionViewModel** - List views
  - Pagination and search
  - Filtering and selection
  - Display value formatting

- **JuxInspectionViewModel** - Read-only detail views
  - Single record display
  - Lightweight (no editing logic)

### Key Features

- ✅ Works with ANY model created in ContextStudio
- ✅ No code generation required
- ✅ No recompilation when users create new models
- ✅ Type safety through metadata validation
- ✅ Fully testable (ViewModels are pure Dart)
- ✅ Reactive updates via ChangeNotifier

### Usage Example

```dart
import 'package:jcore/data.dart';
import 'package:jcore/jux.dart';

// 1. Implement QueryService for your backend
class MyQueryService implements QueryService {
  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) {
    // Route to your backend services
    if (queryId == 1000) return modelService.list(params);
    if (queryId == 1001) return modelService.get(params['i']);
    // ...
  }
}

// 2. Create ViewModel
final formVM = JuxFormViewModel(
  queryService: MyQueryService(),
  jux: viewDefinition,        // JUX view metadata
  model: modelMetadata,        // MetaX ModelX
  columns: columnMetadata,     // MetaX ColumnX
);

// 3. Load and edit
await formVM.load(recordId: 123);
formVM.updateField('name', 'New Value');

// 4. Validate and save
if (formVM.validate()) {
  final saved = await formVM.save();
}
```

### Integration with MetaX

JUX ViewModels use MetaX metadata for:
- **ModelX**: Model identity and relationships
- **ColumnX**: Data types, validation rules, labels
- **QueryX bindings**: List, get, save, delete operations

This enables a single ViewModel to work with customer, sales_order, or any other model without modification.

## Verification

```bash
cd dart
dart test
dart analyze --fatal-infos
```
