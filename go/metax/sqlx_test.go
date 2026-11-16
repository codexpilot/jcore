package metax

import (
	"encoding/json"
	"testing"
)

func TestSqlX_JSON(t *testing.T) {
	sqlx := &SqlX{
		ID:  1001,
		DI:  intPtr(100),
		Q:   intPtr(500),
		N:   strPtr("Get User SQL"),
		C:   strPtr("get_user_pg"),
		DBT: intPtr(1),
		S:   strPtr("SELECT * FROM users WHERE id = $1"),
	}

	data, err := json.Marshal(sqlx)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded SqlX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.ID != sqlx.ID || *decoded.Q != *sqlx.Q {
		t.Errorf("JSON roundtrip failed")
	}
}
