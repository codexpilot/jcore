package metax

import (
	"encoding/json"
	"testing"
)

func TestFieldX_Capabilities(t *testing.T) {
	tests := []struct {
		name string
		ft   int
		want FieldCapabilities
	}{
		{"Bidirectional", 400000, Bidirectional},
		{"InputOnly", 400001, InputOnly},
		{"OutputOnly", 400002, OutputOnly},
		{"Unknown defaults to Bidirectional", 999999, Bidirectional},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &FieldX{FTX: tt.ft}
			if got := f.Capabilities(); got != tt.want {
				t.Errorf("Capabilities() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestFieldX_CanInput(t *testing.T) {
	tests := []struct {
		name string
		ft   int
		want bool
	}{
		{"Bidirectional can input", 400000, true},
		{"InputOnly can input", 400001, true},
		{"OutputOnly cannot input", 400002, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &FieldX{FTX: tt.ft}
			if got := f.CanInput(); got != tt.want {
				t.Errorf("CanInput() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestFieldX_CanOutput(t *testing.T) {
	tests := []struct {
		name string
		ft   int
		want bool
	}{
		{"Bidirectional can output", 400000, true},
		{"InputOnly cannot output", 400001, false},
		{"OutputOnly can output", 400002, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &FieldX{FTX: tt.ft}
			if got := f.CanOutput(); got != tt.want {
				t.Errorf("CanOutput() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestFieldX_JSON(t *testing.T) {
	field := &FieldX{
		I:    1001,
		D:    1700000000000,
		E:    42,
		A:    1,
		DXI:  100,
		N:    "Username",
		MXI:  500,
		CXIS: []int{10, 20},
		CTX:  200001,
		DTX:  300001,
		C:    "username",
		FTX:  400000,
		FP:   0,
	}

	// Marshal to JSON
	data, err := json.Marshal(field)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	// Unmarshal back
	var decoded FieldX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	// Compare key fields
	if decoded.I != field.I || decoded.N != field.N || decoded.C != field.C {
		t.Errorf("JSON roundtrip failed: got %+v, want %+v", decoded, field)
	}
}
