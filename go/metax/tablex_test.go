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
		wantLogEnabled bool
		wantIDFormat   int
		wantErr        bool
	}{
		{
			name:           "Protected Auto-increment INT",
			tt:             101013,
			wantAlgorithm:  1,
			wantSyncPolicy: 1,
			wantLogEnabled: false,
			wantIDFormat:   3,
			wantErr:        false,
		},
		{
			name:           "Synced-Origin-Main with logging BIGINT Increment",
			tt:             103114,
			wantAlgorithm:  1,
			wantSyncPolicy: 3,
			wantLogEnabled: true,
			wantIDFormat:   4,
			wantErr:        false,
		},
		{
			name:           "Synced-Origin Epoch Server Serial UUID",
			tt:             102025,
			wantAlgorithm:  2,
			wantSyncPolicy: 2,
			wantLogEnabled: false,
			wantIDFormat:   5,
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
			if tableType.LogEnabled != tt.wantLogEnabled {
				t.Errorf("LogEnabled = %v, want %v", tableType.LogEnabled, tt.wantLogEnabled)
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
		{"Valid: 101013", 101013, true},
		{"Valid: 103114", 103114, true},
		{"Valid: 102025", 102025, true},
		{"Invalid: too low", 99999, false},
		{"Invalid: too high", 110000, false},
		{"Invalid: sync 3 without logging", 103014, false},
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
