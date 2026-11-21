/// UIG and UIX catalog for the JUX framework.
///
/// Provides stable type identifiers for workspaces, navigation, full views,
/// and partial views. Each type has a unique ID within its group's range.
library;

/// UI Group (UIG) identifier with a stable code and inclusive range.
final class UIG {
  const UIG._({required this.i, required this.code, required this.range});

  /// Unique group ID.
  final int i;

  /// Stable group code (e.g., 'workspace', 'nav').
  final String code;

  /// Inclusive range of UIX IDs belonging to this group.
  final (int min, int max) range;

  /// Workspace group (desk, mobile workspaces).
  static const workspace = UIG._(i: 1, code: 'workspace', range: (1, 999));

  /// Navigation group (rail, bottom bar, drawer).
  static const nav = UIG._(i: 2, code: 'nav', range: (1000, 9999));

  /// Full view group (record workspace, etc.).
  static const fullview = UIG._(i: 3, code: 'fullview', range: (10000, 99999));

  /// Partial view group (panels: collection, inspection, form).
  static const partialview = UIG._(i: 4, code: 'partialview', range: (100000, 999999));

  static const _all = [workspace, nav, fullview, partialview];

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

  // Navigation types (1000-9999)
  static const navigationRail = UIX._(
    i: 1000,
    uig: UIG.nav,
    code: 'navigation_rail',
    name: 'Navigation Rail',
    placement: 'nav',
  );

  static const bottomNavigationBar = UIX._(
    i: 1001,
    uig: UIG.nav,
    code: 'bottom_navigation_bar',
    name: 'Bottom Navigation Bar',
    placement: 'nav',
  );

  static const navigationDrawer = UIX._(
    i: 1002,
    uig: UIG.nav,
    code: 'navigation_drawer',
    name: 'Navigation Drawer',
    placement: 'nav',
  );

  // Full view types (10000-99999)
  static const recordWorkspace = UIX._(
    i: 10000,
    uig: UIG.fullview,
    code: 'record_workspace',
    name: 'Record Workspace',
    placement: 'fullview',
  );

  // Partial view types (100000-999999)
  static const collectionPanel = UIX._(
    i: 100000,
    uig: UIG.partialview,
    code: 'collection_panel',
    name: 'Collection Panel',
    placement: 'partialview',
  );

  static const inspectionPanel = UIX._(
    i: 100001,
    uig: UIG.partialview,
    code: 'inspection_panel',
    name: 'Inspection Panel',
    placement: 'partialview',
  );

  static const formPanel = UIX._(
    i: 100002,
    uig: UIG.partialview,
    code: 'form_panel',
    name: 'Form Panel',
    placement: 'partialview',
  );

  static const _all = [
    deskWorkspace,
    mobileWorkspace,
    navigationRail,
    bottomNavigationBar,
    navigationDrawer,
    recordWorkspace,
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
