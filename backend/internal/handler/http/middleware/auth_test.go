package middleware

import (
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/token"
)

func TestAuthMiddleware(t *testing.T) {
	secret := "test-secret-middleware-key-12345"
	maker := token.NewTokenMaker(secret, 1)

	app := fiber.New()
	app.Use("/protected", AuthMiddleware(maker))
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
