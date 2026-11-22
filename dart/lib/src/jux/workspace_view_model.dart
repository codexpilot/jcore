/// Workspace-level view model for managing full views and navigation.
library;

import '../data/query_service.dart';
import 'view_model.dart';
import 'uidef.dart';

/// View model for workspace-level state and navigation.
///
/// Manages:
/// - Active destination and full view
/// - Navigation between destinations
/// - Unsaved change guards
/// - Workspace-level operations
class WorkspaceViewModel extends ViewModel {
  WorkspaceViewModel({
    required this._workspace,
  }) : _activeDestination = _workspace.initialDestination;

  final WorkspaceDef _workspace;
  String _activeDestination;

  /// Current active destination ID.
  String get activeDestination => _activeDestination;

  /// Workspace definition.
  WorkspaceDef get workspace => _workspace;

  /// Navigate to a destination.
  ///
  /// Returns false if navigation was blocked (e.g., unsaved changes).
  Future<bool> navigateTo(String destinationId) async {
    if (!_workspace.destinations.any((d) => d.id == destinationId)) {
      setError('Unknown destination: $destinationId');
      return false;
    }

    // Check for unsaved changes in current view
    if (_hasUnsavedChanges != null && _hasUnsavedChanges!()) {
      // Caller should show confirmation dialog
      return false;
    }

    _activeDestination = destinationId;
    notifyListeners();
    return true;
  }

  /// Optional callback to check for unsaved changes before navigation.
  bool Function()? _hasUnsavedChanges;

  /// Register a callback to check for unsaved changes.
  void registerUnsavedChangesCheck(bool Function() check) {
    _hasUnsavedChanges = check;
  }

  /// Unregister the unsaved changes check.
  void unregisterUnsavedChangesCheck() {
    _hasUnsavedChanges = null;
  }

  @override
  Future<void> load() async {
    // Workspace loads its initial destination view, not data itself.
    // No-op for workspace-level state.
  }
}

/// View model for a composed full view with multiple panels.
///
/// Manages:
/// - Collection data loading and retry
/// - Shared state across panels
/// - Panel visibility and transitions
/// - Selection state
/// - Draft state with validation
class ComposedViewModel extends ViewModel {
  ComposedViewModel({
    required this._queryService,
    required this._fullView,
  });

  final QueryService _queryService;
  final FullViewDef _fullView;

  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _selectedRecord;
  Map<String, dynamic>? _draftRecord;
  String? _activePanel;
  bool _isReading = false;
  bool _isWriting = false;
  DateTime? _lastSaveCompletedAt;

  /// Full view definition.
  FullViewDef get fullView => _fullView;

  /// Collection records.
  List<Map<String, dynamic>> get records => List.unmodifiable(_records);

  /// Currently selected record.
  Map<String, dynamic>? get selectedRecord => _selectedRecord;

  /// Current draft (unsaved edits).
  Map<String, dynamic>? get draftRecord => _draftRecord;

  /// Active panel key (for mobile).
  String? get activePanel => _activePanel;

  /// Whether there are unsaved changes.
  bool get hasUnsavedChanges => _draftRecord != null;

  /// Whether a read operation is in progress.
  bool get isReading => _isReading;

  /// Whether a write operation is in progress.
  bool get isWriting => _isWriting;

  @override
  bool get isLoading => _isReading || _isWriting;

  /// Load collection data.
  @override
  Future<void> load({int? listOperationId}) async {
    listOperationId ??= 2000; // Default list operation
    if (_isReading) {
      throw StateError('Load already in progress');
    }
    if (_isWriting) {
      throw StateError('Cannot load during save');
    }
    final loadStartedAt = DateTime.now();
    _isReading = true;
    notifyListeners();
    try {
      final result = await _queryService.executeQuery(listOperationId, {});
      // Handle both mutable and immutable list results
      final resultList = result as List;

      // Discard stale data if a save completed during this load
      if (_lastSaveCompletedAt != null &&
          _lastSaveCompletedAt!.isAfter(loadStartedAt)) {
        _isReading = false;
        notifyListeners();
        return; // Keep fresh data from save, discard stale load results
      }

      _records = resultList is List<Map<String, dynamic>>
          ? List<Map<String, dynamic>>.from(resultList)
          : resultList.cast<Map<String, dynamic>>();
      _isReading = false;
      clearError();
      notifyListeners();
    } catch (e) {
      _isReading = false;
      setError('Load failed: $e');
      rethrow;
    }
  }

