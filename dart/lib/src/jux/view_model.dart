import 'package:flutter/foundation.dart';

/// Base class for all ViewModels in the JUX framework (JCore UI/UX system).
///
/// ## JUX Framework
///
/// JUX is JCore's metadata-driven UI/UX framework that works with dynamic
/// schemas. ViewModels are the presentation logic layer in the MVVM pattern.
///
/// ## Architecture
///
/// ```
/// Model (JData/MetaX)  →  ViewModel (JUX)  →  View (Flutter)
///       ↓                      ↓                   ↓
/// Business metadata      Presentation logic    Reactive UI
/// ```
///
/// ## Purpose
///
/// ViewModels:
/// - Hold UI state (loading, error, data)
/// - Transform Model data into View-ready format
/// - Handle user interactions (validate, save, etc.)
/// - Are pure Dart (no Flutter widget imports)
/// - Are testable without Flutter framework
///
/// ## Usage
///
/// ```dart
/// class CustomerListViewModel extends ViewModel {
///   List<Customer> _customers = [];
///   List<Customer> get customers => List.unmodifiable(_customers);
///
///   @override
///   Future<void> load() async {
///     setLoading(true);
///     try {
///       _customers = await _fetchCustomers();
///     } catch (e) {
///       setError('Failed to load: $e');
///     } finally {
///       setLoading(false);
///     }
///   }
/// }
///
/// // In View:
/// Consumer<CustomerListViewModel>(
///   builder: (context, vm, child) {
///     if (vm.isLoading) return LoadingIndicator();
///     return ListView(children: vm.customers.map(...));
///   },
/// )
/// ```
///
/// ## Reactive Updates
///
/// ViewModels extend [ChangeNotifier], so views automatically rebuild when:
/// - [setLoading] is called
/// - [setError] is called
/// - [notifyListeners] is called by subclasses
abstract class ViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// Whether data is currently being loaded.
  bool get isLoading => _isLoading;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether an error is present.
  bool get hasError => _errorMessage != null;

  /// Set loading state and notify listeners.
  ///
  /// Typically called at the start and end of async operations:
  /// ```dart
  /// Future<void> load() async {
  ///   setLoading(true);
  ///   try {
  ///     // ... fetch data
  ///   } finally {
  ///     setLoading(false);
  ///   }
  /// }
  /// ```
  @protected
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message and notify listeners.
  ///
  /// Pass null to clear the error.
  ///
  /// ```dart
  /// try {
  ///   // ... operation
  /// } catch (e) {
  ///   setError('Failed to save: $e');
  /// }
  /// ```
  @protected
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error state.
  ///
  /// Convenience method equivalent to `setError(null)`.
  void clearError() {
    setError(null);
  }

  /// Load data for this ViewModel.
  ///
  /// Subclasses implement this to define their loading behavior.
  /// Should call [setLoading] and [setError] appropriately.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<void> load() async {
  ///   setLoading(true);
  ///   setError(null);
  ///   try {
  ///     final data = await _repository.fetch();
  ///     _processData(data);
  ///   } catch (e) {
  ///     setError('Load failed: $e');
  ///   } finally {
  ///     setLoading(false);
  ///   }
  /// }
  /// ```
  Future<void> load();

  @override
  void dispose() {
    // Clean up resources before disposal
    super.dispose();
  }
}
