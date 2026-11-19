package metax

import "strconv"

// TypeX represents a type catalog record from cox.typex
type TypeX struct {
	I int    `json:"i"` // Type ID (primary key)
	D int64  `json:"d"` // Date of last edit (epoch ms)
	E int    `json:"e"` // Last editor user ID
	A int    `json:"a"` // Active status (0-3)
	N string `json:"n"` // Type name
	G int    `json:"g"` // Group ID (references typeg)
	K int    `json:"k"` // Key within group
	C string `json:"c"` // Code identifier (kebab-case)
}

// IsActive returns whether the type is active
func (tx *TypeX) IsActive() bool {
	return tx.A >= 1
}

// String returns a string representation of the type
func (tx *TypeX) String() string {
	return "TypeX(i=" + strconv.Itoa(tx.I) + ", n=" + tx.N + ", c=" + tx.C + ", g=" + strconv.Itoa(tx.G) + ")"
}
