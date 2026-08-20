package main

import (
	"encoding/json"
	"io"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/config"
	"kantin-backend/internal/domain"
	httpHandler "kantin-backend/internal/handler/http"
	"kantin-backend/internal/handler/http/middleware"
	wsHandler "kantin-backend/internal/handler/websocket"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

func setupTestApp() *fiber.App {
	cfg := config.LoadConfig()
	tokenMaker := token.NewTokenMaker(cfg.JWTSecret, cfg.JWTExpiryHours)
	hub := wsHandler.NewHub()
	go hub.Run()

	// Mock or nil DB for endpoint routing tests
	userRepo := postgres.NewUserRepo(&postgres.DB{})
	productRepo := postgres.NewProductRepo(&postgres.DB{})
	orderRepo := postgres.NewOrderRepo(&postgres.DB{})
	txRepo := postgres.NewTransactionRepo(&postgres.DB{})
	notifRepo := postgres.NewNotificationRepo(&postgres.DB{})
	auditRepo := postgres.NewAuditRepo(&postgres.DB{})
	shiftRepo := postgres.NewShiftRepo(&postgres.DB{})

	authService := service.NewAuthService(userRepo, tokenMaker)
	catalogService := service.NewCatalogService(productRepo, userRepo)
	orderService := service.NewOrderService(orderRepo)
	paymentService := service.NewPaymentService(txRepo, userRepo, auditRepo, productRepo, shiftRepo)
	notifService := service.NewNotificationService(notifRepo)

	authH := httpHandler.NewAuthHandler(authService)
	catalogH := httpHandler.NewCatalogHandler(catalogService)
	orderH := httpHandler.NewOrderHandler(orderService, hub)
	posH := httpHandler.NewPOSHandler(paymentService)
	studentH := httpHandler.NewStudentHandler(paymentService, notifService)
	financeH := httpHandler.NewFinanceHandler(paymentService)
	uploadH := httpHandler.NewUploadHandler(cfg.UploadDir, &postgres.DB{})

	app := fiber.New()

	app.Get("/health", func(c *fiber.Ctx) error {
		return response.Success(c, fiber.StatusOK, "Healthy", map[string]string{
			"status": "healthy",
		})
	})

	api := app.Group("/api/v1")
	api.Post("/auth/login", authH.Login)
	api.Get("/canteens", catalogH.ListCanteens)
	api.Get("/products", catalogH.ListProducts)

	authRequired := api.Group("/", middleware.AuthMiddleware(tokenMaker))
	authRequired.Get("/auth/me", authH.Me)
	authRequired.Post("/upload/product-image", uploadH.UploadProductImage)

	studentGroup := authRequired.Group("/student", middleware.RequireRoles(domain.RoleStudent))
	studentGroup.Get("/me", studentH.GetMyProfile)

	posGroup := authRequired.Group("/pos", middleware.RequireRoles(domain.RolePetugasKantin))
	posGroup.Get("/scan-card", posH.ScanCard)

	financeGroup := authRequired.Group("/finance", middleware.RequireRoles(domain.RolePetugasKeuangan))
	financeGroup.Post("/topup", financeH.Topup)

	authRequired.Post("/orders", orderH.CreateOrder)

	return app
}

func TestHealthCheckEndpoint(t *testing.T) {
	app := setupTestApp()

	req := httptest.NewRequest("GET", "/health", nil)
	resp, err := app.Test(req)
	if err != nil {
		t.Fatalf("Failed to execute health check request: %v", err)
	}

	if resp.StatusCode != fiber.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	body, _ := io.ReadAll(resp.Body)
	var res response.Response
	if err := json.Unmarshal(body, &res); err != nil {
		t.Fatalf("Failed to parse JSON response: %v", err)
	}

	if !res.Success {
		t.Errorf("Expected success true, got false")
	}
}

func TestAuthProtectedRoutesRejection(t *testing.T) {
	app := setupTestApp()

	// 1. /api/v1/auth/me without token -> 401
	req1 := httptest.NewRequest("GET", "/api/v1/auth/me", nil)
	resp1, _ := app.Test(req1)
	if resp1.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized for /api/v1/auth/me, got %d", resp1.StatusCode)
	}

	// 2. /api/v1/student/me without token -> 401
	req2 := httptest.NewRequest("GET", "/api/v1/student/me", nil)
	resp2, _ := app.Test(req2)
	if resp2.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized for /api/v1/student/me, got %d", resp2.StatusCode)
	}

	// 3. /api/v1/pos/scan-card without token -> 401
	req3 := httptest.NewRequest("GET", "/api/v1/pos/scan-card", nil)
	resp3, _ := app.Test(req3)
	if resp3.StatusCode != fiber.StatusUnauthorized {
		t.Errorf("Expected 401 Unauthorized for /api/v1/pos/scan-card, got %d", resp3.StatusCode)
	}
}
