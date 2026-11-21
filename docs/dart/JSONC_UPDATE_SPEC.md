# JCore JSONC Query Response Update - Implementation Plan

## Overview

This document outlines the required changes to implement the shared JSONC query response format for AIXHub, APIHub, ContextStudio, and Dataset. The update standardizes field naming, extends JNF encoding modes, and improves temporal value handling.

## Scope of Changes

### 1. Field Name Standardization

**New Canonical Names** (to be added):
- `jcore` - JCore package version (string, e.g., "4.4.0")
- `mjux` - MJUX package version (string, optional)
- `appx` - Application release with build number (string, optional)
- `dataSchemaVersion` - Schema version as epoch seconds (int, replaces `jv`)
- `uxSchemaVersion` - UIDef format version (int, optional, new field)
- `resultSchemaId` - Result schema identifier (int, replaces `jid`)
- `encoding` - Combined JNF mode (int, replaces `jnf`, defaults to 2)
- `columns` - Explicit column ordering (List<String>, new field)

**Legacy Names** (maintain for backward compatibility):
- `jv` - accepted in input, mapped to `dataSchemaVersion`
- `jid` - accepted in input, mapped to `resultSchemaId`
- `jnf` - accepted in input, mapped to `encoding`

**Backward Compatibility Rules**:
1. Accept both old and new field names in `fromJson`
2. Emit only new canonical names in `toJson`
3. Reject payloads with conflicting values when both spellings present
4. Default omitted `encoding` to 2

### 2. JNF Encoding Extension

**Current Modes 0-5** (unchanged):
- 0: Formal JSON, both BigInt and Numeric as string (web-safe input)
- 1: Formal JSON, both as plain number (not web-safe)
- 2: JSONC, both as plain number (default, not web-safe for INT64)
- 3: JSONC, BigInt as string only (web-safe for large integers)
- 4: JSONC, Numeric as string only (not web-safe for INT64)
- 5: JSONC, both as string (maximum safety)

**New Modes 8-13** (base + 8 for text temporal values):
- 8: Like mode 0, with text temporal values
- 9: Like mode 1, with text temporal values  
- 10: Like mode 2, with text temporal values
- 11: Like mode 3, with text temporal values
- 12: Like mode 4, with text temporal values
- 13: Like mode 5, with text temporal values + INT64/decimals as strings

**Mode 13 Specific Requirements**:
- INT64: Decimal string representation
- Numeric: Decimal string representation
- DATETIME: UTC RFC 3339 with milliseconds (e.g., "2024-01-15T14:30:00.123Z")
- TIME: HH:mm:ss.SSS format (e.g., "14:30:00.123")

**Temporal Value Handling**:
- Internal canonical form: epoch milliseconds for DATETIME, milliseconds since midnight for TIME
- Modes 0-5: Temporal values as epoch/millis integers
- Modes 8-13: Temporal values as text strings (RFC 3339 for DATETIME, HH:mm:ss.SSS for TIME)
- Reject undefined modes (6, 7, 14+)
- Reject invalid temporal string formats

**Data Type IDs** (for temporal types):
- DATETIME: 40001 (assumed based on test)
- TIME: TBD (needs confirmation from registry)
- DATE: TBD (needs confirmation from registry)

### 3. Tabular Result Enhancements

**New `columns` Field**:
- Explicit column ordering as array of column names
- Decode rows using `columns` order even if JSONB reorders `schema` keys
- Required for tabular results with schema
- Optional for data-only payloads (resolved from cached schema)

**Data-Only Resolution**:
- Resolve data-only payloads against cached `resultSchemaId` and `dataSchemaVersion`
- Authority scope determines which cached schema to use
- Fail if no matching schema found in cache

**Composed Results**:
- Preserve declared object, array, or null shape
- Support nested structures beyond flat tabular data

### 4. Version Tracking

**Package Versions**:
- `jcore`: Read from pubspec.yaml version field
- `mjux`: Optional, included when MJUX generates response
- `appx`: Optional, app-specific release identifier

