package metax

import "encoding/json"

// ColumnX represents a physical column record from mx.columnx
type ColumnX struct {
	ID  int     `json:"i"`            // Column ID
	F   int     `json:"f,omitempty"`  // Origin (default 0)
	D   *int    `json:"d,omitempty"`  // Date of last edit
	E   *int    `json:"e,omitempty"`  // Last editor user ID
	A   *int    `json:"a,omitempty"`  // Active status
	DXI *int    `json:"dxi,omitempty"`// Domain ID
	N   *string `json:"n,omitempty"`  // Name
	C   *string `json:"c,omitempty"`  // Code
	T   *int    `json:"t,omitempty"`  // Table ID
	CTX *int    `json:"ctx,omitempty"`// Column type (TypeX Group 5)
	DTX *int    `json:"dtx,omitempty"`// Data type (TypeX Group 3)
}

// MarshalJSON implements custom JSON marshaling
func (c *ColumnX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if c.ID > 0 {
		data["i"] = c.ID
	}
	if c.A != nil {
		data["a"] = *c.A
	}
	if c.DXI != nil {
		data["dxi"] = *c.DXI
	}
	if c.N != nil {
		data["n"] = *c.N
	}
	if c.T != nil {
		data["t"] = *c.T
	}
	if c.CTX != nil {
		data["ctx"] = *c.CTX
	}
	if c.DTX != nil {
		data["dtx"] = *c.DTX
	}
	return json.Marshal(data)
}
