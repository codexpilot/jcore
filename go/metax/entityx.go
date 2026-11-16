package metax

import "encoding/json"

// EntityX represents a logical entity record from mx.entityx
type EntityX struct {
	ID         int     `json:"i"`                    // Entity ID
	F          int     `json:"f,omitempty"`          // Origin (default 0)
	D          *int    `json:"d,omitempty"`          // Date of last edit
	E          *int    `json:"e,omitempty"`          // Last editor user ID
	A          *int    `json:"a,omitempty"`          // Active status
	DI         *int    `json:"di,omitempty"`         // Domain ID
	N          *string `json:"n,omitempty"`          // Name
	C          *string `json:"c,omitempty"`          // Code
	P          []int   `json:"p,omitempty"`          // Parent column IDs
	ET         *int    `json:"et,omitempty"`         // Entity type
	Tables     []int   `json:"tables"`               // Associated table IDs
	ModelState *string `json:"model_state,omitempty"`// Model state (draft/ready)
}

// Orientation returns the entity orientation from ET field
// 0=independent, 1=entity-after-table, 2=table-after-entity
func (e *EntityX) Orientation() int {
	if e.ET == nil {
		return 1
	}
	return (*e.ET / 10000) % 10
}

// RequiresPhysicalBases returns whether the entity requires physical bases
func (e *EntityX) RequiresPhysicalBases() bool {
	return e.Orientation() != 0
}

// IsReady returns whether the server has validated this entity for publication
func (e *EntityX) IsReady() bool {
	return e.ModelState != nil && *e.ModelState == "ready"
}

// IsDraft returns whether this entity is still being designed
func (e *EntityX) IsDraft() bool {
	return e.ModelState != nil && *e.ModelState == "draft"
}

// MarshalJSON implements custom JSON marshaling
func (ex *EntityX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if ex.ID > 0 {
		data["i"] = ex.ID
	}
	if ex.A != nil {
		data["a"] = *ex.A
	}
	if ex.DI != nil {
		data["di"] = *ex.DI
	}
	if ex.N != nil {
		data["n"] = *ex.N
	}
	if ex.P != nil {
		data["p"] = ex.P
	}
	if ex.ET != nil {
		data["et"] = *ex.ET
	}
	if ex.ModelState != nil {
		data["model_state"] = *ex.ModelState
	}
	data["tables"] = ex.Tables
	return json.Marshal(data)
}
