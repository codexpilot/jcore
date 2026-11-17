package metax

import (
	"encoding/json"
	"strconv"
)

// TableX represents a physical table record from mx.tablex
type TableX struct {
	ID  int     `json:"i"`            // Table ID
	F   int     `json:"f,omitempty"`  // Origin (default 0)
	D   *int    `json:"d,omitempty"`  // Date of last edit
	E   *int    `json:"e,omitempty"`  // Last editor user ID
	A   *int    `json:"a,omitempty"`  // Active status
	DXI *int    `json:"dxi,omitempty"`// Domain ID
	N   *string `json:"n,omitempty"`  // Name
	C   *string `json:"c,omitempty"`  // Code
	TTX *int    `json:"ttx,omitempty"`// Table type
	PX  *int    `json:"px,omitempty"` // Partition index
}

// TableType represents a decoded table type
type TableType struct {
	Value         int
	Algorithm     int
	SyncPolicy    int
	LogEnabled    bool
	IDFormat      int
	AlgorithmName string
	PolicyName    string
	FormatName    string
	Description   string
}

// DecodeTableType decodes a table type value
func DecodeTableType(tt int) (*TableType, error) {
	if !IsValidTableType(tt) {
		return nil, ErrInvalidTableType
	}

	key := tt - 100000
	format := key % 10
	algorithm := (key / 10) % 10
	logEnabled := (key / 100) % 10 == 1
	policy := (key / 1000) % 10

	var algorithmName string
	switch algorithm {
	case 0:
		algorithmName = "Custom Function"
	case 1:
		algorithmName = "Increment"
	case 2:
		algorithmName = "Epoch Server Serial"
	default:
		algorithmName = "Unknown"
	}

	var policyName string
	switch policy {
	case 0:
		policyName = "Private"
	case 1:
		policyName = "Protected"
	case 2:
		policyName = "Synced-Origin"
	case 3:
		policyName = "Synced-Origin-Main"
	default:
		policyName = "Unknown"
	}

	var formatName string
	switch format {
	case 3:
		formatName = "INT"
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
		allocation = "Caller-supplied ID"
	case algorithm == 1 && policy >= 2:
		allocation = "Partitioned increment"
	case algorithm == 1:
		allocation = "Auto-increment"
	case algorithm == 2 && (format == 4 || format == 5):
		allocation = "Epoch/server/serial"
	default:
		allocation = "Epoch/server/serial (not yet available)"
	}

	logStatus := "Log Off"
	if logEnabled {
		logStatus = "Log On"
	}

	description := policyName + " • " + logStatus + " • " + formatName + " • " + allocation

	return &TableType{
		Value:         tt,
		Algorithm:     algorithm,
		SyncPolicy:    policy,
		LogEnabled:    logEnabled,
		IDFormat:      format,
		AlgorithmName: algorithmName,
		PolicyName:    policyName,
		FormatName:    formatName,
		Description:   description,
	}, nil
}

// IsValidTableType checks if a table type value is valid
func IsValidTableType(tt int) bool {
	if tt < 100000 || tt >= 110000 {
		return false
	}
	key := tt - 100000
	syncPolicy := (key / 1000) % 10
	log := (key / 100) % 10
	algorithm := (key / 10) % 10
	idFormat := key % 10

	return IsValidVersion1Combination(syncPolicy, log, algorithm, idFormat)
}

// IsValidVersion1Combination validates all table type dimensions
func IsValidVersion1Combination(syncPolicy, log, algorithm, idFormat int) bool {
	if log < 0 || log > 1 || (syncPolicy == 3 && log != 1) {
		return false
	}
	return IsValidCombination(algorithm, syncPolicy, idFormat)
}

// IsValidCombination validates table type dimensions without logging
func IsValidCombination(algorithm, syncPolicy, idFormat int) bool {
	if algorithm < 0 || algorithm > 2 || syncPolicy < 0 || syncPolicy > 3 {
		return false
	}
	if idFormat != 3 && idFormat != 4 && idFormat != 5 {
		return false
	}
	if syncPolicy >= 2 && idFormat == 3 {
		return false
	}
	if algorithm == 1 && idFormat != 3 && idFormat != 4 {
		return false
	}
	if algorithm == 2 && idFormat == 3 {
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
