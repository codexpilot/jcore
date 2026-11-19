package metax

import "strconv"

// FieldCapabilities represents field input/output capabilities
type FieldCapabilities int

const (
	Bidirectional FieldCapabilities = iota // Can be used for input and output
	InputOnly                              // Only for input (e.g., passwords)
	OutputOnly                             // Only for output (e.g., computed fields)
)

func (fc FieldCapabilities) String() string {
	switch fc {
	case Bidirectional:
		return "bidirectional"
	case InputOnly:
		return "inputOnly"
	case OutputOnly:
		return "outputOnly"
	default:
		return "unknown"
	}
}

// FieldX represents logical field metadata from mx.fieldx table
type FieldX struct {
	I   int    `json:"i"`   // Field metadata ID
	D   int    `json:"d"`   // Last edit timestamp
	E   int    `json:"e"`   // Editor user ID
	A   int    `json:"a"`   // Active status
	DXI int    `json:"dxi"` // Domain ID
	N   string `json:"n"`   // Display name
	F    int   `json:"f"`    // Provenance: 0=native, >0=copied, <0=imported
	MXI  int   `json:"mxi"`  // Model ID (references modelx.i)
	CXIS []int `json:"cxis"` // Column IDs (storage binding, references columnx.i)
	CTX int    `json:"ctx"` // Column type (TypeX Group 5)
	DTX int    `json:"dtx"` // Data type (TypeX Group 3)
	C   string `json:"c"`   // Code (unique)
	FTX int    `json:"ftx"` // Field type (TypeX Group 7: 400000-400002)
	FP  int    `json:"fp"`  // Optional recursive parent identifier
}

// Capabilities returns the field capabilities based on type
func (f *FieldX) Capabilities() FieldCapabilities {
	switch f.FTX {
	case 400000:
		return Bidirectional
	case 400001:
		return InputOnly
	case 400002:
		return OutputOnly
	default:
		return Bidirectional
	}
}

// CanInput returns whether this field can be used for input
func (f *FieldX) CanInput() bool {
	return f.FTX == 400000 || f.FTX == 400001
}

// CanOutput returns whether this field can be used for output
func (f *FieldX) CanOutput() bool {
	return f.FTX == 400000 || f.FTX == 400002
}

// String returns a string representation of the field
func (f *FieldX) String() string {
	return "FieldX(i=" + strconv.Itoa(f.I) + ", n=" + f.N + ", c=" + f.C + ", capabilities=" + f.Capabilities().String() + ")"
}
