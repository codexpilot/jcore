/// Data operations service interface for JCore.
///
/// This interface defines the contract for executing data operations
/// in JCore applications. It abstracts the underlying persistence layer,
/// enabling:
/// - Different backends (HTTP API, local database, mock data)
/// - Testability (mock implementations)
/// - Clean separation between data and presentation layers
///
/// ## JCore Layer Architecture
///
/// ```
/// jux/  (Presentation) → uses → jdata/ (Data) → uses → Backend
///   ViewModels                QueryService           HTTP/DB/etc
/// ```
///
/// ## Usage in JUX ViewModels
///
/// JUX ViewModels depend on this interface to execute data operations:
///
/// ```dart
/// import 'package:jcore/jdata.dart';
/// import 'package:jcore/jux.dart';
///
/// class JuxFormViewModel extends ViewModel {
///   final QueryService _queryService;
///
///   Future<void> load({int? recordId}) async {
///     final result = await _queryService.executeQuery(
///       getQueryId,
///       {'i': recordId},
///     );
///   }
/// }
/// ```
///
/// ## Implementation in Applications
///
/// Applications implement this interface to connect to their specific backends:
///
/// ```dart
/// // ContextStudio implementation
/// class ContextStudioQueryService implements QueryService {
///   final ModelXService _modelXService;
///
///   @override
///   Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) {
///     // Route to appropriate service based on query ID
///     if (queryId == 1000) return _modelXService.list(...);
///     if (queryId == 1001) return _modelXService.get(params['i']);
///     // ...
///   }
/// }
/// ```
///
/// ## Query-Based Pattern
///
/// Operations are identified by query IDs (integers) and executed with
/// parameters (maps). This matches the QueryX metadata pattern where
/// queries are defined once and referenced by ID.
///
/// **Example query IDs:**
/// - 1000-1999: ModelX operations
/// - 2000-2999: ColumnX operations
/// - 3000-3999: QueryX operations
/// - etc.
abstract class QueryService {
  /// Execute a query operation with parameters.
  ///
  /// Parameters:
  /// - [queryId]: Query identifier (maps to specific operation)
  /// - [params]: Operation parameters
  ///   - For list operations: filters, pagination (offset, limit)
  ///   - For get operations: record ID (i)
  ///   - For save operations: complete record data
  ///   - For delete operations: record ID (i)
  ///
  /// Returns:
  /// - List operations: `List<Map<String, dynamic>>`
  /// - Get operations: `Map<String, dynamic>`
  /// - Save operations: `Map<String, dynamic>` (saved record)
  /// - Delete operations: `Map<String, dynamic>` (confirmation)
  ///
  /// Throws: Exception on failure with descriptive error message
  ///
  /// Example:
  /// ```dart
  /// // List operation
  /// final models = await queryService.executeQuery(1000, {
  ///   'dxi': 1,      // domain ID
  ///   'offset': 0,
  ///   'limit': 20,
  /// });
  ///
  /// // Get operation
  /// final model = await queryService.executeQuery(1001, {'i': 123});
  ///
  /// // Save operation
  /// final saved = await queryService.executeQuery(1002, {
  ///   'i': 123,
  ///   'c': 'CUST001',
  ///   'n': 'Customer Name',
  /// });
  /// ```
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params);
}
