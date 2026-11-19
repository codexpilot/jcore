package metax

import (
	"encoding/json"
	"testing"
)

func TestParamX_JSON(t *testing.T) {
	param := &ParamX{
		I:   1001,
		D:   1700000000000,
		E:   42,
		A:   1,
		DXI: 100,
		QXI: 500,
		N:   "User ID",
		C:   "user_id",
		DTX: 300004,
		Req: true,
		FP:  0,
	}

	data, err := json.Marshal(param)
	if err != nil {
		t.Fatalf("Marshal failed: %v", err)
	}

	var decoded ParamX
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Unmarshal failed: %v", err)
	}

	if decoded.I != param.I || decoded.N != param.N || decoded.Req != param.Req {
		t.Errorf("JSON roundtrip failed: got %+v, want %+v", decoded, param)
	}
}

func TestParamX_String(t *testing.T) {
	param := &ParamX{
		I:   1001,
		N:   "User ID",
		C:   "user_id",
		Req: true,
	}

	str := param.String()
	if str == "" {
		t.Error("String() should not be empty")
	}
}
