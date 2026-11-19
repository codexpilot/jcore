package metax

import (
	"encoding/json"
	"testing"
)

func TestDomainX_TypeDetection(t *testing.T) {
	tests := []struct {
		name      string
		id        int
		parent    int
		isRoot    bool
		domainType DomainType
		typeLabel string
	}{
		{"Framework Root", -1, -1, true, DomainTypeFramework, "Framework"},
		{"Framework Non-Root", -500, -1, false, DomainTypeFramework, "Framework"},
		{"Template Root", -1001, -1001, true, DomainTypeTemplate, "Template"},
		{"Template Non-Root", -2000, -1001, false, DomainTypeTemplate, "Template"},
		{"Solution Root", 1, 1, true, DomainTypeSolution, "Solution"},
		{"Solution Non-Root", 1000, 1, false, DomainTypeSolution, "Solution"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			d := &DomainX{I: tt.id, P: tt.parent}
			if got := d.IsRoot(); got != tt.isRoot {
				t.Errorf("IsRoot() = %v, want %v", got, tt.isRoot)
			}
			if got := d.Type(); got != tt.domainType {
				t.Errorf("Type() = %v, want %v", got, tt.domainType)
			}
			if got := d.TypeLabel(); got != tt.typeLabel {
				t.Errorf("TypeLabel() = %v, want %v", got, tt.typeLabel)
			}
		})
	}
}

func TestDomainX_MaxCalculations(t *testing.T) {
	d := &DomainX{
		SC: 3, // 3 digits for servers
		TC: 5, // 5 digits for terminals
		CC: 6, // 6 digits for serials
	}

	if got := d.MaxServers(); got != 999 {
		t.Errorf("MaxServers() = %v, want 999", got)
	}
	if got := d.MaxTerminals(); got != 99999 {
		t.Errorf("MaxTerminals() = %v, want 99999", got)
	}
	if got := d.MaxSerialPerMs(); got != 999999 {
		t.Errorf("MaxSerialPerMs() = %v, want 999999", got)
	}
}

func TestDomainX_IsActive(t *testing.T) {
	activeD := &DomainX{A: 1}
	if !activeD.IsActive() {
		t.Errorf("Active domain IsActive() = false, want true")
	}

	inactiveD := &DomainX{A: 0}
	if inactiveD.IsActive() {
		t.Errorf("Inactive domain IsActive() = true, want false")
	}
}

func TestDomainX_JSON(t *testing.T) {
	domain := &DomainX{
		I:   100,
		D:   1700000000000,
		E:   42,
		A:   1,
		N:   "Test Domain",
		C:   "test_domain",
		P:     50,
		IDXIS: []int{1, 2, 3},
		CDXIS: []int{4, 5, 6},
		SC:    3,
		TC:  3,
		RY:  -1,
		CC:  3,
	}

	data, err := json.Marshal(domain)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded DomainX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.I != domain.I || decoded.N != domain.N || decoded.C != domain.C {
		t.Errorf("JSON roundtrip failed")
	}
}