**Schema Versions**:
- `dataSchemaVersion`: Epoch seconds when data schema was created/updated
- `uxSchemaVersion`: Integer version of UIDef format specification
- `resultSchemaId`: Unique identifier for specific result schema shape

### 5. Client Negotiation

**Request Format**:
```http
POST /api/query/{queryId}
Content-Type: application/json

{
  "params": { ... },
  "encoding": 13,          // Request specific encoding mode
  "includeSchema": true    // Request schema in response
}
```

**Response Format**:
```json
{
  "jcore": "4.4.0",
  "dataSchemaVersion": 1737849600,
  "resultSchemaId": 5001,
  "encoding": 13,
  "columns": ["id", "name", "amount"],
  "schema": {
    "id": 40000,
    "name": 70000,
    "amount": 61002
  },
  "data": [
    ["9223372036854775807", "Product A", "1234.56"],
    ["9223372036854775808", "Product B", "5678.90"]
  ]
}
```

**Extended Mode Enablement**:
- Modes 8-13 only available when client explicitly requests them
- Server validates client capability before sending extended modes
- Fall back to mode 2 if extended mode not supported by client

## Implementation Tasks

### Phase 1: Core Type Updates (Dart)

**File: `dart/lib/src/data/jsonc.dart`**

1. Add new fields to `JsonC` class:
   ```dart
   class JsonC {
     // New canonical names
     final String? jcore;
     final String? mjux;
     final String? appx;
     final int dataSchemaVersion;  // renamed from jv
     final int? uxSchemaVersion;
     final int resultSchemaId;     // renamed from jid
     final int? encoding;          // renamed from jnf
     final List<String>? columns;
     
     // Legacy compatibility (computed properties)
     @Deprecated('Use dataSchemaVersion')
     int get jv => dataSchemaVersion;
     
     @Deprecated('Use resultSchemaId')
     int get jid => resultSchemaId;
     
     @Deprecated('Use encoding')
     int? get jnf => encoding;
     
     // Existing fields
     final Map<String, int>? schema;
     final List<List<dynamic>>? data;
   }
   ```

2. Update `fromJson` constructor:
   - Accept both old and new field names
   - Detect conflicts between old/new spellings
   - Throw `FormatException` on conflicts
   - Map legacy names to canonical fields

3. Update `toJson` method:
   - Emit only new canonical names
   - Include version fields when present
   - Include `columns` field for tabular results

4. Update encoding validation:
   - Accept modes 0-5 and 8-13
   - Reject modes 6, 7, 14+
   - Add `isExtendedMode` getter (modes 8-13)
   - Add `baseMode` getter (encoding - 8 for extended modes)

5. Add temporal value helpers:
   ```dart
   String _formatDateTime(int epochMillis);
   int _parseDateTime(String rfc3339);
   String _formatTime(int millisSinceMidnight);
   int _parseTime(String hhmmss);
   ```

### Phase 2: Encoding Mode Support

**File: `dart/lib/src/data/jconverter.dart`**

1. Add temporal type detection:
   - Identify DATETIME, TIME, DATE types by ID
   - Handle temporal values based on encoding mode

2. Extend `toMaps` for modes 8-13:
   - Convert text temporal strings to internal forms
   - Validate RFC 3339 and HH:mm:ss.SSS formats
   - Handle timezone normalization for DATETIME

3. Extend `fromMaps` for modes 8-13:
   - Convert internal temporal forms to text
   - Format DATETIME as RFC 3339 with millis
   - Format TIME as HH:mm:ss.SSS

4. Update validation to check temporal formats

### Phase 3: Column Ordering

**File: `dart/lib/src/data/jsonc.dart`**

1. Add `columns` field handling:
   - Generate from schema keys if not provided
   - Use explicit ordering when decoding rows
   - Validate schema keys match columns

2. Update row decoding:
   - Use `columns` order regardless of JSON object key order
   - Handle JSONB key reordering gracefully

