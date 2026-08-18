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

func TestStudentBlockedAccountWithActiveCard(t *testing.T) {
	rfid := "04:2A:B5:E2"
	student := Student{
		ID:       "std-001",
		Balance:  50000,
		RfidUID:  &rfid,
		IsActive: true, // Physical RFID card is ACTIVE
		Profile: &UserProfile{
			ID:       "std-001",
			FullName: "Budi Santoso",
			Role:     RoleStudent,
			IsActive: false, // Student digital account is BLOCKED
		},
	}

	// Verify that physical card is active even if account is blocked
	if !student.IsActive {
		t.Errorf("Expected student physical card to be active (IsActive == true)")
	}
	if student.Profile.IsActive {
		t.Errorf("Expected student profile account to be blocked (Profile.IsActive == false)")
	}

	// Verify JSON serialization maintains both fields
	bytes, err := json.Marshal(student)
	if err != nil {
		t.Fatalf("Failed to marshal student: %v", err)
	}

	var parsed Student
	if err := json.Unmarshal(bytes, &parsed); err != nil {
		t.Fatalf("Failed to unmarshal student: %v", err)
	}

	if !parsed.IsActive {
		t.Errorf("Parsed student card should remain active")
	}
	if parsed.Profile.IsActive {
		t.Errorf("Parsed student profile should remain inactive/blocked")
	}
}
