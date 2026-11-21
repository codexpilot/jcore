# UIG System Architecture

**Source of Truth:** JCore architecture documentation  
**Purpose:** Define the UI Generation (UIG) layer, group structure, and UIX range allocation

---

## Overview

The **UIG (UI Generation)** system is the layer that generates actual user interface components from JUX definitions. It works in conjunction with the **UIX (UI Index)** enumerated type system to provide a hierarchical, framework-agnostic UI architecture.

**Key Concepts:**
- **UIX** = UI Index (enumerated type values for UI components)
- **UIG** = UI Generation (groups of UI components, implementation layer)
- **Hierarchy** = Workspace → Navigation → Surface → Panel → Control

---

## UIG Groups and UIX Ranges

The UIG system is organized into 5 groups, each with an allocated UIX range:

| UIG Group | Category | UIX Range | Scale | Purpose |
|-----------|----------|-----------|-------|---------|
| **Group 1** | Workspaces | 1-99 | 10² | Top-level application containers |
| **Group 2** | Navigations | 100-999 | 10³ | Navigation and routing components |
| **Group 3** | Surfaces | 1000-9999 | 10⁴ | Full view/screen compositions |
| **Group 4** | Panels | 10000-99999 | 10⁵ | Sectional UI components |
| **Group 5** | Controls | 100000-999999 | 10⁶ | Individual field/widget controls |

**Pattern:** Each group's range is 10× the previous group, providing clear separation and room for growth.

---

## Group 1: Workspaces (1-99)

**Purpose:** Application-level containers that define the overall chrome and navigation structure.

**Characteristics:**
- Top-level UI container
- Defines navigation paradigm (desktop, mobile, tablet)
- Contains one or more destinations/views
- Manages global navigation state

**Examples:**
- `deskWorkspace` (i=1) - Desktop application with sidebar/rail navigation
- `mobileWorkspace` (i=2) - Mobile application with bottom navigation
- `tabletWorkspace` (i=3) - Tablet-optimized layout
- `wizardWorkspace` (i=10) - Step-by-step wizard flow

**Range Allocation:**
- 1-9: Standard workspace types
- 10-19: Specialized workflows (wizards, kiosks)
- 20-99: Reserved for future workspace patterns

---

## Group 2: Navigations (100-999)

**Purpose:** Navigation components and routing mechanisms within workspaces.

**Characteristics:**
- Navigation UI elements (bars, rails, drawers)
- Route definitions and transitions
- Destination management
- Tab and drawer behaviors

**Examples:**
- `navigationRail` (i=100) - Vertical navigation rail (desktop)
- `navigationBar` (i=101) - Bottom navigation bar (mobile)
- `navigationDrawer` (i=102) - Side drawer navigation
- `tabBar` (i=110) - Horizontal tab navigation
- `breadcrumbs` (i=120) - Hierarchical navigation trail

**Range Allocation:**
- 100-199: Primary navigation components
- 200-299: Secondary navigation (tabs, breadcrumbs)
- 300-399: Contextual navigation (steppers, progress)
- 400-999: Reserved for future navigation patterns

---

## Group 3: Surfaces (1000-9999)

**Purpose:** Full view/screen compositions that contain multiple panels.

**Characteristics:**
- Complete screen/view definition
- Composed of multiple panels
- Defines panel layout and relationships
- Specifies view model binding
- Supports multiple workspace types (responsive)

**Examples:**
- `recordWorkspace` (i=1000) - Record management surface (list + detail + form)
- `dashboardSurface` (i=1100) - Dashboard with multiple data panels
- `reportSurface` (i=1200) - Report generation and viewing
- `settingsSurface` (i=1300) - Application settings interface

**Range Allocation:**
- 1000-1999: Data management surfaces (CRUD, records)
- 2000-2999: Analytics and reporting surfaces
- 3000-3999: Configuration and settings surfaces
- 4000-4999: Specialized workflows
- 5000-9999: Reserved for future surface types

---

## Group 4: Panels (10000-99999)

**Purpose:** Sectional UI components that display or edit specific aspects of data.

**Characteristics:**
- Self-contained UI section
- Single responsibility (list, detail, form, chart)
- Bound to view model
- Reusable across surfaces
- Defines fields and commands

**Examples:**
- `collectionPanel` (i=10000) - Scrollable list/table of records
- `inspectionPanel` (i=20000) - Read-only detail view
- `formPanel` (i=30000) - Editable form for record
- `chartPanel` (i=40000) - Data visualization
- `filterPanel` (i=50000) - Search and filter controls
- `summaryPanel` (i=60000) - Aggregated data summary

**Range Allocation:**
- 10000-19999: Collection/list panels
- 20000-29999: Inspection/detail panels
- 30000-39999: Form/edit panels
- 40000-49999: Visualization panels (charts, graphs)
- 50000-59999: Filter and search panels
- 60000-69999: Summary and aggregation panels
- 70000-99999: Reserved for future panel types

---

## Group 5: Controls (100000-999999)

**Purpose:** Individual field-level UI controls for data input and display.

