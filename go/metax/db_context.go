package metax

import (
	"encoding/json"
	"fmt"
	"sort"
)

// ModelRegistry provides lookup by ID, name, and code
type ModelRegistry struct {
	byID   map[int]*ModelX
	byName map[string][]*ModelX
	byCode map[string]*ModelX
}

// NewModelRegistry creates an empty registry
func NewModelRegistry() *ModelRegistry {
	return &ModelRegistry{
		byID:   make(map[int]*ModelX),
		byName: make(map[string][]*ModelX),
		byCode: make(map[string]*ModelX),
	}
}

// Add validates and adds a model to the registry
func (r *ModelRegistry) Add(model *ModelX) error {
	if model == nil {
		return fmt.Errorf("model is nil")
	}

	// Check duplicate ID
	if _, exists := r.byID[model.ID]; exists {
		return fmt.Errorf("duplicate model ID: %d", model.ID)
	}

	// Check duplicate code
	if model.C != nil {
		if _, exists := r.byCode[*model.C]; exists {
			return fmt.Errorf("duplicate model code: %s (IDs %d, %d)",
				*model.C, r.byCode[*model.C].ID, model.ID)
		}
	}

	// Add to registries
	r.byID[model.ID] = model

	if model.N != nil {
		r.byName[*model.N] = append(r.byName[*model.N], model)
	}

	if model.C != nil {
		r.byCode[*model.C] = model
	}

	return nil
}

// ByID looks up model by ID
func (r *ModelRegistry) ByID(id int) *ModelX {
	return r.byID[id]
}

// ByName looks up model by name (returns error if ambiguous)
func (r *ModelRegistry) ByName(name string) (*ModelX, error) {
	models := r.byName[name]
	if len(models) == 0 {
		return nil, nil
	}
	if len(models) > 1 {
		ids := make([]int, len(models))
		for i, m := range models {
			ids[i] = m.ID
		}
		return nil, fmt.Errorf("ambiguous model name %q: matches %d models (IDs: %v)",
			name, len(models), ids)
	}
	return models[0], nil
}

// ByCode looks up model by code
func (r *ModelRegistry) ByCode(code string) *ModelX {
	return r.byCode[code]
}

// IDs returns all active model IDs (sorted)
func (r *ModelRegistry) IDs() []int {
	ids := make([]int, 0, len(r.byID))
	for id := range r.byID {
		ids = append(ids, id)
	}
	sort.Ints(ids)
	return ids
}

// Contains checks if a model ID is active
func (r *ModelRegistry) Contains(id int) bool {
	_, exists := r.byID[id]
	return exists
}

// Clear removes all models
func (r *ModelRegistry) Clear() {
	r.byID = make(map[int]*ModelX)
	r.byName = make(map[string][]*ModelX)
	r.byCode = make(map[string]*ModelX)
}

// SchemaRegistry provides lookup by model ID
type SchemaRegistry struct {
	schemas map[int]*Schema
}

// Schema represents a JX schema for a model
type Schema struct {
	ModelID int
	Fields  []Field
}

// Field represents a schema field
type Field struct {
	ID       int    `json:"i"`
	Code     string `json:"c"`
	Name     string `json:"n"`
	TypeID   int    `json:"typeId"`
	TypeCode string `json:"typeCode,omitempty"`
	TypeName string `json:"typeName"`
}

// NewSchemaRegistry creates an empty schema registry
func NewSchemaRegistry() *SchemaRegistry {
	return &SchemaRegistry{
		schemas: make(map[int]*Schema),
	}
}

// Add adds a schema for a model ID
func (r *SchemaRegistry) Add(modelID int, schema *Schema) error {
	if schema == nil {
		return fmt.Errorf("schema is nil")
	}
	if _, exists := r.schemas[modelID]; exists {
		return fmt.Errorf("schema already exists for model ID: %d", modelID)
	}
	r.schemas[modelID] = schema
	return nil
}

// ByModelID looks up schema by model ID
func (r *SchemaRegistry) ByModelID(modelID int) *Schema {
	return r.schemas[modelID]
}

// Contains checks if a schema exists for a model ID
func (r *SchemaRegistry) Contains(modelID int) bool {
	_, exists := r.schemas[modelID]
	return exists
}

// Clear removes all schemas
func (r *SchemaRegistry) Clear() {
	r.schemas = make(map[int]*Schema)
}

// DBContext manages model and schema registries
type DBContext struct {
	Models  *ModelRegistry
	Schemas *SchemaRegistry
}

// NewDBContext creates a new database context
func NewDBContext() *DBContext {
	return &DBContext{
		Models:  NewModelRegistry(),
		Schemas: NewSchemaRegistry(),
	}
}

