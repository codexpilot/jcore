package metax

import (
	"encoding/json"
	"strconv"
)

// DomainX represents a domain hierarchy record from cox.domainx table
type DomainX struct {
	I   int    `json:"i"`            // ID
	D   int    `json:"d"`            // Date of last edit (epoch ms)
	E   int    `json:"e"`            // Last editor user ID
	A   int    `json:"a"`            // Active status (0=inactive, 1=active)
	N   string `json:"n"`            // Name
	C   string `json:"c"`            // Code
	P     int   `json:"p"`      // Parent ID
	IDXIS []int `json:"i_dxis"` // Import source domain IDs (template domains)
	CDXIS []int `json:"c_dxis"` // Copy source domain IDs (solution domains)
	SC    int   `json:"sc"`     // Server count digits
	TC  int    `json:"tc"`           // Terminal count digits
	RY  int    `json:"ry"`           // Reference year
	CC  int    `json:"cc"`           // Count capacity
}

// IsActive returns whether the domain is active
func (d *DomainX) IsActive() bool {
	return d.A == 1
}

// IsRoot returns whether this is a root domain (self-parent)
func (d *DomainX) IsRoot() bool {
	return d.I == d.P
}

// Type returns the domain type based on ID range
func (d *DomainX) Type() DomainType {
	if d.I >= 1 {
		return DomainTypeSolution
	}
	if d.I <= -1001 {
		return DomainTypeTemplate
	}
	if d.I >= -1000 && d.I <= -1 {
		return DomainTypeFramework
	}
	return DomainTypeUnknown
}

// TypeLabel returns the human-readable domain type
func (d *DomainX) TypeLabel() string {
	switch d.Type() {
	case DomainTypeFramework:
		return "Framework"
	case DomainTypeTemplate:
		return "Template"
	case DomainTypeSolution:
		return "Solution"
	default:
		return "Unknown"
	}
}

// DomainType represents the category of a domain
type DomainType int

const (
	DomainTypeUnknown DomainType = iota
	DomainTypeFramework
	DomainTypeTemplate
	DomainTypeSolution
)

// StatusLabel returns the human-readable status
func (d *DomainX) StatusLabel() string {
	if d.IsActive() {
		return "Active"
	}
	return "Inactive"
}

// MaxServers returns the maximum number of servers
func (d *DomainX) MaxServers() int {
	if d.SC <= 0 {
		return 0
	}
	max := 1
	for i := 0; i < d.SC; i++ {
		max *= 10
	}
	return max - 1
}

// MaxTerminals returns the maximum number of terminals
func (d *DomainX) MaxTerminals() int {
	if d.TC <= 0 {
		return 0
	}
	max := 1
	for i := 0; i < d.TC; i++ {
		max *= 10
	}
	return max - 1
}

// MaxSerialPerMs returns the maximum serial number per millisecond
func (d *DomainX) MaxSerialPerMs() int {
	if d.CC <= 0 {
		return 0
	}
	max := 1
	for i := 0; i < d.CC; i++ {
		max *= 10
	}
	return max - 1
}

// EpochDescription returns the human-readable epoch description
func (d *DomainX) EpochDescription() string {
	if d.RY == -1 {
		return "Current year at generation"
	}
	if d.RY == 0 {
		return "Unix epoch (1970)"
	}
	return "Year " + strconv.Itoa(1970+d.RY)
}

// MarshalJSON implements custom JSON marshaling
func (d *DomainX) MarshalJSON() ([]byte, error) {
	type Alias DomainX
	data := struct {
		*Alias
	}{
		Alias: (*Alias)(d),
	}
	if d.I == 0 {
		return json.Marshal(struct {
			*Alias
			I *int `json:"i,omitempty"`
		}{
			Alias: (*Alias)(d),
			I:     nil,
		})
	}
	return json.Marshal(data)
}
