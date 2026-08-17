package domain

import (
	"encoding/json"
	"testing"
)

func TestProductJSONSerialization(t *testing.T) {
	p := Product{
		ID:                  "p-01",
		OperatorID:          "op-01",
		Name:                "Nasi Goreng Spesial",
		Price:               15000,
		Category:            "makanan",
		IsAvailable:         true,
		CustomizableOptions: []string{"Pedas Level 1", "Telur Dadar"},
	}

	bytes, err := json.Marshal(p)
	if err != nil {
		t.Fatalf("Failed to marshal product: %v", err)
	}

	var parsed Product
	if err := json.Unmarshal(bytes, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal product: %v", err)
	}

	if parsed.Name != p.Name {
		t.Errorf("Expected Name %s, got %s", p.Name, parsed.Name)
	}
	if len(parsed.CustomizableOptions) != 2 {
		t.Errorf("Expected 2 customizable options, got %d", len(parsed.CustomizableOptions))
	}
}

func TestOrderLifecycleConstants(t *testing.T) {
	statuses := []OrderStatus{
		OrderStatusBaru,
		OrderStatusSedangDimasak,
		OrderStatusSiapDiambil,
		OrderStatusSiapDiantar,
		OrderStatusSelesai,
		OrderStatusDibatalkan,
	}

	if len(statuses) != 6 {
		t.Errorf("Expected 6 main statuses, got %d", len(statuses))
	}
}
