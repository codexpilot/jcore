package metax

import "strconv"

// FieldCapabilities represents field input/output capabilities
type FieldCapabilities int

const (
	Bidirectional FieldCapabilities = iota // Can be used for input and output
	InputOnly                               // Only for input (e.g., passwords)
	OutputOnly                              // Only for output (e.g., computed fields)
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
	DI  int    `json:"di"`  // Domain ID
	N   string `json:"n"`   // Display name
	Ent int    `json:"ent"` // Parent entity ID
	P   []int  `json:"p"`   // Parent column IDs (storage binding)
	CT  int    `json:"ct"`  // Column type (TypeX Group 5)
	DT  int    `json:"dt"`  // Data type (TypeX Group 3)
	C   string `json:"c"`   // Code (unique)
	FT  int    `json:"ft"`  // Field type (TypeX Group 7: 400000-400002)
	F   int    `json:"f"`   // Origin
}

// Capabilities returns the field capabilities based on type
func (f *FieldX) Capabilities() FieldCapabilities {
	switch f.FT {
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
	return f.FT == 400000 || f.FT == 400001
}

// CanOutput returns whether this field can be used for output
func (f *FieldX) CanOutput() bool {
	return f.FT == 400000 || f.FT == 400002
}

// String returns a string representation of the field
func (f *FieldX) String() string {
	return "FieldX(i=" + strconv.Itoa(f.I) + ", n=" + f.N + ", c=" + f.C + ", capabilities=" + f.Capabilities().String() + ")"
}
