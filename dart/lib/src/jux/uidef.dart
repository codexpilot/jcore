/// UI Definition (uidef) parsing and validation for JUX.
///
/// A uidef is a versioned JSON definition that references a UIX type and
/// declares its placement, supported workspaces, view-model binding, and fields.
library;

import 'catalog.dart';

/// Base class for all UI definitions.
abstract class UIDef {
  const UIDef({
    required this.key,
    required this.schemaVersion,
    required this.uix,
  });

  /// Stable definition key (e.g., 'storage_profiles').
  final String key;

  /// JSON format version.
  final int schemaVersion;

  /// Referenced UIX type.
  final UIX uix;

  /// Validate this definition.
  ///
  /// If [registry] is provided, validates cross-references to other definitions.
  List<String> validate([Map<String, UIDef>? registry]);
}

/// Workspace definition with navigation and initial destination.
final class WorkspaceDef extends UIDef {
  const WorkspaceDef({
    required super.key,
    required super.schemaVersion,
    required super.uix,
    required this.title,
    required this.destinations,
    required this.initialDestination,
    this.primaryDestinations,
  });

  final String title;
  final List<DestinationDef> destinations;
  final String initialDestination;

  /// Optional list of primary destination IDs for bottom navigation.
  /// If provided, these will be shown in the bottom bar (mobile) or
  /// emphasized in navigation (desktop). If null, all destinations
  /// are treated equally.
  final List<String>? primaryDestinations;

  @override
  List<String> validate([Map<String, UIDef>? registry]) {
    final errors = <String>[];
    if (uix.placement != 'workspace') {
      errors.add('$key: UIX ${uix.code} is not a workspace type');
    }
    if (destinations.isEmpty) {
      errors.add('$key: At least one destination is required');
    }
    final destIds = destinations.map((d) => d.id).toSet();
    if (destIds.length != destinations.length) {
      errors.add('$key: Duplicate destination IDs');
    }
    if (!destIds.contains(initialDestination)) {
      errors.add('$key: Initial destination "$initialDestination" not found');
    }

    // Validate primary destinations if specified
    if (primaryDestinations != null) {
      for (final primaryId in primaryDestinations!) {
        if (!destIds.contains(primaryId)) {
          errors.add('$key.primaryDestinations: "$primaryId" not found in destinations');
        }
      }
    }

    // Validate that all viewKeys reference actual full views in the registry
    if (registry != null) {
      for (final dest in destinations) {
        final view = registry[dest.viewKey];
        if (view == null) {
          errors.add('$key.destinations["${dest.id}"]: viewKey "${dest.viewKey}" not found in registry');
        } else if (view is! FullViewDef) {
          errors.add('$key.destinations["${dest.id}"]: viewKey "${dest.viewKey}" must reference a full view, found ${view.runtimeType}');
        } else {
          // Check if this workspace type is supported by the full view
          final fullView = view;
          if (!fullView.supportedWorkspaces.contains(uix.i)) {
            errors.add('$key.destinations["${dest.id}"]: view "${dest.viewKey}" does not support workspace type ${uix.code} (UIX ${uix.i})');
          }
        }
      }
    }
    return errors;
  }

  factory WorkspaceDef.fromJson(Map<String, dynamic> json) {
    final key = _requireString(json, 'key');
    final schemaVersion = _requireInt(json, 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException('$key: Only schemaVersion 1 is supported');
    }
    final uixId = _requireInt(json, 'uix');
    final uix = UIX.byId(uixId);
    if (uix == null) {
      throw FormatException('$key: Unknown UIX ID $uixId');
    }
    final title = _requireString(json, 'title');
    final destList = _requireList(json, 'destinations');
    final destinations = <DestinationDef>[];
    for (final item in destList) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('$key.destinations: Expected object');
      }
      destinations.add(DestinationDef.fromJson(item, key));
    }
    final initialDestination = _requireString(json, 'initialDestination');
    final primaryList = json['primaryDestinations'];
    final primaryDestinations = primaryList == null
        ? null
        : (primaryList as List).map((e) => e as String).toList();
    return WorkspaceDef(
      key: key,
      schemaVersion: schemaVersion,
      uix: uix,
      title: title,
      destinations: destinations,
      initialDestination: initialDestination,
      primaryDestinations: primaryDestinations,
    );
  }
}

/// Navigation destination referencing a full view.
final class DestinationDef {
  const DestinationDef({
    required this.id,
    required this.label,
    required this.viewKey,
  });

  final String id;
  final String label;
  final String viewKey;

