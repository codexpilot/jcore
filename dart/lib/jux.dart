/// jux - JCore UI/UX framework for metadata-driven interfaces.
///
/// Provides reactive ViewModels that work with dynamic schemas without
/// code generation. ViewModels use the QueryService from jdata for
/// data operations and are designed to work with any model defined
/// through MetaX metadata.
///
/// ## Core ViewModels
///
/// - **ViewModel**: Base class with reactive state (loading, error)
/// - **JuxFormViewModel**: Edit views with validation and dirty tracking
/// - **JuxCollectionViewModel**: List views with pagination and search
/// - **JuxInspectionViewModel**: Read-only detail views
///
/// ## Usage
///
/// ```dart
/// import 'package:jcore/jdata.dart';
/// import 'package:jcore/jux.dart';
///
/// // Implement QueryService for your backend
/// class MyQueryService implements QueryService {
///   @override
///   Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) {
///     // Route to your backend
///   }
/// }
///
/// // Create ViewModel
/// final formVM = JuxFormViewModel(
///   queryService: MyQueryService(),
///   jux: viewDefinition,
///   model: modelMetadata,
///   columns: columnMetadata,
/// );
///
/// // Load and edit
/// await formVM.load(recordId: 123);
/// formVM.updateField('name', 'New Value');
/// if (formVM.validate()) {
///   await formVM.save();
/// }
/// ```
///
/// ## Architecture
///
/// ```
/// JUX (Presentation) → JData (Data) → Backend
///    ViewModels         QueryService    HTTP/DB
/// ```
library;

// Base ViewModel with reactive state management
export 'src/jux/view_model.dart';

// Specific ViewModels for different view types
export 'src/jux/jux_form_view_model.dart';
export 'src/jux/jux_collection_view_model.dart';
export 'src/jux/jux_inspection_view_model.dart';
