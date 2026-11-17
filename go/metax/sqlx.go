package metax

import (
	"encoding/json"
)

// SqlX represents SQL implementation metadata from mx.sqlx
type SqlX struct {
	ID  int     `json:"i"`            // SQL implementation ID
	F   int     `json:"f,omitempty"`  // Origin (default 0)
	D   *string `json:"d,omitempty"`  // Date of last edit
	E   *string `json:"e,omitempty"`  // Last editor user ID
	DXI *int    `json:"dxi,omitempty"`// Domain ID
	Q   *int    `json:"q,omitempty"`  // Query ID
	N   *string `json:"n,omitempty"`  // Name
	C   *string `json:"c,omitempty"`  // Code
	DBT *int    `json:"dbt,omitempty"`// Database type
	S   *string `json:"s,omitempty"`  // SQL text
}

// MarshalJSON implements custom JSON marshaling
func (s *SqlX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if s.ID > 0 {
		data["i"] = s.ID
	}
	if s.DXI != nil {
		data["dxi"] = *s.DXI
	}
	if s.Q != nil {
		data["q"] = *s.Q
	}
	if s.N != nil {
		data["n"] = *s.N
	}
	if s.C != nil {
		data["c"] = *s.C
	}
	if s.DBT != nil {
		data["dbt"] = *s.DBT
	}
	if s.S != nil {
		data["s"] = *s.S
	}
	return json.Marshal(data)
}
