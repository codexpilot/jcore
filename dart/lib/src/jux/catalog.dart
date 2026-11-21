/// UIG and UIX catalog for the JUX framework.
///
/// Provides stable type identifiers for workspaces, navigation, surfaces,
/// panels, and controls. Each type has a unique ID within its group's range.
library;

/// UI Group (UIG) identifier with a stable code and inclusive range.
final class UIG {
  const UIG._({required this.i, required this.code, required this.range});

  /// Unique group ID.
  final int i;

  /// Stable group code (e.g., 'workspace', 'nav', 'surface').
  final String code;

  /// Inclusive range of UIX IDs belonging to this group.
  final (int min, int max) range;

  /// Group 1: Workspace types (desk, mobile, tablet).
  static const workspace = UIG._(i: 1, code: 'workspace', range: (1, 99));

  /// Group 2: Navigation types (rail, bar, drawer).
  static const navigation = UIG._(i: 2, code: 'navigation', range: (100, 999));

  /// Group 3: Surface types (full view compositions).
  static const surface = UIG._(i: 3, code: 'surface', range: (1000, 9999));

  /// Group 4: Panel types (sectional UI components).
  static const panel = UIG._(i: 4, code: 'panel', range: (10000, 99999));

  /// Group 5: Control types (individual field controls).
  static const control = UIG._(i: 5, code: 'control', range: (100000, 999999));

  /// @deprecated Use [navigation] instead. Removed in next major version.
  static const nav = navigation;

  /// @deprecated Use [surface] instead. Removed in next major version.
  static const fullview = surface;

  /// @deprecated Use [panel] instead. Removed in next major version.
  static const partialview = panel;

  static const _all = [workspace, navigation, surface, panel, control];

  /// Get a group by its ID.
  static UIG? byId(int id) {
    for (final group in _all) {
      if (group.i == id) return group;
    }
    return null;
  }

  /// Get a group by its code.
  static UIG? byCode(String code) {
    for (final group in _all) {
      if (group.code == code) return group;
    }
    return null;
  }

  /// Check if a UIX ID belongs to this group's range.
  bool contains(int uixId) => uixId >= range.$1 && uixId <= range.$2;
}

/// UI Type (UIX) within a group, with a stable ID, code, and contract.
final class UIX {
  const UIX._({
    required this.i,
    required this.uig,
    required this.code,
    required this.name,
    required this.placement,
  });

  /// Unique type ID within the group's range.
  final int i;

  /// Parent group reference.
  final UIG uig;

  /// Stable type code (e.g., 'desk_workspace').
  final String code;

  /// Display name (e.g., 'Desk Workspace').
  final String name;

  /// Placement: 'workspace', 'fullview', or 'partialview'.
  final String placement;

  // Workspace types (1-999)
  static const deskWorkspace = UIX._(
    i: 1,
    uig: UIG.workspace,
    code: 'desk_workspace',
    name: 'Desk Workspace',
    placement: 'workspace',
  );

  static const mobileWorkspace = UIX._(
    i: 2,
    uig: UIG.workspace,
    code: 'mobile_workspace',
    name: 'Mobile Workspace',
    placement: 'workspace',
  );

  // Navigation types (100-999)
  static const navigationRail = UIX._(
    i: 100,
    uig: UIG.navigation,
    code: 'navigation_rail',
    name: 'Navigation Rail',
    placement: 'navigation',
  );

  static const bottomNavigationBar = UIX._(
    i: 101,
    uig: UIG.navigation,
    code: 'bottom_navigation_bar',
    name: 'Bottom Navigation Bar',
    placement: 'navigation',
  );

  static const navigationDrawer = UIX._(
    i: 102,
    uig: UIG.navigation,
    code: 'navigation_drawer',
    name: 'Navigation Drawer',
    placement: 'navigation',
  );

  // Surface types (1000-9999)
  static const recordSurface = UIX._(
    i: 1000,
    uig: UIG.surface,
    code: 'record_surface',
    name: 'Record Surface',
    placement: 'surface',
  );

  /// @deprecated Use [recordSurface] instead. Removed in next major version.
  static const recordWorkspace = recordSurface;

  // Panel types (10000-99999)
  static const collectionPanel = UIX._(
    i: 10000,
    uig: UIG.panel,
    code: 'collection_panel',
    name: 'Collection Panel',
    placement: 'panel',
  );

  static const inspectionPanel = UIX._(
    i: 20000,
    uig: UIG.panel,
    code: 'inspection_panel',
    name: 'Inspection Panel',
    placement: 'panel',
  );

  static const formPanel = UIX._(
    i: 30000,
    uig: UIG.panel,
    code: 'form_panel',
    name: 'Form Panel',
    placement: 'panel',
  );

  static const _all = [
    deskWorkspace,
    mobileWorkspace,
    navigationRail,
    bottomNavigationBar,
    navigationDrawer,
    recordSurface,
    collectionPanel,
    inspectionPanel,
    formPanel,
  ];

  /// Get a type by its ID.
  static UIX? byId(int id) {
    for (final type in _all) {
      if (type.i == id) return type;
    }
    return null;
  }

  /// Get a type by its code.
  static UIX? byCode(String code) {
    for (final type in _all) {
      if (type.code == code) return type;
    }
    return null;
  }

  /// Validate that this UIX belongs to its declared group's range.
  bool validateRange() => uig.contains(i);
}

/// Validates catalog integrity: no duplicate IDs or codes, and range compliance.
List<String> validateCatalog() {
  final errors = <String>[];
  final seenGroupIds = <int>{};
  final seenGroupCodes = <String>{};
  final seenTypeIds = <int>{};
  final seenTypeCodes = <String>{};

  // Validate groups
  for (final group in UIG._all) {
    if (!seenGroupIds.add(group.i)) {
      errors.add('Duplicate UIG ID: ${group.i}');
    }
    if (!seenGroupCodes.add(group.code)) {
      errors.add('Duplicate UIG code: ${group.code}');
    }
  }

  // Validate types
  for (final type in UIX._all) {
    if (!seenTypeIds.add(type.i)) {
      errors.add('Duplicate UIX ID: ${type.i}');
    }
    if (!seenTypeCodes.add(type.code)) {
      errors.add('Duplicate UIX code: ${type.code}');
    }
    if (!type.validateRange()) {
      errors.add(
        'UIX ${type.code} (${type.i}) is outside its group range ${type.uig.range}',
      );
    }
  }

  return errors;
}
