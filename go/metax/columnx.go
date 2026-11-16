package metax

import "encoding/json"

// ColumnX represents a physical column record from mx.columnx
type ColumnX struct {
	ID int     `json:"i"`           // Column ID
	F  int     `json:"f,omitempty"` // Origin (default 0)
	D  *int    `json:"d,omitempty"` // Date of last edit
	E  *int    `json:"e,omitempty"` // Last editor user ID
	A  *int    `json:"a,omitempty"` // Active status
	DI *int    `json:"di,omitempty"`// Domain ID
	N  *string `json:"n,omitempty"` // Name
	C  *string `json:"c,omitempty"` // Code
	T  *int    `json:"t,omitempty"` // Table ID
	CT *int    `json:"ct,omitempty"`// Column type (TypeX Group 5)
	DT *int    `json:"dt,omitempty"`// Data type (TypeX Group 3)
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
	if c.DI != nil {
		data["di"] = *c.DI
	}
	if c.N != nil {
		data["n"] = *c.N
	}
	if c.T != nil {
		data["t"] = *c.T
	}
	if c.CT != nil {
		data["ct"] = *c.CT
	}
	if c.DT != nil {
		data["dt"] = *c.DT
	}
	return json.Marshal(data)
}
