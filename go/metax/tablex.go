package metax

import (
	"encoding/json"
	"strconv"
)

// TableX represents a physical table record from mx.tablex
type TableX struct {
	ID  int     `json:"i"`             // Table ID
	FP  int     `json:"fp,omitempty"` // Optional recursive parent identifier
	D   *int    `json:"d,omitempty"`   // Date of last edit
	E   *int    `json:"e,omitempty"`   // Last editor user ID
	A   *int    `json:"a,omitempty"`   // Active status
	DXI *int    `json:"dxi,omitempty"` // Domain ID
	N   *string `json:"n,omitempty"`   // Name
	F   *int    `json:"f,omitempty"`   // Provenance: 0=native, >0=copied, <0=imported
	C   *string `json:"c,omitempty"`   // Code
	TTX *int    `json:"ttx,omitempty"` // Table type
	PX  *int    `json:"px,omitempty"`  // Partition index
}

// TableType represents a decoded table type (SXB format)
type TableType struct {
	Value         int
	Algorithm     int
	SyncPolicy    int
	Logging       int
	Recursion     int
	IDFormat      int
	AlgorithmName string
	PolicyName    string
	FormatName    string
	Description   string
}

// DecodeTableType decodes a table type value using SXB format
// SXB format: 100000 + 100×S + 10×X + B
// where S = sync policy, X = 3×algorithm+(format-3), B = 2×logging+recursion
func DecodeTableType(tt int) (*TableType, error) {
	if !IsValidTableType(tt) {
		return nil, ErrInvalidTableType
	}

	key := tt - 100000
	s := (key / 100) % 10
	x := (key / 10) % 10
	b := key % 10

	// Decode X: X = 3×algorithm + (format-3)
	algorithm := x / 3
	format := 3 + (x % 3)

	// Decode B: B = 2×logging + recursion
	logging := b / 2
	recursion := b % 2

	var algorithmName string
	switch algorithm {
	case 0:
		algorithmName = "Custom/Supplied"
	case 1:
		algorithmName = "Auto-increment"
	case 2:
		algorithmName = "Epoch Server Serial"
	default:
		algorithmName = "Unknown"
	}

	var policyName string
	switch s {
	case 0:
		policyName = "Private"
	case 1:
		policyName = "Protected"
	case 2:
		policyName = "Synced"
	case 3:
		policyName = "Main"
	default:
		policyName = "Unknown"
	}

	var formatName string
	switch format {
	case 3:
		formatName = "INTEGER"
	case 4:
		formatName = "BIGINT"
	case 5:
		formatName = "UUID"
	default:
		formatName = "Unknown"
	}

	var allocation string
	switch {
	case algorithm == 0:
		allocation = "Custom/supplied ID"
	case algorithm == 1 && s >= 2:
		allocation = "Partitioned auto-increment"
	case algorithm == 1:
		allocation = "Auto-increment"
	case algorithm == 2 && (format == 4 || format == 5):
		allocation = "Epoch/server/serial"
	default:
		allocation = "Invalid combination"
	}

	logStatus := "Log off"
	if logging == 1 {
		logStatus = "Log on"
	}

	recursionStatus := ""
	if recursion == 1 {
		recursionStatus = " • Recursive"
	}

	description := policyName + " • " + logStatus + recursionStatus + " • " + formatName + " • " + allocation

	return &TableType{
		Value:         tt,
		Algorithm:     algorithm,
		SyncPolicy:    s,
		Logging:       logging,
		Recursion:     recursion,
		IDFormat:      format,
		AlgorithmName: algorithmName,
		PolicyName:    policyName,
		FormatName:    formatName,
		Description:   description,
	}, nil
}

// IsValidTableType checks if a table type value is valid (SXB format)
func IsValidTableType(tt int) bool {
	if tt < 100000 || tt >= 110000 {
		return false
	}
	key := tt - 100000
	s := (key / 100) % 10
	x := (key / 10) % 10
	b := key % 10

	// Decode components
	algorithm := x / 3
	format := 3 + (x % 3)
	logging := b / 2
	recursion := b % 2

	return IsValidSXBCombination(s, algorithm, format, logging, recursion)
}

// IsValidSXBCombination validates SXB table type components
func IsValidSXBCombination(syncPolicy, algorithm, format, logging, recursion int) bool {
	// Valid ranges
	if syncPolicy < 0 || syncPolicy > 3 {
		return false
	}
	if algorithm < 0 || algorithm > 2 {
		return false
	}
	if format < 3 || format > 5 {
		return false
	}
	if logging < 0 || logging > 1 {
		return false
	}
	if recursion < 0 || recursion > 1 {
		return false
	}

	// Main requires logging
	if syncPolicy == 3 && logging != 1 {
		return false
	}

	// Synced/Main require BIGINT or UUID (not INTEGER)
	if syncPolicy >= 2 && format == 3 {
		return false
	}

	// Auto-increment requires INTEGER or BIGINT (not UUID)
	if algorithm == 1 && format == 5 {
		return false
	}

	// Epoch Server Serial requires BIGINT or UUID (not INTEGER)
	if algorithm == 2 && format == 3 {
		return false
	}

	return true
}

// TableTypeLabel returns a human-readable table type label
func TableTypeLabel(tt *int) string {
	if tt == nil {
		return ""
	}
	tableType, err := DecodeTableType(*tt)
	if err != nil {
		return "Invalid (" + strconv.Itoa(*tt) + ")"
	}
	return tableType.Description
}

// MarshalJSON implements custom JSON marshaling
func (t *TableX) MarshalJSON() ([]byte, error) {
	data := make(map[string]interface{})
	if t.ID > 0 {
		data["i"] = t.ID
	}
	if t.A != nil {
		data["a"] = *t.A
	}
	if t.DXI != nil {
		data["dxi"] = *t.DXI
	}
	if t.N != nil {
		data["n"] = *t.N
	}
	if t.F != nil {
		data["f"] = *t.F
	}
	if t.TTX != nil {
		data["ttx"] = *t.TTX
	}
	if t.PX != nil {
		data["px"] = *t.PX
	}
	return json.Marshal(data)
}

var ErrInvalidTableType = &TableTypeError{"Invalid table type"}

type TableTypeError struct {
	Message string
}

func (e *TableTypeError) Error() string {
	return e.Message
}
