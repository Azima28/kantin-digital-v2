package token

import (
	"testing"
	"time"

	"kantin-backend/internal/domain"
)

func TestTokenMaker(t *testing.T) {
	secret := "test-secret-key-12345-very-long"
	maker := NewTokenMaker(secret, 2)

	email := "student@sekolah.sch.id"
	user := &domain.UserProfile{
		ID:       "11111111-2222-3333-4444-555555555555",
		Email:    &email,
		FullName: "Ahmad Siswa",
		Role:     domain.RoleStudent,
	}

	// 1. Create Token
	tokenStr, expiresAt, err := maker.CreateToken(user)
	if err != nil {
		t.Fatalf("Failed to create token: %v", err)
	}

	if len(tokenStr) == 0 {
		t.Fatalf("Token string is empty")
	}

	if expiresAt.Before(time.Now()) {
		t.Fatalf("Expiry date should be in the future")
	}

	// 2. Verify Valid Token
	claims, err := maker.VerifyToken(tokenStr)
	if err != nil {
		t.Fatalf("Failed to verify token: %v", err)
	}

	if claims.UserID != user.ID {
		t.Errorf("Expected UserID %s, got %s", user.ID, claims.UserID)
	}
	if claims.Email != email {
		t.Errorf("Expected Email %s, got %s", email, claims.Email)
	}
	if claims.FullName != user.FullName {
		t.Errorf("Expected FullName %s, got %s", user.FullName, claims.FullName)
	}
	if claims.Role != domain.RoleStudent {
		t.Errorf("Expected Role %s, got %s", domain.RoleStudent, claims.Role)
	}

	// 3. Verify Invalid / Tampered Token
	tamperedToken := tokenStr + "invalid"
	_, err = maker.VerifyToken(tamperedToken)
	if err == nil {
		t.Errorf("Expected error for tampered token, got nil")
	}

	// 4. Verify Token with wrong secret
	otherMaker := NewTokenMaker("different-secret-key", 2)
	_, err = otherMaker.VerifyToken(tokenStr)
	if err == nil {
		t.Errorf("Expected error when verifying with wrong secret key, got nil")
	}
}
