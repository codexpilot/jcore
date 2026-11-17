package metax

import "strconv"

// ParamX represents query parameter metadata from mx.paramx table
type ParamX struct {
	I   int    `json:"i"`   // Parameter ID
	D   int    `json:"d"`   // Last edit timestamp
	E   int    `json:"e"`   // Editor user ID
	A   int    `json:"a"`   // Active status
	DXI int    `json:"dxi"` // Domain ID
	Q   int    `json:"q"`   // Query ID
	N   string `json:"n"`   // Display name
	C   string `json:"c"`   // Code (unique within query)
	DTX int    `json:"dtx"` // Data type (TypeX Group 3)
	Req bool   `json:"req"` // Required flag
	FP  int    `json:"fp"`  // Optional recursive parent identifier
}

// String returns a string representation of the parameter
func (p *ParamX) String() string {
	return "ParamX(i=" + strconv.Itoa(p.I) + ", n=" + p.N + ", c=" + p.C + ", req=" + strconv.FormatBool(p.Req) + ")"
}