  /// Select a record.
  void selectRecord(Map<String, dynamic> record) {
    if (_isWriting) {
      throw StateError('Cannot change selection during save');
    }
    _selectedRecord = Map.unmodifiable(record);
    _draftRecord = null;
    notifyListeners();
  }

  /// Clear selection.
  void clearSelection() {
    if (_isWriting) {
      throw StateError('Cannot clear selection during save');
    }
    _selectedRecord = null;
    _draftRecord = null;
    notifyListeners();
  }

  /// Start editing (create draft from selected record).
  void startEdit() {
    if (_selectedRecord == null) {
      throw StateError('No record selected');
    }
    if (_isWriting) {
      throw StateError('Cannot start edit during save');
    }
    _draftRecord = Map<String, dynamic>.from(_selectedRecord!);
    notifyListeners();
  }

  /// Update a field in the draft.
  void updateDraft(String fieldKey, dynamic value) {
    if (_draftRecord == null) {
      throw StateError('No draft active');
    }
    _draftRecord![fieldKey] = value;
    notifyListeners();
  }

  /// Cancel editing (discard draft).
  void cancelEdit() {
    if (_isWriting) {
      throw StateError('Cannot cancel edit during save');
    }
    _draftRecord = null;
    clearError();
    notifyListeners();
  }

  /// Save the draft.
  Future<Map<String, dynamic>> saveDraft(int saveOperationId) async {
    if (_draftRecord == null) {
      throw StateError('No draft to save');
    }
    if (_isWriting) {
      throw StateError('Save already in progress');
    }
    _isWriting = true;
    notifyListeners();
    try {
      // Build sparse update payload: only changed fields + ID
      // Never send server-managed fields (d, e) or immutable fields (c, f, txis)
      final payload = _buildSparsePayload(_draftRecord!, _selectedRecord);

      // DEBUG: Log payload being sent
      print('DEBUG saveDraft: payload keys = ${payload.keys.toList()}');
      print('DEBUG saveDraft: payload = $payload');

      final saved = await _queryService.executeQuery(
        saveOperationId,
        payload,
      ) as Map<String, dynamic>;

      // Update selected record and collection atomically
      _selectedRecord = Map.unmodifiable(saved);
      final id = saved['i'];
      final index = _records.indexWhere((r) => r['i'] == id);
      if (index >= 0) {
        _records[index] = Map<String, dynamic>.from(saved);
      }

      _draftRecord = null;
      _isWriting = false;
      _lastSaveCompletedAt = DateTime.now();
      clearError();
      notifyListeners();
      return saved;
    } catch (e) {
      _isWriting = false;
      setError('Save failed: $e');
      // Preserve draft on failure so user can retry
      rethrow;
    }
  }

  /// Set the active panel (mobile).
  void setActivePanel(String panelKey) {
    _activePanel = panelKey;
    notifyListeners();
  }
}

  /// Build sparse payload for save: only changed fields, no immutable ones.
  ///
  /// Immutable fields (never send): d (timestamp), e (editor), c (code)
  /// All other fields are editable and sent when changed
  Map<String, dynamic> _buildSparsePayload(
    Map<String, dynamic> draft,
    Map<String, dynamic>? original,
  ) {
    const neverSend = {'d', 'e', 'c'};
    final payload = <String, dynamic>{};
    final isUpdate = original != null && draft['i'] != null;

    if (isUpdate) {
      // Updates: ID + changed editable fields only
      payload['i'] = draft['i'];
      for (final entry in draft.entries) {
        final key = entry.key;
        if (neverSend.contains(key) || key == 'i') continue;
        if (entry.value != original[key]) {
          payload[key] = entry.value;
        }
      }
    } else {
      // Creates: all fields except never-send
      for (final entry in draft.entries) {
        if (!neverSend.contains(entry.key)) {
          payload[entry.key] = entry.value;
        }
      }
    }
    return payload;
  }
