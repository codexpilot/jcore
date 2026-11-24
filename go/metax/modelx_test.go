package metax

import (
	"encoding/json"
	"testing"
)

func TestModelX_JSON(t *testing.T) {
	model := &ModelX{
		ID:  1001,
		A:   intPtr(1),
		DXI: intPtr(100),
		N:   strPtr("User Model"),
		C:   strPtr("user"),
		Ps:  []int{10, 20},
		MTX: intPtr(310000), // Single Table Mapped
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
