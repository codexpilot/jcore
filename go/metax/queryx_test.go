package metax

import (
	"encoding/json"
	"testing"
)

func TestQueryType_IsGet(t *testing.T) {
	if !SystemGet.IsGet() {
		t.Error("SystemGet should be a get operation")
	}
	if SystemSet.IsGet() {
		t.Error("SystemSet should not be a get operation")
	}
	if !TableGet.IsGet() {
		t.Error("TableGet should be a get operation")
	}
	if TableSet.IsGet() {
		t.Error("TableSet should not be a get operation")
	}
}

func TestQueryTypeFromID(t *testing.T) {
	tests := []struct {
		name string
		id   int
		want *QueryType
	}{
		{"SystemGet", 500000, &SystemGet},
		{"SystemSet", 500001, &SystemSet},
		{"TableGet", 510000, &TableGet},
		{"TableSet", 510001, &TableSet},
		{"EntityGet", 520000, &EntityGet},
		{"EntitySet", 520001, &EntitySet},
		{"Unknown", 999999, nil},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := QueryTypeFromID(tt.id)
			if tt.want == nil {
				if got != nil {
					t.Errorf("Expected nil, got %v", got)
				}
			} else {
				if got == nil || got.ID != tt.want.ID {
					t.Errorf("QueryTypeFromID(%d) = %v, want %v", tt.id, got, tt.want)
				}
			}
		})
	}
}

func TestQueryTypeLabel(t *testing.T) {
	qt := 500000
	label := QueryTypeLabel(&qt)
	if label != "System Get" {
		t.Errorf("QueryTypeLabel() = %v, want 'System Get'", label)
	}

	if label := QueryTypeLabel(nil); label != "" {
		t.Errorf("QueryTypeLabel(nil) = %v, want ''", label)
	}
}

func TestQueryX_JSON(t *testing.T) {
	qt := 510000
	query := &QueryX{
		ID:           1001,
		A:            intPtr(1),
		DI:           intPtr(100),
		N:            strPtr("Get User"),
		C:            strPtr("get_user"),
		QT:           &qt,
		TargetKind:   strPtr("table"),
		TableID:      intPtr(500),
		InputFields:  []int{10, 20},
		OutputFields: []int{30, 40},
	}

	data, err := json.Marshal(query)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded QueryX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != query.ID || *decoded.QT != *query.QT {
		t.Errorf("JSON roundtrip failed")
	}
}
