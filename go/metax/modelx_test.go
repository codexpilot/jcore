package metax

import (
	"encoding/json"
	"testing"
)

func TestModelX_Orientation(t *testing.T) {
	tests := []struct {
		name string
		mt   *int
		want int
	}{
		{"nil defaults to 1", nil, 1},
		{"Independent", intPtr(0), 0},
		{"Model-after-table", intPtr(10000), 1},
		{"Table-after-model", intPtr(20000), 2},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			m := &ModelX{MTX: tt.mt}
			if got := m.Orientation(); got != tt.want {
				t.Errorf("Orientation() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestModelX_RequiresPhysicalBases(t *testing.T) {
	independent := &ModelX{MTX: intPtr(0)}
	if independent.RequiresPhysicalBases() {
		t.Error("Independent model should not require physical bases")
	}

	dependent := &ModelX{MTX: intPtr(10000)}
	if !dependent.RequiresPhysicalBases() {
		t.Error("Dependent model should require physical bases")
	}
}

func TestModelX_JSON(t *testing.T) {
	model := &ModelX{
		ID:         1001,
		A:          intPtr(1),
		DXI:        intPtr(100),
		N:          strPtr("User Model"),
		C:          strPtr("user"),
		P:          []int{10, 20},
		MTX:        intPtr(10000),
	}

	data, err := json.Marshal(model)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded ModelX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != model.ID || *decoded.DXI != *model.DXI {
		t.Errorf("JSON roundtrip failed")
	}
}
