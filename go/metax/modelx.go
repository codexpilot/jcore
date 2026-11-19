package metax

import "encoding/json"

// ModelX represents a logical model record from mx.modelx
type ModelX struct {
	ID         int     `json:"i"`                    // Model ID
	FP         int     `json:"fp,omitempty"`         // Optional recursive parent identifier
	D          *int    `json:"d,omitempty"`          // Date of last edit
	E          *int    `json:"e,omitempty"`          // Last editor user ID
	A          *int    `json:"a,omitempty"`          // Active status
	DXI        *int    `json:"dxi,omitempty"`        // Domain ID
	N          *string `json:"n,omitempty"`          // Name
	F          *int    `json:"f,omitempty"`          // Provenance: 0=native, >0=copied, <0=imported
	C          *string `json:"c,omitempty"`          // Code
	Ps         []int   `json:"ps,omitempty"`         // Parent model IDs
	MTX        *int    `json:"mtx,omitempty"`        // Model type
}

// Orientation returns the model orientation from MTX field
// 0=independent, 1=model-after-table, 2=table-after-model
func (m *ModelX) Orientation() int {
	if m.MTX == nil {
		return 1
	}
	return (*m.MTX / 10000) % 10
}

// RequiresPhysicalBases returns whether the model requires physical bases
func (m *ModelX) RequiresPhysicalBases() bool {
	return m.Orientation() != 0
}

// MarshalJSON implements custom JSON marshaling
func (mx *ModelX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if mx.ID > 0 {
		data["i"] = mx.ID
	}
	if mx.A != nil {
		data["a"] = *mx.A
	}
	if mx.DXI != nil {
		data["dxi"] = *mx.DXI
	}
	if mx.N != nil {
		data["n"] = *mx.N
	}
	if mx.F != nil {
		data["f"] = *mx.F
	}
	if mx.Ps != nil {
		data["ps"] = mx.Ps
	}
	if mx.MTX != nil {
		data["mtx"] = *mx.MTX
	}
	return json.Marshal(data)
}