**Characteristics:**
- Single field or widget
- Bound to one data property
- Self-contained validation
- Reusable across panels
- Type-specific rendering

**Examples:**
- `textControl` (i=100000) - Single-line text input
- `textareaControl` (i=100100) - Multi-line text input
- `selectControl` (i=200000) - Dropdown/picker selection
- `checkboxControl` (i=300000) - Boolean checkbox
- `radioControl` (i=300100) - Radio button group
- `dateControl` (i=400000) - Date picker
- `displayControl` (i=500000) - Read-only display field

**Range Allocation:**
- 100000-199999: Text input controls
- 200000-299999: Selection controls (dropdown, autocomplete)
- 300000-399999: Boolean and choice controls (checkbox, radio, toggle)
- 400000-499999: Date and time controls
- 500000-599999: Display-only controls
- 600000-699999: Numeric controls (number, slider, rating)
- 700000-799999: File and media controls
- 800000-899999: Specialized controls (color, location, signature)
- 900000-999999: Reserved for future control types

---

## Hierarchical Composition

The UIG groups form a clear containment hierarchy:

```
Workspace (Group 1)
  └─ Navigation (Group 2)
  └─ Surface (Group 3)
       └─ Panel (Group 4)
            └─ Control (Group 5)
```

**Example Composition:**
```
deskWorkspace (1)
  └─ navigationRail (100)
  └─ recordWorkspace (1000)
       ├─ collectionPanel (10000)
       │    └─ displayControl (500000) for each field
       ├─ inspectionPanel (20000)
       │    └─ displayControl (500000) for each field
       └─ formPanel (30000)
            ├─ textControl (100000) for name
            ├─ selectControl (200000) for type
            └─ dateControl (400000) for created date
```

---

## UIDef Taxonomy

The UIG groups map to UIDef class hierarchy:

| UIG Group | UIDef Class | Description |
|-----------|-------------|-------------|
| Group 1 | WorkspaceDef | Workspace definition |
| Group 2 | NavigationDef | Navigation component definition |
| Group 3 | SurfaceDef | Surface/full view definition |
| Group 4 | PanelDef | Panel/partial view definition |
| Group 5 | ControlDef | Control/field definition |

**Naming Convention:**
- **Previous:** FullViewDef, PartialViewDef (confusing)
- **Current:** SurfaceDef, PanelDef (clear hierarchy)
- **New:** ControlDef (individual controls)

---

## Reference Patterns

Following the TypeX group-specific reference pattern, UIG references use group-specific patterns:

| UIG Group | Singular | Plural | Description |
|-----------|----------|--------|-------------|
| Group 1 | wtx | wtxs | Workspace type |
| Group 2 | ntx | ntxs | Navigation type |
| Group 3 | stx | stxs | Surface type |
| Group 4 | pntx | pntxs | Panel type (pn- to avoid ctx conflict) |
| Group 5 | cntx | cntxs | Control type (cn- to avoid ctx conflict) |

**Alternative Generic Pattern:**
- `uix` = Generic UI component reference (when group is unknown/mixed)
- `uixs` = Generic UI component array

**Note:** Panel and Control use prefixed patterns (`pntx`, `cntx`) to avoid conflicts with existing TypeX patterns (`ptx` for parameter type, `ctx` for column type).

---

## Implementation Layers

### Definition Layer (JCore)
- UIX enumerated values
- UIDef classes (WorkspaceDef, SurfaceDef, PanelDef, ControlDef)
- View models (business logic)
- Framework-agnostic definitions

### Generation Layer (Platform-Specific)
- **MJUX** (Flutter/Material): Material Design implementations
- **SwiftUI JUX**: Native iOS/macOS implementations
- **React JUX**: Web implementations
- Each platform implements UIG builders for all groups

### Directory Organization

Platform implementations should organize by UIG group:

```
lib/src/jux/
  ├─ workspacex/     # Group 1 implementations
  ├─ navigationx/    # Group 2 implementations
  ├─ surfacex/       # Group 3 implementations
  ├─ panelx/         # Group 4 implementations
  └─ controlx/       # Group 5 implementations
```

---

## Design Principles

1. **Hierarchical:** Each group contains the next, forming clear composition
2. **Scalable:** 10× range multiplier provides room for growth
3. **Separable:** Clear boundaries between groups
4. **Framework-Agnostic:** Definitions work across platforms
5. **Type-Safe:** Enumerated UIX values prevent invalid references
6. **Consistent:** Follows JCore taxonomy patterns (TypeG/TypeX model)

---

## Migration Path

### Current → New Terminology
- `FullViewDef` → `SurfaceDef`
- `PartialViewDef` → `PanelDef`
- Add new: `ControlDef`

### Backward Compatibility
- Maintain type aliases during transition
- Deprecate old names with clear migration guidance
- Update all internal references to new terminology

---

## Related Documentation

- [UIX Catalog](../reference/uix-catalog.md) - Complete UIX enumeration
- [Type Patterns](../taxonomy/TYPE-PATTERNS.md) - TypeG/TypeX reference model
- [JUX Framework](./jux-framework.md) - Overall JUX architecture
