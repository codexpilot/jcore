/// Tests for workspace view model race condition handling.
library;

import 'package:test/test.dart';
import 'package:jcore/jux.dart';
import 'package:jcore/data.dart';

/// Mock QueryService for testing race conditions.
class MockQueryService implements QueryService {
  MockQueryService({
    this.loadDelay = Duration.zero,
    this.saveDelay = Duration.zero,
  });

  final Duration loadDelay;
  final Duration saveDelay;
  final List<Map<String, dynamic>> _data = [
    {'i': 1, 'name': 'Profile 1', 'path': '/path/1'},
    {'i': 2, 'name': 'Profile 2', 'path': '/path/2'},
  ];

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    switch (queryId) {
      case 2000: // List operation
        await Future<void>.delayed(loadDelay);
        return List<Map<String, dynamic>>.from(_data);
      case 2001: // Save operation
        await Future<void>.delayed(saveDelay);
        final id = params['i'] as int;
        final index = _data.indexWhere((r) => r['i'] == id);
        if (index >= 0) {
          _data[index] = Map<String, dynamic>.from(params);
          return _data[index];
        }
        throw Exception('Record not found: $id');
      default:
        throw Exception('Unknown query ID: $queryId');
    }
  }
}

void main() {
  group('ComposedViewModel', () {
    late ComposedViewModel viewModel;
    late MockQueryService queryService;
    late SurfaceDef surfaceDef;

    setUp(() {
      surfaceDef = SurfaceDef(
        key: 'test_surface',
        schemaVersion: 1,
        uix: UIX.recordSurface,
        title: 'Test Surface',
        supportedWorkspaces: [1],
        viewModelBinding: 'composed',
        panels: null,
      );
    });

    test('load succeeds when no save is in progress', () async {
      queryService = MockQueryService();
      viewModel = ComposedViewModel(
        queryService: queryService,
        fullView: surfaceDef,
      );

      await viewModel.load();

      expect(viewModel.records.length, 2);
      expect(viewModel.records[0]['name'], 'Profile 1');
      expect(viewModel.hasError, false);
    });

    test('save wins over stale load when load completes after save', () async {
      // Load takes 200ms, save takes 50ms
      queryService = MockQueryService(
        loadDelay: const Duration(milliseconds: 200),
        saveDelay: const Duration(milliseconds: 50),
      );
      viewModel = ComposedViewModel(
        queryService: queryService,
        fullView: surfaceDef,
      );

      // Initial load to populate records
      await viewModel.load();
      expect(viewModel.records.length, 2);

      // Select and start editing
      viewModel.selectRecord(viewModel.records[0]);
      viewModel.startEdit();
      viewModel.updateDraft('name', 'Updated Profile');

      // Start a slow load (doesn't await)
      final loadFuture = viewModel.load();

      // Give load time to start
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Complete a save while load is in progress
      final saved = await viewModel.saveDraft(2001);
      expect(saved['name'], 'Updated Profile');

      // Wait for the stale load to complete
      await loadFuture;

      // Verify that the saved value is preserved, not overwritten by stale load
      final record = viewModel.records.firstWhere((r) => r['i'] == 1);
      expect(record['name'], 'Updated Profile',
          reason: 'Save should win over stale load');

      // Verify selected record also has the saved value
      expect(viewModel.selectedRecord?['name'], 'Updated Profile');
    });

    test('load updates records when no save happened during load', () async {
      queryService = MockQueryService(
        loadDelay: const Duration(milliseconds: 50),
      );
      viewModel = ComposedViewModel(
        queryService: queryService,
        fullView: surfaceDef,
      );

      // Initial load
      await viewModel.load();
      expect(viewModel.records.length, 2);

      // Directly modify the data source (simulating external update)
      queryService._data[0]['name'] = 'Externally Updated';

      // Load again - should pick up the external update
      await viewModel.load();

      final record = viewModel.records.firstWhere((r) => r['i'] == 1);
      expect(record['name'], 'Externally Updated',
          reason: 'Load should update records when no save is racing');
    });

    test('throws StateError when load is called during active load', () async {
      queryService = MockQueryService(
        loadDelay: const Duration(milliseconds: 100),
      );
      viewModel = ComposedViewModel(
        queryService: queryService,
        fullView: surfaceDef,
      );

      // Start first load (don't await)
      final loadFuture = viewModel.load();

      // Try to start second load
      expect(
        () => viewModel.load(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Load already in progress',
        )),
      );

      await loadFuture;
    });

    test('throws StateError when load is called during save', () async {
      queryService = MockQueryService(
        saveDelay: const Duration(milliseconds: 100),
      );
      viewModel = ComposedViewModel(
        queryService: queryService,
        fullView: surfaceDef,
      );

      // Initial load and setup
      await viewModel.load();
      viewModel.selectRecord(viewModel.records[0]);
      viewModel.startEdit();
      viewModel.updateDraft('name', 'Updated');

      // Start save (don't await)
      final saveFuture = viewModel.saveDraft(2001);

      // Try to load during save
      expect(
        () => viewModel.load(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          'Cannot load during save',
        )),
      );

      await saveFuture;
    });
  });
}
