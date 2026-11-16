// Package metax provides Go models for AIX MetaX metadata tables.
//
// This package implements Go equivalents of the Dart models in ContextStudio,
// representing metadata from the following tables:
//
//   - DomainX: Domain hierarchy (cox.domainx)
//   - TableX: Physical tables (mx.tablex)
//   - ColumnX: Physical columns (mx.columnx)
//   - EntityX: Logical entities (mx.entityx)
//   - FieldX: Logical fields (mx.fieldx)
//   - QueryX: Query operations (mx.queryx)
//   - ParamX: Query parameters (mx.paramx)
//   - SqlX: SQL implementations (mx.sqlx)
//
// All models support JSON marshaling/unmarshaling and include helper methods
// for type detection, validation, and business logic.
package metax