3. Add schema cache resolution:
   - Look up schema by `resultSchemaId` + `dataSchemaVersion`
   - Support authority-scoped caching
   - Merge data-only with cached schema

### Phase 4: Testing

**File: `dart/test/jsonc_extended_test.dart` (new)**

1. Test backward compatibility:
   - Accept old field names (`jv`, `jid`, `jnf`)
   - Emit new field names in output
   - Reject conflicting old/new values
   - Preserve legacy behavior for modes 0-5

2. Test encoding modes 8-13:
   - Verify text temporal formatting
   - Test RFC 3339 parsing with various timezones
   - Test HH:mm:ss.SSS parsing
   - Verify mode 13 string representations
   - Test invalid temporal values rejection

3. Test column ordering:
   - Verify explicit column order used
   - Test with reordered schema keys
   - Test data-only schema resolution

4. Test version fields:
   - Verify version inclusion in output
   - Test optional version fields

5. Test edge cases:
   - Undefined mode rejection (6, 7, 14+)
   - Invalid temporal format rejection
   - Boundary values for DATETIME/TIME
   - NULL temporal values
   - INT64 precision in mode 13

**File: `dart/test/jsonc_fixtures.dart` (new)**

Create fixtures for all 12 valid modes:
- Products example (INT64 IDs, NUMERIC amounts, DATETIME timestamps)
- Time schedule example (TIME values)
- Mixed temporal types
- Boundary values
- Legacy format examples

### Phase 5: Specification Updates

**File: `docs/dart/JNF_ENCODING_SPEC.md`**

1. Update title to "JNF Encoding Specification v2.0"
2. Document new canonical field names
3. Add modes 8-13 to encoding table
4. Document temporal value formats
5. Add migration guide from v1 to v2
6. Update examples with new field names
7. Document column ordering behavior
8. Add negotiation protocol

**File: `docs/dart/JSONC_API_CONTRACT.md` (new)**

Document the POST /api/query/{q} contract:
- Request format with encoding negotiation
- Response format with all fields
- Version tracking semantics
- Error responses
- Client capability detection

### Phase 6: Go Implementation (Future)

**Note**: Go JSONC codec does not currently exist. This outlines what needs to be created.

**File: `go/jsonc/jsonc.go` (new)**

1. Create `JsonC` struct matching Dart implementation
2. Implement JSON marshaling/unmarshaling
3. Support all 12 encoding modes
4. Handle temporal value conversions
5. Implement backward compatibility
6. Add comprehensive tests

This is deferred to a future cycle as the current JCore Go implementation focuses on metax only.

## Verification Checklist

### Dart Implementation

- [ ] All legacy payloads parse correctly
- [ ] New payloads emit canonical field names only
- [ ] Conflicting old/new field values rejected
- [ ] All 12 valid modes (0-5, 8-13) work correctly
- [ ] Undefined modes (6, 7, 14+) rejected
- [ ] Mode 13 produces correct string formats
- [ ] INT64 exact precision preserved in mode 13
- [ ] Decimal exact precision preserved in mode 13
- [ ] DATETIME formats as RFC 3339 with millis in modes 8-13
- [ ] TIME formats as HH:mm:ss.SSS in modes 8-13
- [ ] DATETIME timezone handling correct (UTC normalization)
- [ ] Invalid temporal string formats rejected
- [ ] DATE boundary values handled correctly
- [ ] TIME boundary values (00:00:00.000, 23:59:59.999) handled
- [ ] DATETIME epoch boundaries handled
- [ ] Column ordering used regardless of JSON key order
- [ ] JSONB key reordering handled correctly
- [ ] Data-only schema resolution works
- [ ] Schema cache version mismatches detected
- [ ] NULL temporal values handled
- [ ] Composed result shapes preserved (object, array, null)
- [ ] `flutter analyze` passes with no issues
- [ ] All existing tests still pass
- [ ] New tests cover all modes and edge cases

### Browser Precision Check

