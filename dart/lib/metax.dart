/// MetaX models for AIX metadata tables
///
/// This library provides Dart models for the 10 canonical AIX MetaX types:
/// - DomainX: Domain hierarchy (cox.domainx)
/// - TypeG: Type groups (cox.typeg)
/// - TypeX: Type catalog (cox.typex)
/// - TableX: Physical tables (mx.tablex)
/// - ColumnX: Physical columns (mx.columnx)
/// - ModelX: Logical models (mx.modelx)
/// - FieldX: Logical fields (mx.fieldx)
/// - QueryX: Query operations (mx.queryx)
/// - ParamX: Query parameters (mx.paramx)
/// - SqlX: SQL implementations (mx.sqlx)
library metax;

export 'src/metax/domainx.dart';
export 'src/metax/typeg.dart';
export 'src/metax/typex.dart';
export 'src/metax/tablex.dart';
export 'src/metax/columnx.dart';
export 'src/metax/modelx.dart';
export 'src/metax/fieldx.dart';
export 'src/metax/queryx.dart';
export 'src/metax/paramx.dart';
export 'src/metax/sqlx.dart';
