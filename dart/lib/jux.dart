/// jux - JCore UI/UX framework for metadata-driven interfaces.
///
/// Provides the UIG/UIX catalog, versioned UI definitions (uidef), and reactive
/// ViewModels organized around workspace → surface → panel → control hierarchy.
///
/// ## Catalog and Taxonomy
///
/// - **UIG**: UI Groups (workspace, navigation, surface, panel, control)
/// - **UIX**: UI Types with stable IDs and codes within group ranges
/// - **UIDef**: Versioned JSON definitions referencing UIX types
///
/// ## ViewModels
///
/// - **ViewModel**: Base class with reactive state (loading, error)
/// - **WorkspaceViewModel**: Workspace-level navigation and state
/// - **ComposedViewModel**: Surface-level with panel composition
/// - **JuxFormViewModel**: Edit views with validation and dirty tracking
/// - **JuxCollectionViewModel**: List views with pagination and search
/// - **JuxInspectionViewModel**: Read-only detail views
///
/// ## Usage
///
/// ```dart
/// import 'package:jcore/data.dart';
/// import 'package:jcore/jux.dart';
///
/// // Parse a workspace definition
/// final workspaceDef = WorkspaceDef.fromJson(jsonDecode(workspaceJson));
/// final errors = workspaceDef.validate();
///
/// // Create workspace view model
/// final workspaceVM = WorkspaceViewModel(
///   queryService: myQueryService,
///   workspace: workspaceDef,
/// );
///
/// // Navigate
/// await workspaceVM.navigateTo('data');
/// ```
///
/// ## Architecture
///
/// ```
/// Workspace → Surface → Panel → Control
///     ↓         ↓         ↓        ↓
/// WorkspaceVM ComposedVM FormVM   FieldControl
///     ↓         ↓         ↓
/// QueryService (from package:jcore/data.dart)
/// ```
library;

// UIG/UIX catalog and validation
export 'src/jux/catalog.dart';

// UI definition parsing and validation
export 'src/jux/uidef.dart';

// Base ViewModel with reactive state management
export 'src/jux/view_model.dart';

// Workspace and composed view models
export 'src/jux/workspace_view_model.dart';

// Panel-level ViewModels for different view types
export 'src/jux/jux_form_view_model.dart';
export 'src/jux/jux_collection_view_model.dart';
export 'src/jux/jux_inspection_view_model.dart';