- [ ] Mode 13 INT64 strings preserve full precision in browser
- [ ] Mode 13 decimal strings preserve exact values in browser
- [ ] JavaScript Number.MAX_SAFE_INTEGER boundary tested
- [ ] Verify no automatic string-to-number coercion

### Go Implementation (Future)

- [ ] Go struct matches Dart implementation
- [ ] JSON marshaling produces same output as Dart
- [ ] JSON unmarshaling handles all valid inputs
- [ ] All encoding modes implemented
- [ ] Temporal value handling matches Dart
- [ ] Go tests pass

## Package Revisions to Pin

### For This Cycle

**JCore Dart**:
- Branch: `main`
- Commit: TBD (after implementation)
- Version: 4.5.0 (new minor version for API extension)

**MJUX**:
- No changes required in this cycle
- Current: commit 15c35d0, version 0.2.0

### Consumer Integration

**ContextStudio**:
- Update to JCore 4.5.0+
- Request encoding mode 13 for web deployment
- Request encoding mode 2 for native deployment
- Include `appx` in responses

**Dataset**:
- Update to JCore 4.5.0+
- Request encoding mode based on deployment target
- Handle temporal text formats in modes 8-13

**AIXHub**:
- Update to JCore 4.5.0+
- Implement POST /api/query/{q} endpoint
- Support encoding negotiation
- Emit canonical field names

**APIHub**:
- Update to JCore 4.5.0+
- Forward JSONC responses without modification
- Preserve encoding mode from backend

## Integration Gaps

### Not Implemented in This Cycle

1. **Go JSONC Codec**:
   - Go implementation deferred to future cycle
   - Specification documented for future implementation
   - Dart implementation serves as reference

2. **Temporal Type Registry**:
   - TIME and DATE type IDs need confirmation
   - Current implementation assumes DATETIME = 40001
   - May need registry update

3. **UX Schema Version Tracking**:
   - `uxSchemaVersion` field added but semantic unclear
   - Needs coordination with UIDef specification versioning

4. **Authority Scope Resolution**:
   - Schema cache lookup by authority not yet implemented
   - Deferred to when multi-tenant support added

5. **Client Capability Detection**:
   - Extended mode negotiation protocol specified but not implemented
   - Currently all modes available if encoding field set

6. **Comprehensive Widget Tests**:
   - AdaptiveWorkspace navigation behaviors implemented but lack automated tests
   - Manual testing confirmed functionality

## Implementation Status

**Completed**:
- ✅ Research and specification of requirements
- ✅ Detailed implementation plan created
- ✅ Verification checklist defined
- ✅ Integration approach documented

**In Progress**:
- 🔄 This document serves as the handoff specification

**Not Started** (requires actual code changes):
- ⬜ Dart JsonC class updates
- ⬜ Encoding mode 8-13 implementation
- ⬜ Temporal value helpers
- ⬜ Column ordering implementation
- ⬜ Test suite expansion
- ⬜ Specification document updates
- ⬜ Go implementation planning

## Estimated Effort

**Dart Implementation**: 8-12 hours
- JsonC class updates: 2 hours
- Encoding mode support: 3 hours
- Temporal value handling: 2 hours
- Column ordering: 1 hour
- Testing: 3-4 hours
- Documentation: 1 hour

**Go Implementation** (future): 12-16 hours
- Initial codec: 4 hours
- Encoding modes: 4 hours
- Temporal handling: 3 hours
- Testing: 4 hours
- Documentation: 1 hour

## Next Steps

1. Review and approve this specification
2. Confirm temporal type IDs from registry
3. Clarify UX schema version semantics
4. Implement Phase 1: Core Type Updates
5. Implement Phase 2: Encoding Mode Support
6. Implement Phase 3: Column Ordering
7. Implement Phase 4: Testing
8. Update Phase 5: Specification
9. Verify all checklist items
10. Create final handoff document for consumers

---

**Document Version**: 1.0  
**Created**: 2024-01-15  
**Status**: Specification Complete - Awaiting Implementation
