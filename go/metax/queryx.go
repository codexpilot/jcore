package metax

import (
	"encoding/json"
	"strconv"
)

// QueryType represents a query operation type
type QueryType struct {
	ID         int
	Code       string
	Label      string
	TargetKind string
}

var (
	SystemGet  = QueryType{500000, "system_get", "System Get", "system"}
	SystemSet  = QueryType{500001, "system_set", "System Set", "system"}
	TableGet   = QueryType{510000, "table_get", "Table Get", "table"}
	TableSet   = QueryType{510001, "table_set", "Table Set", "table"}
	EntityGet  = QueryType{520000, "entity_get", "Entity Get", "entity"}
	EntitySet  = QueryType{520001, "entity_set", "Entity Set", "entity"}
)

var queryTypes = []QueryType{
	SystemGet, SystemSet, TableGet, TableSet, EntityGet, EntitySet,
}

// IsGet returns whether this is a get operation
func (qt QueryType) IsGet() bool {
	return qt.ID%2 == 0
}

// QueryTypeFromID returns a QueryType by ID
func QueryTypeFromID(id int) *QueryType {
	for _, qt := range queryTypes {
		if qt.ID == id {
			return &qt
		}
	}
	return nil
}

// QueryX represents a query operation record from mx.queryx
type QueryX struct {
	ID           int                    `json:"i"`                      // Query ID
	F            int                    `json:"f,omitempty"`            // Origin (default 0)
	D            *int                   `json:"d,omitempty"`            // Date of last edit
	E            *int                   `json:"e,omitempty"`            // Last editor user ID
	A            *int                   `json:"a,omitempty"`            // Active status
	DI           *int                   `json:"di,omitempty"`           // Domain ID
	N            *string                `json:"n,omitempty"`            // Name
	C            *string                `json:"c,omitempty"`            // Code
	QT           *int                   `json:"qt,omitempty"`           // Query type
	TargetKind   *string                `json:"target_kind,omitempty"`  // Target kind
	TableID      *int                   `json:"table_id,omitempty"`     // Table ID
	EntityID     *int                   `json:"entity_id,omitempty"`    // Entity ID
	Role         *string                `json:"role,omitempty"`         // Role
	RelationIDs  []int                  `json:"relation_ids,omitempty"` // Relation IDs
	IsSingle     *bool                  `json:"is_single,omitempty"`    // Single result flag
	IsPaged      *bool                  `json:"is_paged,omitempty"`     // Paged result flag
	RequiresID   *bool                  `json:"requires_id,omitempty"`  // Requires ID flag
	InputFields  []int                  `json:"input_fields,omitempty"` // Input field IDs
	OutputFields []int                  `json:"output_fields,omitempty"`// Output field IDs
	SqlxID       *int                   `json:"sqlx_id,omitempty"`      // SQL implementation ID
	CustomSQL    *string                `json:"custom_sql,omitempty"`   // Custom SQL
	TS           []int                  `json:"ts,omitempty"`           // Legacy: timestamps
	OES          []int                  `json:"oes,omitempty"`          // Legacy: output entities
	QS           map[string]interface{} `json:"qs,omitempty"`           // Legacy: query state
	CTX          map[string]interface{} `json:"ctx,omitempty"`          // Legacy: context
	DefaultF     *int                   `json:"default_f,omitempty"`    // Legacy: default origin
}

// QueryTypeLabel returns a human-readable label for a query type
func QueryTypeLabel(qt *int) string {
	if qt == nil {
		return ""
	}
	queryType := QueryTypeFromID(*qt)
	if queryType == nil {
		return "Unknown (" + strconv.Itoa(*qt) + ")"
	}
	return queryType.Label
}

// MarshalJSON implements custom JSON marshaling
func (q *QueryX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if q.ID > 0 {
		data["i"] = q.ID
	}
	if q.A != nil {
		data["a"] = *q.A
	}
	if q.DI != nil {
		data["di"] = *q.DI
	}
	if q.N != nil {
		data["n"] = *q.N
	}
	if q.C != nil {
		data["c"] = *q.C
	}
	if q.QT != nil {
		data["qt"] = *q.QT
	}
	if q.TargetKind != nil {
		data["target_kind"] = *q.TargetKind
	}
	if q.TableID != nil {
		data["table_id"] = *q.TableID
	}
	if q.EntityID != nil {
		data["entity_id"] = *q.EntityID
	}
	if q.Role != nil {
		data["role"] = *q.Role
	}
	if q.RelationIDs != nil {
		data["relation_ids"] = q.RelationIDs
	}
	if q.IsSingle != nil {
		data["is_single"] = *q.IsSingle
	}
	if q.IsPaged != nil {
		data["is_paged"] = *q.IsPaged
	}
	if q.RequiresID != nil {
		data["requires_id"] = *q.RequiresID
	}
	if q.InputFields != nil {
		data["input_fields"] = q.InputFields
	}
	if q.OutputFields != nil {
		data["output_fields"] = q.OutputFields
	}
	if q.SqlxID != nil {
		data["sqlx_id"] = *q.SqlxID
	}
	if q.CustomSQL != nil {
		data["custom_sql"] = *q.CustomSQL
	}
	if q.TS != nil {
		data["ts"] = q.TS
	}
	if q.OES != nil {
		data["oes"] = q.OES
	}
	if q.QS != nil {
		data["qs"] = q.QS
	}
	if q.CTX != nil {
		data["ctx"] = q.CTX
	}
	if q.DefaultF != nil {
		data["default_f"] = *q.DefaultF
	}
	return json.Marshal(data)
}
