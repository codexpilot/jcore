package metax

import (
	"encoding/json"
	"testing"
)

func TestEntityX_Orientation(t *testing.T) {
	tests := []struct {
		name string
		et   *int
		want int
	}{
		{"nil defaults to 1", nil, 1},
		{"Independent", intPtr(0), 0},
		{"Entity-after-table", intPtr(10000), 1},
		{"Table-after-entity", intPtr(20000), 2},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			e := &EntityX{ET: tt.et}
			if got := e.Orientation(); got != tt.want {
				t.Errorf("Orientation() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestEntityX_RequiresPhysicalBases(t *testing.T) {
	independent := &EntityX{ET: intPtr(0)}
	if independent.RequiresPhysicalBases() {
		t.Error("Independent entity should not require physical bases")
	}

	dependent := &EntityX{ET: intPtr(10000)}
	if !dependent.RequiresPhysicalBases() {
		t.Error("Dependent entity should require physical bases")
	}
}

func TestEntityX_ModelState(t *testing.T) {
	ready := &EntityX{ModelState: strPtr("ready")}
	if !ready.IsReady() {
		t.Error("IsReady() should be true")
	}
	if ready.IsDraft() {
		t.Error("IsDraft() should be false")
	}

	draft := &EntityX{ModelState: strPtr("draft")}
	if draft.IsReady() {
		t.Error("IsReady() should be false")
	}
	if !draft.IsDraft() {
		t.Error("IsDraft() should be true")
	}
}

func TestEntityX_JSON(t *testing.T) {
	entity := &EntityX{
		ID:         1001,
		A:          intPtr(1),
		DI:         intPtr(100),
		N:          strPtr("User Entity"),
		C:          strPtr("user"),
		P:          []int{10, 20},
		ET:         intPtr(10000),
		Tables:     []int{500, 501},
		ModelState: strPtr("ready"),
	}

	data, err := json.Marshal(entity)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded EntityX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != entity.ID || len(decoded.Tables) != len(entity.Tables) {
		t.Errorf("JSON roundtrip failed")
	}
}