// Activate validates and activates models and schemas together
func (ctx *DBContext) Activate(models []*ModelX, schemas map[int]*Schema) error {
	// Create new registries
	newModels := NewModelRegistry()
	newSchemas := NewSchemaRegistry()

	// Add all models
	for _, model := range models {
		if err := newModels.Add(model); err != nil {
			return err
		}

		// Validate schema exists
		schema, exists := schemas[model.ID]
		if !exists {
			code := "unknown"
			if model.C != nil {
				code = *model.C
			}
			return fmt.Errorf("missing schema for model %d (%s)", model.ID, code)
		}

		// Add schema
		if err := newSchemas.Add(model.ID, schema); err != nil {
			return err
		}
	}

	// Atomically replace
	ctx.Models = newModels
	ctx.Schemas = newSchemas

	return nil
}

// Clear removes all registries
func (ctx *DBContext) Clear() {
	ctx.Models.Clear()
	ctx.Schemas.Clear()
}

// Row represents a data row with both index and name access
type Row struct {
	Schema    *Schema
	Cells     []interface{}
	nameIndex map[string]int
}

// NewRow creates a row with validation
func NewRow(schema *Schema, cells []interface{}) (*Row, error) {
	if len(cells) != len(schema.Fields) {
		return nil, fmt.Errorf("cell count %d does not match schema field count %d",
			len(cells), len(schema.Fields))
	}

	nameIndex := make(map[string]int)
	for i, field := range schema.Fields {
		nameIndex[field.Name] = i
	}

	return &Row{
		Schema:    schema,
		Cells:     cells,
		nameIndex: nameIndex,
	}, nil
}

// Get retrieves value by index or name
func (r *Row) Get(key interface{}) (interface{}, error) {
	switch k := key.(type) {
	case int:
		if k < 0 || k >= len(r.Cells) {
			return nil, fmt.Errorf("index %d out of range", k)
		}
		return r.Cells[k], nil
	case string:
		idx, exists := r.nameIndex[k]
		if !exists {
			return nil, fmt.Errorf("field name not found: %s", k)
		}
		return r.Cells[idx], nil
	default:
		return nil, fmt.Errorf("key must be int or string, got %T", key)
	}
}

// GetString retrieves a string value by field name
func (r *Row) GetString(fieldName string) (string, error) {
	val, err := r.Get(fieldName)
	if err != nil {
		return "", err
	}
	if val == nil {
		return "", nil
	}
	s, ok := val.(string)
	if !ok {
		return "", fmt.Errorf("field %s is not a string", fieldName)
	}
	return s, nil
}

// GetInt64 retrieves an int64 value by field name (exact INT64)
func (r *Row) GetInt64(fieldName string) (int64, error) {
	val, err := r.Get(fieldName)
	if err != nil {
		return 0, err
	}
	if val == nil {
		return 0, nil
	}

	// Handle both int64 and float64 from JSON
	switch v := val.(type) {
	case int64:
		return v, nil
	case float64:
		return int64(v), nil
	case json.Number:
		return v.Int64()
	default:
		return 0, fmt.Errorf("field %s is not an int64", fieldName)
	}
}

// GetNumeric retrieves exact numeric value as string
func (r *Row) GetNumeric(fieldName string) (string, error) {
	val, err := r.Get(fieldName)
	if err != nil {
		return "", err
	}
	if val == nil {
		return "", nil
	}

	// Exact numeric values are preserved as strings
	s, ok := val.(string)
	if !ok {
		return "", fmt.Errorf("field %s is not a numeric string", fieldName)
	}
	return s, nil
}

// ToMap converts row to map
func (r *Row) ToMap() map[string]interface{} {
	result := make(map[string]interface{})
	for i, field := range r.Schema.Fields {
		result[field.Name] = r.Cells[i]
	}
	return result
}

// ComposedRow represents a row with named sections
type ComposedRow struct {
	*Row
	Sections map[string]Section
}

// Section represents a one or many section
type Section interface {
	IsOne() bool
	IsMany() bool
}

// OneSection contains a single child row or nil
type OneSection struct {
	Row *Row
}

func (s *OneSection) IsOne() bool  { return true }
func (s *OneSection) IsMany() bool { return false }

// ManySection contains a list of child rows
type ManySection struct {
	Rows []*Row
}

func (s *ManySection) IsOne() bool  { return false }
func (s *ManySection) IsMany() bool { return true }

// GetOne retrieves a one section
func (r *ComposedRow) GetOne(sectionKey string) (*Row, error) {
	section, exists := r.Sections[sectionKey]
	if !exists {
		return nil, fmt.Errorf("section %q not found", sectionKey)
	}
	one, ok := section.(*OneSection)
	if !ok {
		return nil, fmt.Errorf("section %q is not a one section", sectionKey)
	}
	return one.Row, nil
}

// GetMany retrieves a many section
func (r *ComposedRow) GetMany(sectionKey string) ([]*Row, error) {
	section, exists := r.Sections[sectionKey]
	if !exists {
		return nil, fmt.Errorf("section %q not found", sectionKey)
	}
	many, ok := section.(*ManySection)
	if !ok {
		return nil, fmt.Errorf("section %q is not a many section", sectionKey)
	}
	return many.Rows, nil
}
