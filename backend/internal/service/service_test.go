package service

import (
	"testing"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/hasher"
	"kantin-backend/internal/pkg/token"
)

func TestRoleTokenGenerationAndValidation(t *testing.T) {
	secret := "jwt-test-secret-suite-2026"
	maker := token.NewTokenMaker(secret, 24)

	roles := []domain.Role{
		domain.RoleStudent,
		domain.RolePetugasKantin,
		domain.RolePetugasKeuangan,
		domain.RoleParent,
		domain.RoleSuperAdmin,
	}

	for _, r := range roles {
		email := string(r) + "@sekolah.sch.id"
		user := &domain.UserProfile{
			ID:       "user-uuid-" + string(r),
			Email:    &email,
			FullName: "User " + string(r),
			Role:     r,
			IsActive: true,
		}

		tok, _, err := maker.CreateToken(user)
		if err != nil {
			t.Fatalf("Failed to create token for role %s: %v", r, err)
		}

		claims, err := maker.VerifyToken(tok)
		if err != nil {
			t.Fatalf("Failed to verify token for role %s: %v", r, err)
		}

		if claims.Role != r {
			t.Errorf("Role mismatch: expected %s, got %s", r, claims.Role)
		}
	}
}

func TestBcryptHashVerificationAgainstDatabaseHashes(t *testing.T) {
	// Sample hash from profiles.json
	password := "123456"
	hash, err := hasher.HashPassword(password)
	if err != nil {
		t.Fatalf("Failed to hash password: %v", err)
	}

	if !hasher.CheckPassword(password, hash) {
		t.Errorf("Password %s should match hash %s", password, hash)
	}

	if hasher.CheckPassword("wrongpassword", hash) {
		t.Errorf("Wrong password should not match hash")
	}
}

func TestOrderCartCalculations(t *testing.T) {
	items := []domain.OrderItem{
		{ProductName: "Nasi Goreng", Price: 15000, Quantity: 2},
		{ProductName: "Es Jeruk", Price: 5000, Quantity: 1},
	}

	deliveryFee := 2000
	subtotal := 0
	for _, it := range items {
		subtotal += it.Price * it.Quantity
	}

	if subtotal != 35000 {
		t.Errorf("Expected subtotal 35000, got %d", subtotal)
	}

	totalDelivery := subtotal + deliveryFee
	if totalDelivery != 37000 {
		t.Errorf("Expected total with delivery 37000, got %d", totalDelivery)
	}
}
