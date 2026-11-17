package metax

import "encoding/json"

// ModelX represents a logical model record from mx.modelx
type ModelX struct {
	ID         int     `json:"i"`                    // Model ID
	F          int     `json:"f,omitempty"`          // Origin (default 0)
	D          *int    `json:"d,omitempty"`          // Date of last edit
	E          *int    `json:"e,omitempty"`          // Last editor user ID
	A          *int    `json:"a,omitempty"`          // Active status
	DI         *int    `json:"di,omitempty"`         // Domain ID
	N          *string `json:"n,omitempty"`          // Name
	C          *string `json:"c,omitempty"`          // Code
	P          []int   `json:"p,omitempty"`          // Parent model IDs
	MT         *int    `json:"mt,omitempty"`         // Model type
	Tables     []int   `json:"tables"`               // Associated table IDs
	ModelState *string `json:"model_state,omitempty"`// Model state (draft/ready)
}

// Orientation returns the model orientation from MT field
// 0=independent, 1=model-after-table, 2=table-after-model
func (m *ModelX) Orientation() int {
	if m.MT == nil {
		return 1
	}
	return (*m.MT / 10000) % 10
}

// RequiresPhysicalBases returns whether the model requires physical bases
func (m *ModelX) RequiresPhysicalBases() bool {
	return m.Orientation() != 0
}

// IsReady returns whether the server has validated this model for publication
func (m *ModelX) IsReady() bool {
	return m.ModelState != nil && *m.ModelState == "ready"
}

// IsDraft returns whether this model is still being designed
func (m *ModelX) IsDraft() bool {
	return m.ModelState != nil && *m.ModelState == "draft"
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
	if mx.DI != nil {
		data["di"] = *mx.DI
	}
	if mx.N != nil {
		data["n"] = *mx.N
	}
	if mx.P != nil {
		data["p"] = mx.P
	}
	if mx.MT != nil {
		data["mt"] = *mx.MT
	}
	if mx.ModelState != nil {
		data["model_state"] = *mx.ModelState
	}
	data["tables"] = mx.Tables
	return json.Marshal(data)
}
