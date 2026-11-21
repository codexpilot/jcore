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
      expect(UIX.recordSurface.validateRange(), isTrue);
      expect(UIX.collectionPanel.validateRange(), isTrue);
      expect(UIX.inspectionPanel.validateRange(), isTrue);
      expect(UIX.formPanel.validateRange(), isTrue);
    });

    test('can lookup UIX by ID', () {
      expect(UIX.byId(1), equals(UIX.deskWorkspace));
      expect(UIX.byId(1000), equals(UIX.recordSurface));
      expect(UIX.byId(10000), equals(UIX.collectionPanel));
      expect(UIX.byId(999999), isNull);
    });

    test('can lookup UIX by code', () {
      expect(UIX.byCode('desk_workspace'), equals(UIX.deskWorkspace));
      expect(UIX.byCode('collection_panel'), equals(UIX.collectionPanel));
      expect(UIX.byCode('unknown'), isNull);
    });

    test('can lookup UIG by ID', () {
      expect(UIG.byId(1), equals(UIG.workspace));
      expect(UIG.byId(4), equals(UIG.panel));
      expect(UIG.byId(99), isNull);
    });

    test('UIG range membership works correctly', () {
      expect(UIG.workspace.contains(1), isTrue);
      expect(UIG.workspace.contains(99), isTrue);
      expect(UIG.workspace.contains(100), isFalse);
      expect(UIG.panel.contains(10000), isTrue);
      expect(UIG.panel.contains(99999), isTrue);
      expect(UIG.panel.contains(100000), isFalse);
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
        'uix': 10000, // panel, not workspace
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

  group('SurfaceDef', () {
    test('parses valid surface definition', () {
      final json = {
        'key': 'record_view',
        'schemaVersion': 1,
        'uix': 1000,
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

      final surface = SurfaceDef.fromJson(json);
      expect(surface.key, 'record_view');
      expect(surface.uix, UIX.recordSurface);
      expect(surface.supportedWorkspaces, [1, 2]);
      expect(surface.panels, isNotNull);
      expect(surface.panels!.desktop.left, 'collection_panel');
      expect(surface.panels!.mobile.startingPanel, 'collection_panel');
      expect(surface.validate(), isEmpty);
    });

    test('rejects surface with wrong UIX type', () {
      final json = {
        'key': 'bad_view',
        'schemaVersion': 1,
        'uix': 10000, // panel, not surface
        'title': 'Bad',
        'supportedWorkspaces': [1],
        'viewModelBinding': 'composed',
      };

      final surface = SurfaceDef.fromJson(json);
      final errors = surface.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('not a surface type'));
    });

    test('rejects surface with invalid workspace reference', () {
      final json = {
        'key': 'bad_view',
        'schemaVersion': 1,
        'uix': 1000,
        'title': 'Bad',
        'supportedWorkspaces': [999], // non-existent workspace
        'viewModelBinding': 'composed',
      };

      final surface = SurfaceDef.fromJson(json);
      final errors = surface.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('Invalid workspace'));
    });
  });

  group('PanelDef', () {
    test('parses valid panel definition', () {
      final json = {
        'key': 'form_panel',
        'schemaVersion': 1,
        'uix': 30000,
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

      final panel = PanelDef.fromJson(json);
      expect(panel.key, 'form_panel');
      expect(panel.uix, UIX.formPanel);
      expect(panel.fields.length, 2);
      expect(panel.commands.length, 2);
      expect(panel.validate(), isEmpty);
    });

    test('rejects panel with duplicate field keys', () {
      final json = {
        'key': 'bad_panel',
        'schemaVersion': 1,
        'uix': 30000,
        'title': 'Bad Panel',
        'dataSchemaRef': 'test',
        'fields': [
          {'key': 'name', 'label': 'Name', 'control': 'text', 'readOnly': false},
          {'key': 'name', 'label': 'Name2', 'control': 'text', 'readOnly': false},
        ],
        'commands': [],
      };

      final panel = PanelDef.fromJson(json);
      final errors = panel.validate();
      expect(errors, isNotEmpty);
      expect(errors.first, contains('Duplicate field keys'));
    });
  });
}
