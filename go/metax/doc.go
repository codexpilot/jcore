// Package metax provides Go models for the 10 canonical AIX MetaX types.
//
// JCore is the source of truth for AIX MetaX taxonomy and type definitions.
//
// The 10 canonical MetaX types are:
//
//  1. DomainX - Domain hierarchy and scope (cox.domainx)
//  2. TypeG   - Type group catalog (cox.typeg)
//  3. TypeX   - Type catalog with group-based IDs (cox.typex)
//  4. TableX  - Physical table metadata (mx.tablex)
//  5. ColumnX - Physical column metadata (mx.columnx)
//  6. ModelX  - Logical model metadata (mx.modelx)
//  7. FieldX  - Logical field metadata (mx.fieldx)
//  8. QueryX  - Query operation metadata (mx.queryx)
//  9. ParamX  - Query parameter metadata (mx.paramx)
// 10. SqlX    - SQL template metadata (mx.sqlx)
//
// All models support JSON marshaling/unmarshaling and include helper methods
// for type detection, validation, and business logic.
package metax
