package metax

import (
	"encoding/json"
	"testing"
)

func TestDecodeTableType(t *testing.T) {
	tests := []struct {
		name           string
		tt             int
		wantAlgorithm  int
		wantSyncPolicy int
		wantLogging    int
		wantRecursion  int
		wantIDFormat   int
		wantErr        bool
	}{
		{
			name:           "Private Auto-increment BIGINT flat log-off (default)",
			tt:             100040,
			wantAlgorithm:  1,
			wantSyncPolicy: 0,
			wantLogging:    0,
			wantRecursion:  0,
			wantIDFormat:   4,
			wantErr:        false,
		},
		{
			name:           "Main Auto-increment BIGINT flat log-on",
			tt:             100342,
			wantAlgorithm:  1,
			wantSyncPolicy: 3,
			wantLogging:    1,
			wantRecursion:  0,
			wantIDFormat:   4,
			wantErr:        false,
		},
		{
			name:           "Private Custom BIGINT flat log-off (inherited ID)",
			tt:             100010,
			wantAlgorithm:  0,
			wantSyncPolicy: 0,
			wantLogging:    0,
			wantRecursion:  0,
			wantIDFormat:   4,
			wantErr:        false,
		},
		{
			name:    "Invalid table type",
			tt:      999999,
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tableType, err := DecodeTableType(tt.tt)
			if tt.wantErr {
				if err == nil {
					t.Error("Expected error but got none")
				}
				return
			}
			if err != nil {
				t.Fatalf("Unexpected error: %v", err)
			}
			if tableType.Algorithm != tt.wantAlgorithm {
				t.Errorf("Algorithm = %v, want %v", tableType.Algorithm, tt.wantAlgorithm)
			}
			if tableType.SyncPolicy != tt.wantSyncPolicy {
				t.Errorf("SyncPolicy = %v, want %v", tableType.SyncPolicy, tt.wantSyncPolicy)
			}
			if tableType.Logging != tt.wantLogging {
				t.Errorf("Logging = %v, want %v", tableType.Logging, tt.wantLogging)
			}
			if tableType.Recursion != tt.wantRecursion {
				t.Errorf("Recursion = %v, want %v", tableType.Recursion, tt.wantRecursion)
			}
			if tableType.IDFormat != tt.wantIDFormat {
				t.Errorf("IDFormat = %v, want %v", tableType.IDFormat, tt.wantIDFormat)
			}
		})
	}
}

func TestIsValidTableType(t *testing.T) {
	tests := []struct {
		name  string
		tt    int
		valid bool
	}{
		{"Valid: 100040 (default)", 100040, true},
		{"Valid: 100342 (Main with logging)", 100342, true},
		{"Valid: 100010 (Custom BIGINT)", 100010, true},
		{"Invalid: too low", 99999, false},
		{"Invalid: too high", 110000, false},
		{"Invalid: Main without logging", 100340, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := IsValidTableType(tt.tt); got != tt.valid {
				t.Errorf("IsValidTableType(%d) = %v, want %v", tt.tt, got, tt.valid)
			}
		})
	}
}

func TestTableX_JSON(t *testing.T) {
	tt := 101013
	table := &TableX{
		ID: 1001,
		A:  intPtr(1),
		DXI: intPtr(100),
		N:  strPtr("Users Table"),
		TTX: &tt,
	}

	data, err := json.Marshal(table)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded TableX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != table.ID || *decoded.TTX != *table.TTX {
		t.Errorf("JSON roundtrip failed")
	}
}

func intPtr(i int) *int {
	return &i
}

func strPtr(s string) *string {
	return &s
}
