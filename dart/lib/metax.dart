/// MetaX models for AIX metadata tables
///
/// This library provides Dart models for AIX MetaX tables:
/// - DomainX: Domain hierarchy (cox.domainx)
/// - TableX: Physical tables (mx.tablex)
/// - ColumnX: Physical columns (mx.columnx)
/// - ModelX: Logical models (mx.modelx)
/// - FieldX: Logical fields (mx.fieldx)
/// - QueryX: Query operations (mx.queryx)
/// - ParamX: Query parameters (mx.paramx)
/// - SqlX: SQL implementations (mx.sqlx)
library metax;

export 'src/metax/domainx.dart';
export 'src/metax/tablex.dart';
export 'src/metax/columnx.dart';
export 'src/metax/modelx.dart';
export 'src/metax/fieldx.dart';
export 'src/metax/queryx.dart';
export 'src/metax/paramx.dart';
export 'src/metax/sqlx.dart';
