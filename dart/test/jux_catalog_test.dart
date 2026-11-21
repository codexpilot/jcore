import 'package:test/test.dart';
import 'package:jcore/jux.dart';

void main() {
  group('UIG/UIX Catalog', () {
    test('catalog has no duplicate IDs or codes', () {
      final errors = validateCatalog();
      expect(errors, isEmpty, reason: errors.join('; '));
    });

    test('all UIX types are within their group ranges', () {
      expect(UIX.deskWorkspace.validateRange(), isTrue);
      expect(UIX.mobileWorkspace.validateRange(), isTrue);
      expect(UIX.recordWorkspace.validateRange(), isTrue);
      expect(UIX.collectionPanel.validateRange(), isTrue);
      expect(UIX.inspectionPanel.validateRange(), isTrue);
      expect(UIX.formPanel.validateRange(), isTrue);
    });

    test('can lookup UIX by ID', () {
      expect(UIX.byId(1), equals(UIX.deskWorkspace));
      expect(UIX.byId(10000), equals(UIX.recordWorkspace));
      expect(UIX.byId(100000), equals(UIX.collectionPanel));
      expect(UIX.byId(999999), isNull);
    });

    test('can lookup UIX by code', () {
      expect(UIX.byCode('desk_workspace'), equals(UIX.deskWorkspace));
      expect(UIX.byCode('collection_panel'), equals(UIX.collectionPanel));
      expect(UIX.byCode('unknown'), isNull);
    });

    test('can lookup UIG by ID', () {
      expect(UIG.byId(1), equals(UIG.workspace));
      expect(UIG.byId(4), equals(UIG.partialview));
      expect(UIG.byId(99), isNull);
    });

    test('UIG range membership works correctly', () {
      expect(UIG.workspace.contains(1), isTrue);
      expect(UIG.workspace.contains(999), isTrue);
      expect(UIG.workspace.contains(1000), isFalse);
      expect(UIG.partialview.contains(100000), isTrue);
      expect(UIG.partialview.contains(999999), isTrue);
      expect(UIG.partialview.contains(1000000), isFalse);
    });
  });

  group('WorkspaceDef', () {
    test('parses valid workspace definition', () {
      final json = {
        'key': 'main_workspace',
        'schemaVersion': 1,
        'uix': 1,
        'title': 'Main Workspace',
        'destinations': [
          {'id': 'home', 'label': 'Home', 'viewKey': 'home_view'},
          {'id': 'data', 'label': 'Data', 'viewKey': 'data_view'},
        ],
        'initialDestination': 'home',
      };

      final workspace = WorkspaceDef.fromJson(json);
      expect(workspace.key, 'main_workspace');
      expect(workspace.uix, UIX.deskWorkspace);
      expect(workspace.destinations.length, 2);
      expect(workspace.initialDestination, 'home');
      expect(workspace.validate(), isEmpty);
    });

    test('rejects workspace with wrong UIX type', () {
      final json = {
        'key': 'bad_workspace',
        'schemaVersion': 1,
        'uix': 100000, // partial view, not workspace
        'title': 'Bad',
        'destinations': [
          {'id': 'home', 'label': 'Home', 'viewKey': 'home_view'},
        ],
        'initialDestination': 'home',
      };

      final workspace = WorkspaceDef.fromJson(json);
      final errors = workspace.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('not a workspace type'));
    });

    test('rejects workspace with missing initial destination', () {
      final json = {
        'key': 'bad_workspace',
        'schemaVersion': 1,
        'uix': 1,
        'title': 'Bad',
        'destinations': [
          {'id': 'home', 'label': 'Home', 'viewKey': 'home_view'},
        ],
        'initialDestination': 'missing',
      };

      final workspace = WorkspaceDef.fromJson(json);
      final errors = workspace.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('not found'));
    });
  });

  group('FullViewDef', () {
    test('parses valid full view definition', () {
      final json = {
        'key': 'record_view',
        'schemaVersion': 1,
        'uix': 10000,
        'title': 'Record View',
        'supportedWorkspaces': [1, 2],
        'viewModelBinding': 'composed',
        'panels': {
          'desktop': {
            'left': 'collection_panel',
            'center': 'inspection_panel',
            'right': 'form_panel',
          },
          'mobile': {
            'startingPanel': 'collection_panel',
            'transitions': {
              'select': 'inspection_panel',
              'edit': 'form_panel',
            },
          },
        },
      };

      final fullView = FullViewDef.fromJson(json);
      expect(fullView.key, 'record_view');
      expect(fullView.uix, UIX.recordWorkspace);
      expect(fullView.supportedWorkspaces, [1, 2]);
      expect(fullView.panels, isNotNull);
      expect(fullView.panels!.desktop.left, 'collection_panel');
      expect(fullView.panels!.mobile.startingPanel, 'collection_panel');
      expect(fullView.validate(), isEmpty);
    });

    test('rejects full view with wrong UIX type', () {
      final json = {
        'key': 'bad_view',
        'schemaVersion': 1,
        'uix': 100000, // partial view, not full view
        'title': 'Bad',
        'supportedWorkspaces': [1],
        'viewModelBinding': 'composed',
      };

      final fullView = FullViewDef.fromJson(json);
      final errors = fullView.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('not a full view type'));
    });

    test('rejects full view with invalid workspace reference', () {
      final json = {
        'key': 'bad_view',
        'schemaVersion': 1,
        'uix': 10000,
        'title': 'Bad',
        'supportedWorkspaces': [999], // non-existent workspace
        'viewModelBinding': 'composed',
      };

      final fullView = FullViewDef.fromJson(json);
      final errors = fullView.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('Invalid workspace'));
    });
  });

  group('PartialViewDef', () {
    test('parses valid partial view definition', () {
      final json = {
        'key': 'form_panel',
        'schemaVersion': 1,
        'uix': 100002,
        'title': 'Form Panel',
        'dataSchemaRef': 'storage_profile',
        'fields': [
          {'key': 'name', 'label': 'Name', 'control': 'text', 'readOnly': false},
          {'key': 'ttx', 'label': 'Type', 'control': 'select', 'readOnly': false},
        ],
        'commands': [
          {'command': 'save', 'label': 'Save', 'operation': 2001},
          {'command': 'cancel', 'label': 'Cancel'},
        ],
      };

      final partialView = PartialViewDef.fromJson(json);
      expect(partialView.key, 'form_panel');
      expect(partialView.uix, UIX.formPanel);
      expect(partialView.fields.length, 2);
      expect(partialView.commands.length, 2);
      expect(partialView.validate(), isEmpty);
    });

    test('rejects partial view with duplicate field keys', () {
      final json = {
        'key': 'bad_panel',
        'schemaVersion': 1,
        'uix': 100002,
        'title': 'Bad Panel',
        'dataSchemaRef': 'test',
        'fields': [
          {'key': 'name', 'label': 'Name', 'control': 'text', 'readOnly': false},
          {'key': 'name', 'label': 'Name2', 'control': 'text', 'readOnly': false},
        ],
        'commands': [],
      };

      final partialView = PartialViewDef.fromJson(json);
      final errors = partialView.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('Duplicate field keys'));
    });
  });
}