  factory DestinationDef.fromJson(Map<String, dynamic> json, String parent) {
    return DestinationDef(
      id: _requireString(json, 'id', parent),
      label: _requireString(json, 'label', parent),
      viewKey: _requireString(json, 'viewKey', parent),
    );
  }
}

/// Full view definition with optional panel composition.
final class FullViewDef extends UIDef {
  const FullViewDef({
    required super.key,
    required super.schemaVersion,
    required super.uix,
    required this.title,
    required this.supportedWorkspaces,
    required this.viewModelBinding,
    this.panels,
  });

  final String title;
  final List<int> supportedWorkspaces;
  final String viewModelBinding;
  final PanelComposition? panels;

  @override
  List<String> validate([Map<String, UIDef>? registry]) {
    final errors = <String>[];
    if (uix.placement != 'fullview') {
      errors.add('$key: UIX ${uix.code} is not a full view type');
    }
    if (supportedWorkspaces.isEmpty) {
      errors.add('$key: At least one supported workspace is required');
    }
    for (final wsId in supportedWorkspaces) {
      final ws = UIX.byId(wsId);
      if (ws == null || ws.placement != 'workspace') {
        errors.add('$key.supportedWorkspaces: Invalid workspace UIX ID $wsId');
      }
    }

    // Validate panel references if registry is provided
    if (registry != null && panels != null) {
      final panelKeys = <String>[
        if (panels!.desktop.left != null) panels!.desktop.left!,
        if (panels!.desktop.center != null) panels!.desktop.center!,
        if (panels!.desktop.right != null) panels!.desktop.right!,
        panels!.mobile.startingPanel,
        ...panels!.mobile.transitions.values,
      ];

      for (final panelKey in panelKeys.toSet()) {
        final panel = registry[panelKey];
        if (panel == null) {
          errors.add('$key.panels: Panel reference "$panelKey" not found in registry');
        } else if (panel is! PartialViewDef) {
          errors.add('$key.panels: "$panelKey" must reference a partial view, found ${panel.runtimeType}');
        }
      }
    }
    return errors;
  }

  factory FullViewDef.fromJson(Map<String, dynamic> json) {
    final key = _requireString(json, 'key');
    final schemaVersion = _requireInt(json, 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException('$key: Only schemaVersion 1 is supported');
    }
    final uixId = _requireInt(json, 'uix');
    final uix = UIX.byId(uixId);
    if (uix == null) {
      throw FormatException('$key: Unknown UIX ID $uixId');
    }
    final title = _requireString(json, 'title');
    final supportedWorkspaces = _requireIntList(json, 'supportedWorkspaces');
    final viewModelBinding = _requireString(json, 'viewModelBinding');
    final panelsJson = json['panels'];
    final panels = panelsJson == null
        ? null
        : PanelComposition.fromJson(panelsJson as Map<String, dynamic>, key);
    return FullViewDef(
      key: key,
      schemaVersion: schemaVersion,
      uix: uix,
      title: title,
      supportedWorkspaces: supportedWorkspaces,
      viewModelBinding: viewModelBinding,
      panels: panels,
    );
  }
}

/// Panel composition for desktop and mobile layouts.
final class PanelComposition {
  const PanelComposition({
    required this.desktop,
    required this.mobile,
  });

  final DesktopPanels desktop;
  final MobilePanels mobile;

  factory PanelComposition.fromJson(Map<String, dynamic> json, String parent) {
    final desktopJson = json['desktop'];
    final mobileJson = json['mobile'];
    if (desktopJson == null || mobileJson == null) {
      throw FormatException('$parent.panels: desktop and mobile are required');
    }
    return PanelComposition(
      desktop: DesktopPanels.fromJson(desktopJson as Map<String, dynamic>, parent),
      mobile: MobilePanels.fromJson(mobileJson as Map<String, dynamic>, parent),
    );
  }
}

/// Desktop panel slots (left, center, right).
final class DesktopPanels {
  const DesktopPanels({this.left, this.center, this.right});

  final String? left;
  final String? center;
  final String? right;

  factory DesktopPanels.fromJson(Map<String, dynamic> json, String parent) {
    return DesktopPanels(
      left: json['left'] as String?,
      center: json['center'] as String?,
      right: json['right'] as String?,
    );
  }
}

/// Mobile panel flow with starting panel and transitions.
final class MobilePanels {
  const MobilePanels({
    required this.startingPanel,
    required this.transitions,
  });

  final String startingPanel;
  final Map<String, String> transitions;

