# JCore Go - MetaX Package

Go implementation of AIX MetaX metadata models, mirroring the Dart implementation in ContextStudio.

## Models

This package provides Go structs for all AIX MetaX tables:

| Model | Database Table | Description |
|-------|----------------|-------------|
| `DomainX` | `cox.domainx` | Domain hierarchy (Framework/Template/Solution) |
| `TableX` | `mx.tablex` | Physical table metadata with table type decoding |
| `ColumnX` | `mx.columnx` | Physical column metadata |
| `ModelX` | `mx.modelx` | Logical model metadata with orientation detection |
| `FieldX` | `mx.fieldx` | Logical field metadata with capability detection |
| `QueryX` | `mx.queryx` | Query operation metadata |
| `ParamX` | `mx.paramx` | Query parameter metadata |
| `SqlX` | `mx.sqlx` | SQL implementation metadata |

## Features

- **JSON Serialization**: All models support `json.Marshal` and `json.Unmarshal`
- **Type Detection**: Helper methods for domain types, model orientation, field capabilities
- **Table Type Decoding**: Full table type validation and decoding (sync/log/algorithm/format)
- **Query Types**: Enum-like constants for query operations (SystemGet, TableGet, ModelGet)
- **Field Capabilities**: Detection of input/output capabilities (Bidirectional, InputOnly, OutputOnly)

## Usage

```go
import "github.com/codexpilot/jcore/go/metax"

// Parse domain type
domain := &metax.DomainX{I: -1}
fmt.Println(domain.TypeLabel())  // "Framework Root"
fmt.Println(domain.IsTemplate()) // false

// Decode table type
tableType, err := metax.DecodeTableType(101013)
if err != nil {
    log.Fatal(err)
}
fmt.Println(tableType.Description)
// "Protected • Log Off • INT • Auto-increment"

// Check field capabilities
field := &metax.FieldX{FT: 400001} // InputOnly
fmt.Println(field.CanInput())  // true
fmt.Println(field.CanOutput()) // false

// Query type detection
if metax.SystemGet.IsGet() {
    fmt.Println("This is a get operation")
}
```

## JSON Marshaling

All models implement custom JSON marshaling that omits zero/nil values appropriately:

```go
table := &metax.TableX{
    ID: 1001,
    N:  strPtr("users"),
    TT: intPtr(101013),
}

data, _ := json.Marshal(table)
// {"i":1001,"n":"users","tt":101013}
```

## Testing

Run all tests:

```bash
cd /Users/Shared/dev/git/jcore/go
go test ./metax/... -v
```

All tests cover:
- JSON serialization/deserialization
- Type detection and validation
- Helper method correctness
- Edge cases and error handling

## Architecture Notes

- Follows Go naming conventions (PascalCase for exports)
- Uses pointers for optional fields to distinguish between zero values and absence
- Custom JSON marshaling for conditional field inclusion
- Matches Dart implementation behavior while being idiomatic Go
