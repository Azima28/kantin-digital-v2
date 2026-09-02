package token

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
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

// TestCreateTokenAlwaysCarriesSessionID guards the precondition for revocation:
// a token with no jti cannot be blacklisted individually.
func TestCreateTokenAlwaysCarriesSessionID(t *testing.T) {
	maker := NewTokenMaker("test-secret-key-12345-very-long", 2)
	user := &domain.UserProfile{ID: "11111111-2222-3333-4444-555555555555", FullName: "Ahmad Siswa", Role: domain.RoleStudent}

	seen := make(map[string]bool)
	for i := 0; i < 25; i++ {
		tokenStr, _, err := maker.CreateToken(user)
		if err != nil {
			t.Fatalf("CreateToken gagal: %v", err)
		}
		claims, err := maker.VerifyToken(tokenStr)
		if err != nil {
			t.Fatalf("VerifyToken gagal: %v", err)
		}
		if claims.ID == "" {
			t.Fatalf("jti kosong: sesi ini tidak bisa dicabut saat logout")
		}
		if seen[claims.ID] {
			t.Fatalf("jti terulang (%s): logout satu sesi akan mencabut sesi lain", claims.ID)
		}
		seen[claims.ID] = true
		if claims.IssuedAt == nil {
			t.Fatalf("iat kosong: pencabutan massal per pengguna tidak bisa membandingkan watermark")
		}
	}
}

// TestRenewTokenPreservesRevocationHandles is the regression test for the
// renewal chain. The auth middleware renews silently on every request, so if a
// renewal minted a fresh jti the session would rename itself past its own
// logout, and if it refreshed iat it would slip past a password change.
func TestRenewTokenPreservesRevocationHandles(t *testing.T) {
	maker := NewTokenMaker("test-secret-key-12345-very-long", 2)
	user := &domain.UserProfile{ID: "11111111-2222-3333-4444-555555555555", FullName: "Ahmad Siswa", Role: domain.RoleStudent}

	originalStr, _, err := maker.CreateToken(user)
	if err != nil {
		t.Fatalf("CreateToken gagal: %v", err)
	}
	original, err := maker.VerifyToken(originalStr)
	if err != nil {
		t.Fatalf("VerifyToken gagal: %v", err)
	}

	// Three renewals in a row: the handles must survive the whole chain, not
	// just the first hop.
	claims := original
	for i := 1; i <= 3; i++ {
		renewedStr, expiresAt, err := maker.RenewToken(claims)
		if err != nil {
			t.Fatalf("RenewToken #%d gagal: %v", i, err)
		}
		if !expiresAt.After(time.Now()) {
			t.Fatalf("RenewToken #%d menghasilkan token yang sudah kadaluarsa", i)
		}
		renewed, err := maker.VerifyToken(renewedStr)
		if err != nil {
			t.Fatalf("VerifyToken pada hasil RenewToken #%d gagal: %v", i, err)
		}
		if renewed.ID != original.ID {
			t.Fatalf("renewal #%d mengganti jti (%s -> %s): sesi bisa lolos dari logout", i, original.ID, renewed.ID)
		}
		if renewed.IssuedAt.Unix() != original.IssuedAt.Unix() {
			t.Fatalf("renewal #%d menyegarkan iat (%d -> %d): sesi bisa lolos dari ganti kata sandi", i, original.IssuedAt.Unix(), renewed.IssuedAt.Unix())
		}
		if renewed.UserID != original.UserID || renewed.Role != original.Role {
			t.Fatalf("renewal #%d mengubah identitas pemilik token", i)
		}
		claims = renewed
	}
}

// TestRenewTokenBackfillsLegacySessionID covers tokens minted before jti
// existed. They have no id to blacklist, so renewal must mint one -- the
// not_before watermark is what covers them until they next renew.
func TestRenewTokenBackfillsLegacySessionID(t *testing.T) {
	maker := NewTokenMaker("test-secret-key-12345-very-long", 2)
	staleIssuedAt := time.Now().Add(-90 * time.Minute)

	legacy := &JWTClaims{
		UserID:   "11111111-2222-3333-4444-555555555555",
		FullName: "Ahmad Siswa",
		Role:     domain.RoleStudent,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * time.Minute)),
			IssuedAt:  jwt.NewNumericDate(staleIssuedAt),
			Subject:   "11111111-2222-3333-4444-555555555555",
		},
	}

	renewedStr, _, err := maker.RenewToken(legacy)
	if err != nil {
		t.Fatalf("RenewToken gagal: %v", err)
	}
	renewed, err := maker.VerifyToken(renewedStr)
	if err != nil {
		t.Fatalf("VerifyToken gagal: %v", err)
	}
	if renewed.ID == "" {
		t.Fatalf("jti tetap kosong setelah renewal: sesi lama tidak akan pernah bisa dicabut per token")
	}
	if renewed.IssuedAt.Unix() != staleIssuedAt.Unix() {
		t.Fatalf("iat lama tidak dipertahankan (%d != %d): watermark pencabutan massal jadi tidak berlaku", renewed.IssuedAt.Unix(), staleIssuedAt.Unix())
	}
}