  factory MobilePanels.fromJson(Map<String, dynamic> json, String parent) {
    final startingPanel = _requireString(json, 'startingPanel', parent);
    final transitionsJson = json['transitions'];
    final transitions = <String, String>{};
    if (transitionsJson is Map<String, dynamic>) {
      for (final entry in transitionsJson.entries) {
        if (entry.value is! String) {
          throw FormatException('$parent.transitions: Expected string values');
        }
        transitions[entry.key] = entry.value as String;
      }
    }
    return MobilePanels(
      startingPanel: startingPanel,
      transitions: transitions,
    );
  }
}

/// Partial view definition with field bindings and commands.
final class PartialViewDef extends UIDef {
  const PartialViewDef({
    required super.key,
    required super.schemaVersion,
    required super.uix,
    required this.title,
    required this.dataSchemaRef,
    required this.fields,
    required this.commands,
  });

  final String title;
  final String dataSchemaRef;
  final List<FieldBinding> fields;
  final List<CommandDef> commands;

  @override
  List<String> validate([Map<String, UIDef>? registry]) {
    final errors = <String>[];
    if (uix.placement != 'partialview') {
      errors.add('$key: UIX ${uix.code} is not a partial view type');
    }
    final fieldKeys = fields.map((f) => f.key).toSet();
    if (fieldKeys.length != fields.length) {
      errors.add('$key.fields: Duplicate field keys');
    }
    final commandNames = commands.map((c) => c.command).toSet();
    if (commandNames.length != commands.length) {
      errors.add('$key.commands: Duplicate command names');
    }
    return errors;
  }

  factory PartialViewDef.fromJson(Map<String, dynamic> json) {
    final key = _requireString(json, 'key');
    final schemaVersion = _requireInt(json, 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException('$key: Only schemaVersion 1 is supported');
    }
    final uixId = _requireInt(json, 'uix');
    final uix = UIX.byId(uixId);
    if (uix == null) {
      throw FormatException('$key: Unknown UIX ID $uixId');
    }
    final title = _requireString(json, 'title');
    final dataSchemaRef = _requireString(json, 'dataSchemaRef');
    final fieldsList = _requireList(json, 'fields');
    final fields = <FieldBinding>[];
    for (final item in fieldsList) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('$key.fields: Expected object');
      }
      fields.add(FieldBinding.fromJson(item, key));
    }
    final commandsList = _requireList(json, 'commands');
    final commands = <CommandDef>[];
    for (final item in commandsList) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('$key.commands: Expected object');
      }
      commands.add(CommandDef.fromJson(item, key));
    }
    return PartialViewDef(
      key: key,
      schemaVersion: schemaVersion,
      uix: uix,
      title: title,
      dataSchemaRef: dataSchemaRef,
      fields: fields,
      commands: commands,
    );
  }
}

/// Field binding with layout and type information.
final class FieldBinding {
  const FieldBinding({
    required this.key,
    required this.label,
    required this.control,
    required this.readOnly,
  });

  final String key;
  final String label;
  final String control;
  final bool readOnly;

  factory FieldBinding.fromJson(Map<String, dynamic> json, String parent) {
    return FieldBinding(
      key: _requireString(json, 'key', parent),
      label: _requireString(json, 'label', parent),
      control: _requireString(json, 'control', parent),
      readOnly: json['readOnly'] as bool? ?? false,
    );
  }
}

/// Command definition with label and operation reference.
final class CommandDef {
  const CommandDef({
    required this.command,
    required this.label,
    this.operation,
  });

  final String command;
  final String label;
  final Object? operation;

  factory CommandDef.fromJson(Map<String, dynamic> json, String parent) {
    return CommandDef(
      command: _requireString(json, 'command', parent),
      label: _requireString(json, 'label', parent),
      operation: json['operation'],
    );
  }
}

// Helper functions

String _requireString(Map<String, dynamic> json, String key, [String? parent]) {
  final path = parent == null ? key : '$parent.$key';
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path: Expected non-empty string');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key, [String? parent]) {
  final path = parent == null ? key : '$parent.$key';
  final value = json[key];
  if (value is! int) {
    throw FormatException('$path: Expected integer');
  }
  return value;
}

List<dynamic> _requireList(Map<String, dynamic> json, String key, [String? parent]) {
  final path = parent == null ? key : '$parent.$key';
  final value = json[key];
  if (value is! List) {
    throw FormatException('$path: Expected array');
  }
  return value;
}

List<int> _requireIntList(Map<String, dynamic> json, String key, [String? parent]) {
  final list = _requireList(json, key, parent);
  final result = <int>[];
  for (final item in list) {
    if (item is! int) {
      final path = parent == null ? key : '$parent.$key';
      throw FormatException('$path: Expected array of integers');
    }
    result.add(item);
  }
  return result;
}
