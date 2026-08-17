package hasher

import (
	"testing"
)

func TestHashPassword(t *testing.T) {
	password := "Secret123!"
	hash, err := HashPassword(password)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	if len(hash) == 0 {
		t.Fatalf("Expected non-empty hash string")
	}

	if hash == password {
		t.Fatalf("Hash should not be equal to plain password")
	}

	// Test valid comparison
	if !CheckPassword(password, hash) {
		t.Fatalf("Expected password check to return true for correct password")
	}

	// Test invalid password comparison
	if CheckPassword("WrongPassword", hash) {
		t.Fatalf("Expected password check to return false for incorrect password")
	}
}
