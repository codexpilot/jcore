package metax

import "encoding/json"

// ColumnX represents a physical column record from mx.columnx
type ColumnX struct {
	ID  int     `json:"i"`             // Column ID
	FP  int     `json:"fp,omitempty"` // Optional recursive parent identifier
	D   *int    `json:"d,omitempty"`   // Date of last edit
	E   *int    `json:"e,omitempty"`   // Last editor user ID
	A   *int    `json:"a,omitempty"`   // Active status
	DXI *int    `json:"dxi,omitempty"` // Domain ID
	N   *string `json:"n,omitempty"`   // Name
	F   *int    `json:"f,omitempty"`   // Provenance: 0=native, >0=copied, <0=imported
	C   *string `json:"c,omitempty"`   // Code
	TXI *int    `json:"txi,omitempty"` // Table ID (references tablex.i)
	CTX *int    `json:"ctx,omitempty"` // Column type (TypeX Group 5)
	DT *int    `json:"dt,omitempty"` // Data type (TypeX Group 3)
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
	if c.F != nil {
		data["f"] = *c.F
	}
	if c.TXI != nil {
		data["txi"] = *c.TXI
	}
	if c.CTX != nil {
		data["ctx"] = *c.CTX
	}
	if c.DT != nil {
		data["dt"] = *c.DT
	}
	return json.Marshal(data)
}
