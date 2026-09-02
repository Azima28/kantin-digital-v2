package middleware

import (
	"context"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/token"
)

func TestAuthMiddleware(t *testing.T) {
	secret := "test-secret-middleware-key-12345"
	maker := token.NewTokenMaker(secret, 1)

	app := fiber.New()
	app.Use("/protected", AuthMiddleware(maker, nil, nil))
	app.Get("/protected", func(c *fiber.Ctx) error {
		return c.SendString("access granted")
	})

	// 1. Missing Authorization Header -> 401
	req1 := httptest.NewRequest("GET", "/protected", nil)
	resp1, _ := app.Test(req1)
	if resp1.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("Expected 401 for missing token, got %d", resp1.StatusCode)
	}

	// 2. Valid Token -> 200
	user := &domain.UserProfile{
		ID:       "user-001",
		FullName: "Ahmad",
		Role:     domain.RoleStudent,
	}
	tok, _, _ := maker.CreateToken(user)

	req2 := httptest.NewRequest("GET", "/protected", nil)
	req2.Header.Set("Authorization", "Bearer "+tok)
	resp2, _ := app.Test(req2)
	if resp2.StatusCode != fiber.StatusOK {
		t.Errorf("Expected 200 for valid token, got %d", resp2.StatusCode)
	}
}

// TestSessionIsDead pins the revocation truth table. Both directions matter: a
// false negative keeps a logged-out or password-changed session alive, and a
// false positive logs out every user who never had a watermark set.
func TestSessionIsDead(t *testing.T) {
	base := time.Date(2026, 9, 2, 10, 0, 0, 0, time.UTC)

	cases := []struct {
		name      string
		revoked   bool
		notBefore time.Time
		issuedAt  time.Time
		want      bool
	}{
		{
			name:     "sesi normal tanpa watermark tetap hidup",
			issuedAt: base,
			want:     false,
		},
		{
			name:    "jti masuk daftar cabut (logout) selalu mati",
			revoked: true,
			// No watermark and a token issued far in the future: the blacklist
			// alone must be enough.
			issuedAt: base.Add(24 * time.Hour),
			want:     true,
		},
		{
			name:      "token diterbitkan sebelum watermark ikut mati",
			notBefore: base,
			issuedAt:  base.Add(-time.Second),
			want:      true,
		},
		{
			name:      "token diterbitkan tepat pada watermark tetap hidup",
			notBefore: base,
			issuedAt:  base,
			want:      false,
		},
		{
			name:      "token diterbitkan setelah watermark tetap hidup",
			notBefore: base,
			issuedAt:  base.Add(time.Second),
			want:      false,
		},
		{
			name:      "token lama tanpa iat ikut mati saat ada watermark",
			notBefore: base,
			want:      true,
		},
		{
			name: "token lama tanpa iat dan tanpa watermark tetap hidup",
			want: false,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := sessionIsDead(tc.revoked, tc.notBefore, tc.issuedAt); got != tc.want {
				t.Fatalf("sessionIsDead(%v, %v, %v) = %v, mau %v", tc.revoked, tc.notBefore, tc.issuedAt, got, tc.want)
			}
		})
	}
}

// SessionAlive must not invent a revocation when there is nothing to check it
// against. Both the HTTP middleware and the WebSocket upgrade call it on every
// authenticated request, so a nil store or a token carrying no user id has to
// come back alive -- otherwise wiring the app without a session repository would
// silently reject every logged-in user instead of merely skipping the check.
func TestSessionAliveWithNothingToCheck(t *testing.T) {
	if !SessionAlive(context.Background(), nil, &token.JWTClaims{UserID: "user-1"}) {
		t.Fatal("sessionRepo nil harus dianggap sesi hidup")
	}
	if !SessionAlive(context.Background(), nil, nil) {
		t.Fatal("claims nil harus dianggap sesi hidup")
	}
	if !SessionAlive(context.Background(), nil, &token.JWTClaims{}) {
		t.Fatal("token tanpa user id harus dianggap sesi hidup")
	}
}
