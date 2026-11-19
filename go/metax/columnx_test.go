package metax

import (
	"encoding/json"
	"testing"
)

func TestColumnX_JSON(t *testing.T) {
	column := &ColumnX{
		ID:  1001,
		A:   intPtr(1),
		DXI: intPtr(100),
		N:   strPtr("id"),
		C:   strPtr("i"),
		TXI: intPtr(500),
		CTX: intPtr(200001),
		DTX: intPtr(300004),
	}

	data, err := json.Marshal(column)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded ColumnX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != column.ID || *decoded.CTX != *column.CTX || *decoded.DTX != *column.DTX {
		t.Errorf("JSON roundtrip failed")
	}
}
