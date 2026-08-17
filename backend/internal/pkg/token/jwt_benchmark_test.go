package token

import (
	"testing"

	"kantin-backend/internal/domain"
)

// BenchmarkJWTTokenCreation measures token signing throughput
func BenchmarkJWTTokenCreation(b *testing.B) {
	secret := "super-secure-benchmark-secret-key-2026"
	maker := NewTokenMaker(secret, 24)

	email := "student@sekolah.sch.id"
	user := &domain.UserProfile{
		ID:       "user-uuid-12345",
		Email:    &email,
		FullName: "Ahmad Subarjo",
		Role:     domain.RoleStudent,
	}

	b.ResetTimer()
	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		_, _, err := maker.CreateToken(user)
		if err != nil {
			b.Fatalf("Failed to create token: %v", err)
		}
	}
}

// BenchmarkJWTTokenVerification measures token parsing & claims verification latency
func BenchmarkJWTTokenVerification(b *testing.B) {
	secret := "super-secure-benchmark-secret-key-2026"
	maker := NewTokenMaker(secret, 24)

	email := "student@sekolah.sch.id"
	user := &domain.UserProfile{
		ID:       "user-uuid-12345",
		Email:    &email,
		FullName: "Ahmad Subarjo",
		Role:     domain.RoleStudent,
	}

	tok, _, err := maker.CreateToken(user)
	if err != nil {
		b.Fatalf("Failed to create token: %v", err)
	}

	b.ResetTimer()
	b.ReportAllocs()

	for i := 0; i < b.N; i++ {
		claims, err := maker.VerifyToken(tok)
		if err != nil || claims.UserID != user.ID {
			b.Fatalf("Verification failed: %v", err)
		}
	}
}
