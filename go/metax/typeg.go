package metax

import "strconv"

// TypeG represents a type group record from cox.typeg
type TypeG struct {
	I int    `json:"i"` // Group ID
	D int64  `json:"d"` // Date of last edit (epoch ms)
	N string `json:"n"` // Group name
}

// String returns a string representation of the type group
func (tg *TypeG) String() string {
	return "TypeG(i=" + strconv.Itoa(tg.I) + ", n=" + tg.N + ")"
}
