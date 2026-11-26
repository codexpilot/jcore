package metax

import "testing"

func TestModelRegistry(t *testing.T) {
	registry := NewModelRegistry()

	// Create test models
	model1 := &ModelX{
		ID: 1,
		N:  stringPtr("Customer"),
		C:  stringPtr("CUST"),
	}
	model2 := &ModelX{
		ID: 2,
		N:  stringPtr("Order"),
		C:  stringPtr("ORDER"),
	}
	model3 := &ModelX{
		ID: 3,
		N:  stringPtr("Customer"), // Duplicate name
		C:  stringPtr("CUST2"),
	}

	// Add models
	if err := registry.Add(model1); err != nil {
		t.Fatalf("Failed to add model1: %v", err)
	}
	if err := registry.Add(model2); err != nil {
		t.Fatalf("Failed to add model2: %v", err)
	}
	if err := registry.Add(model3); err != nil {
		t.Fatalf("Failed to add model3: %v", err)
	}

	// Test ByID
	if m := registry.ByID(1); m != model1 {
		t.Errorf("ByID(1) failed")
	}

	// Test ByCode
	if m := registry.ByCode("ORDER"); m != model2 {
		t.Errorf("ByCode(ORDER) failed")
	}

	// Test ByName with unique name
	if m, err := registry.ByName("Order"); err != nil || m != model2 {
		t.Errorf("ByName(Order) failed: %v", err)
	}

	// Test ByName with ambiguous name
	if _, err := registry.ByName("Customer"); err == nil {
		t.Error("ByName(Customer) should return ambiguity error")
	}

	// Test duplicate ID
	duplicate := &ModelX{ID: 1, C: stringPtr("DUP")}
	if err := registry.Add(duplicate); err == nil {
		t.Error("Should reject duplicate ID")
	}

	// Test duplicate code
	duplicateCode := &ModelX{ID: 10, C: stringPtr("CUST")}
	if err := registry.Add(duplicateCode); err == nil {
		t.Error("Should reject duplicate code")
	}
}

func TestDBContext(t *testing.T) {
	ctx := NewDBContext()

	// Create test model
	model := &ModelX{
		ID: 100,
		C:  stringPtr("TEST"),
	}

	// Create test schema
	schema := &Schema{
		ModelID: 100,
		Fields: []Field{
			{ID: 1, Code: "id", Name: "id", TypeID: 300007, TypeName: "Integer"},
			{ID: 2, Code: "name", Name: "name", TypeID: 300011, TypeName: "String"},
		},
	}

	schemas := map[int]*Schema{100: schema}

	// Test activation
	if err := ctx.Activate([]*ModelX{model}, schemas); err != nil {
		t.Fatalf("Activation failed: %v", err)
	}

	// Verify model is active
	if m := ctx.Models.ByID(100); m == nil {
		t.Error("Model not found after activation")
	}

	// Verify schema is active
	if s := ctx.Schemas.ByModelID(100); s == nil {
		t.Error("Schema not found after activation")
	}

	// Test missing schema error
	model2 := &ModelX{ID: 200, C: stringPtr("NOSCHEMA")}
	if err := ctx.Activate([]*ModelX{model2}, schemas); err == nil {
		t.Error("Should reject model without schema")
	}

	// Test clear
	ctx.Clear()
	if ctx.Models.ByID(100) != nil {
		t.Error("Model still present after clear")
	}
}

func TestRow(t *testing.T) {
	schema := &Schema{
		Fields: []Field{
			{ID: 1, Code: "id", Name: "id", TypeID: 300007, TypeName: "Integer"},
			{ID: 2, Code: "name", Name: "name", TypeID: 300011, TypeName: "String"},
			{ID: 3, Code: "amount", Name: "amount", TypeID: 300013, TypeName: "Numeric"},
		},
	}

	cells := []interface{}{123, "Test", "456.78"}

	row, err := NewRow(schema, cells)
	if err != nil {
		t.Fatalf("Failed to create row: %v", err)
	}

	// Test index access
	val, err := row.Get(0)
	if err != nil || val != 123 {
		t.Errorf("Index access failed: %v", err)
	}

	// Test name access
	val, err = row.Get("name")
	if err != nil || val != "Test" {
		t.Errorf("Name access failed: %v", err)
	}

	// Test GetString
	name, err := row.GetString("name")
	if err != nil || name != "Test" {
		t.Errorf("GetString failed: %v", err)
	}

	// Test GetNumeric
	amount, err := row.GetNumeric("amount")
	if err != nil || amount != "456.78" {
		t.Errorf("GetNumeric failed: %v", err)
	}

	// Test invalid field name
	if _, err := row.Get("invalid"); err == nil {
		t.Error("Should error on invalid field name")
	}

	// Test cell count mismatch
	if _, err := NewRow(schema, []interface{}{1, 2}); err == nil {
		t.Error("Should reject mismatched cell count")
	}
}

func TestComposedRow(t *testing.T) {
	// Create header schema and row
	headerSchema := &Schema{
		Fields: []Field{
			{ID: 1, Code: "invoice_id", Name: "invoice_id", TypeID: 300007, TypeName: "Integer"},
			{ID: 2, Code: "total", Name: "total", TypeID: 300013, TypeName: "Numeric"},
		},
	}
	headerRow, _ := NewRow(headerSchema, []interface{}{1, "1250.50"})

	// Create line item schema and rows
	lineSchema := &Schema{
		Fields: []Field{
			{ID: 10, Code: "line_id", Name: "line_id", TypeID: 300007, TypeName: "Integer"},
			{ID: 11, Code: "product", Name: "product", TypeID: 300011, TypeName: "String"},
		},
	}
	line1, _ := NewRow(lineSchema, []interface{}{1, "Widget"})
	line2, _ := NewRow(lineSchema, []interface{}{2, "Gadget"})

	// Create composed row
	composed := &ComposedRow{
		Row: headerRow,
		Sections: map[string]Section{
			"info":  &OneSection{Row: headerRow},
			"items": &ManySection{Rows: []*Row{line1, line2}},
		},
	}

	// Test GetOne
	info, err := composed.GetOne("info")
	if err != nil || info == nil {
		t.Errorf("GetOne failed: %v", err)
	}

	// Test GetMany
	items, err := composed.GetMany("items")
	if err != nil || len(items) != 2 {
		t.Errorf("GetMany failed: %v", err)
	}

	// Test invalid section
	if _, err := composed.GetOne("invalid"); err == nil {
		t.Error("Should error on invalid section")
	}

	// Test wrong section type
	if _, err := composed.GetOne("items"); err == nil {
		t.Error("Should error when requesting one section as many")
	}
}

func TestModelXComposedFields(t *testing.T) {
	// Test non-composed model
	model1 := &ModelX{
		ID:   1,
		MXIS: []int{},
	}
	if model1.IsComposed() {
		t.Error("Empty mxis should not be composed")
	}

	// Test composed model
	mtx := 370000
	model2 := &ModelX{
		ID:   2,
		MTX:  &mtx,
		MXIS: []int{10, 20, 30},
	}
	if !model2.IsComposed() {
		t.Error("Model with mxis should be composed")
	}
	if !model2.IsComposed() {
		t.Error("Model with mtx=370000 should be composed type")
	}
}

func stringPtr(s string) *string {
	return &s
}
