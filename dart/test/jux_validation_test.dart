import 'package:test/test.dart';
import 'package:jcore/jux.dart' as jux;
import 'package:jcore/data.dart' as jdata;

void main() {
  group('UIDef validation with registry', () {
    test('WorkspaceDef validates viewKey references exist', () {
      final workspace = jux.WorkspaceDef(
        key: 'test_workspace',
        schemaVersion: 1,
        uix: jux.UIX.deskWorkspace,
        title: 'Test',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'missing_view'),
        ],
        initialDestination: 'home',
      );

      // Without registry - no cross-reference validation
      expect(workspace.validate(), isEmpty);

      // With empty registry - should detect missing view
      final errors = workspace.validate({});
      expect(errors, isNotEmpty);
      expect(errors.first, contains('viewKey "missing_view" not found'));
    });

    test('WorkspaceDef validates viewKey references are full views', () {
      final partialView = jux.PartialViewDef(
        key: 'wrong_type',
        schemaVersion: 1,
        uix: jux.UIX.formPanel,
        title: 'Form',
        dataSchemaRef: 'test',
        fields: const [],
        commands: const [],
      );

      final workspace = jux.WorkspaceDef(
        key: 'test_workspace',
        schemaVersion: 1,
        uix: jux.UIX.deskWorkspace,
        title: 'Test',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'wrong_type'),
        ],
        initialDestination: 'home',
      );

      final errors = workspace.validate({'wrong_type': partialView});
      expect(errors, isNotEmpty);
      expect(errors.first, contains('must reference a full view'));
    });

    test('FullViewDef validates panel references exist', () {
      final fullView = jux.FullViewDef(
        key: 'test_view',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i],
        viewModelBinding: 'composed',
        panels: const jux.PanelComposition(
          desktop: jux.DesktopPanels(left: 'missing_panel'),
          mobile: jux.MobilePanels(startingPanel: 'missing_panel', transitions: {}),
        ),
      );

      final errors = fullView.validate({});
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Panel reference "missing_panel" not found')), isTrue);
    });

    test('FullViewDef validates panel references are partial views', () {
      final fullView1 = jux.FullViewDef(
        key: 'full1',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Full1',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i],
        viewModelBinding: 'composed',
      );

      final fullView2 = jux.FullViewDef(
        key: 'test_view',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i],
        viewModelBinding: 'composed',
        panels: const jux.PanelComposition(
          desktop: jux.DesktopPanels(left: 'full1'),
          mobile: jux.MobilePanels(startingPanel: 'full1', transitions: {}),
        ),
      );

      final errors = fullView2.validate({'full1': fullView1});
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('"full1" must reference a partial view')), isTrue);
    });

    test('WorkspaceDef validates full view supports workspace type', () {
      final fullView = jux.FullViewDef(
        key: 'desktop_only_view',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Desktop Only',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i], // Only supports desktop
        viewModelBinding: 'composed',
      );

      final mobileWorkspace = jux.WorkspaceDef(
        key: 'mobile_workspace',
        schemaVersion: 1,
        uix: jux.UIX.mobileWorkspace, // Mobile workspace
        title: 'Mobile',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'desktop_only_view'),
        ],
        initialDestination: 'home',
      );

      final errors = mobileWorkspace.validate({'desktop_only_view': fullView});
      expect(errors, isNotEmpty);
      expect(errors.first, contains('does not support workspace type'));
      expect(errors.first, contains('mobile_workspace'));
    });

    test('Complete definition graph validates successfully', () {
      final collection = jux.PartialViewDef(
        key: 'collection_panel',
        schemaVersion: 1,
        uix: jux.UIX.collectionPanel,
        title: 'Collection',
        dataSchemaRef: 'test',
        fields: const [
          jux.FieldBinding(key: 'name', label: 'Name', control: 'text', readOnly: true),
        ],
        commands: const [
          jux.CommandDef(command: 'refresh', label: 'Refresh'),
        ],
      );

      final fullView = jux.FullViewDef(
        key: 'test_view',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test View',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i],
        viewModelBinding: 'composed',
        panels: const jux.PanelComposition(
          desktop: jux.DesktopPanels(left: 'collection_panel'),
          mobile: jux.MobilePanels(startingPanel: 'collection_panel', transitions: {}),
        ),
      );

      final workspace = jux.WorkspaceDef(
        key: 'test_workspace',
        schemaVersion: 1,
        uix: jux.UIX.deskWorkspace,
        title: 'Test Workspace',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'test_view'),
        ],
        initialDestination: 'home',
      );

      final registry = {
        'collection_panel': collection,
        'test_view': fullView,
        'test_workspace': workspace,
      };

      expect(collection.validate(registry), isEmpty);
      expect(fullView.validate(registry), isEmpty);
      expect(workspace.validate(registry), isEmpty);
    });
  });

  group('ComposedViewModel state management', () {
    test('saveDraft guards against duplicate calls', () async {
      var saveCount = 0;
      final mockService = _MockQueryService(onSave: () async {
        saveCount++;
        await Future.delayed(Duration(milliseconds: 50));
        return {'i': 1, 'name': 'Saved'};
      });

      final fullView = jux.FullViewDef(
        key: 'test',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [1],
        viewModelBinding: 'composed',
      );

      final vm = jux.ComposedViewModel(
        queryService: mockService,
        fullView: fullView,
      );

      vm.selectRecord({'i': 1, 'name': 'Original'});
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // First save
      final save1 = vm.saveDraft(2001);

      // Second save while first is pending - should throw
      expect(() => vm.saveDraft(2001), throwsStateError);

      await save1;
      expect(saveCount, 1);
    });

    test('saveDraft allows retry after failure', () async {
      var saveCount = 0;
      final mockService = _MockQueryService(onSave: () async {
        saveCount++;
        if (saveCount == 1) {
          throw Exception('Network error');
        }
        return {'i': 1, 'name': 'Saved'};
      });

      final fullView = jux.FullViewDef(
        key: 'test',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [1],
        viewModelBinding: 'composed',
      );

      final vm = jux.ComposedViewModel(
        queryService: mockService,
        fullView: fullView,
      );

      vm.selectRecord({'i': 1, 'name': 'Original'});
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // First save fails
      expect(() => vm.saveDraft(2001), throwsException);
      await Future.delayed(Duration(milliseconds: 10));

      expect(vm.hasError, isTrue);
      expect(vm.hasUnsavedChanges, isTrue);

      // Retry succeeds
      final saved = await vm.saveDraft(2001);
      expect(saved['name'], 'Saved');
      expect(vm.hasUnsavedChanges, isFalse);
      expect(saveCount, 2);
    });

    test('load and save operations tracked independently', () async {
      var saveCount = 0;
      var loadCount = 0;
      final mockService = _MockQueryService(
        onSave: () async {
          saveCount++;
          await Future.delayed(Duration(milliseconds: 100));
          return {'i': 1, 'name': 'Saved'};
        },
        onLoad: () async {
          loadCount++;
          await Future.delayed(Duration(milliseconds: 50));
          return [{'i': 1, 'name': 'Record 1'}];
        },
      );

      final fullView = jux.FullViewDef(
        key: 'test',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [1],
        viewModelBinding: 'composed',
      );

      final vm = jux.ComposedViewModel(
        queryService: mockService,
        fullView: fullView,
      );

      vm.selectRecord({'i': 1, 'name': 'Original'});
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // Start save (will take 100ms)
      final save1 = vm.saveDraft(2001);

      // While save is pending, load completes (50ms)
      await vm.load(listOperationId: 2000);
      expect(loadCount, 1);

      // Try to save again while first save is still pending - should throw
      expect(() => vm.saveDraft(2001), throwsStateError);

      // Wait for first save to complete
      await save1;
      expect(saveCount, 1, reason: 'Only one save should have executed');
    });

    test('prevents selection changes during save', () async {
      final mockService = _MockQueryService(
        onSave: () async {
          await Future.delayed(Duration(milliseconds: 50));
          return {'i': 1, 'name': 'Saved'};
        },
      );

      final fullView = jux.FullViewDef(
        key: 'test',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Test',
        supportedWorkspaces: [1],
        viewModelBinding: 'composed',
      );

      final vm = jux.ComposedViewModel(
        queryService: mockService,
        fullView: fullView,
      );

      vm.selectRecord({'i': 1, 'name': 'Original'});
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // Start save
      final save = vm.saveDraft(2001);

      // Try to change selection during save - should throw
      expect(() => vm.selectRecord({'i': 2, 'name': 'Other'}), throwsStateError);
      expect(() => vm.clearSelection(), throwsStateError);
      expect(() => vm.startEdit(), throwsStateError);
      expect(() => vm.cancelEdit(), throwsStateError);

      await save;
    });
  });
}

class _MockQueryService implements jdata.QueryService {
  _MockQueryService({
    this._onSave,
    this._onLoad,
  });

  final Future<Map<String, dynamic>> Function()? _onSave;
  final Future<List<Map<String, dynamic>>> Function()? _onLoad;

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    if (queryId == 2000 && _onLoad != null) {
      return _onLoad();
    }
    if (queryId == 2001 && _onSave != null) {
      return _onSave();
    }
    throw Exception('Unexpected query: $queryId');
  }
}
