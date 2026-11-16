package metax

import (
	"encoding/json"
	"testing"
)

func TestColumnX_JSON(t *testing.T) {
	column := &ColumnX{
		ID: 1001,
		A:  intPtr(1),
		DI: intPtr(100),
		N:  strPtr("id"),
		C:  strPtr("i"),
		T:  intPtr(500),
		CT: intPtr(200001),
		DT: intPtr(300004),
	}

	data, err := json.Marshal(column)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded ColumnX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != column.ID || *decoded.CT != *column.CT || *decoded.DT != *column.DT {
		t.Errorf("JSON roundtrip failed")
	}
}
