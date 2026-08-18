package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/websocket/v2"

	"kantin-backend/config"
	"kantin-backend/internal/domain"
	httpHandler "kantin-backend/internal/handler/http"
	"kantin-backend/internal/handler/http/middleware"
	wsHandler "kantin-backend/internal/handler/websocket"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

func main() {
	cfg := config.LoadConfig()

	// 1. Database Connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	db, err := postgres.NewDB(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Printf("[WARN] Tidak dapat terhubung ke PostgreSQL: %v (Pastikan PostgreSQL aktif)", err)
	} else {
		log.Println("[SUCCESS] Terhubung ke PostgreSQL database")
		defer db.Close()
	}

	// 2. Token Maker
	tokenMaker := token.NewTokenMaker(cfg.JWTSecret, cfg.JWTExpiryHours)

	// 3. WebSocket Realtime Hub
	hub := wsHandler.NewHub()
	go hub.Run()

	// 4. Repositories
	userRepo := postgres.NewUserRepo(db)
	productRepo := postgres.NewProductRepo(db)
	orderRepo := postgres.NewOrderRepo(db)
	txRepo := postgres.NewTransactionRepo(db)
	notifRepo := postgres.NewNotificationRepo(db)
	auditRepo := postgres.NewAuditRepo(db)

	// 5. Services
	authService := service.NewAuthService(userRepo, tokenMaker)
	catalogService := service.NewCatalogService(productRepo, userRepo)
	orderService := service.NewOrderService(orderRepo)
	paymentService := service.NewPaymentService(txRepo, userRepo, auditRepo)
	notifService := service.NewNotificationService(notifRepo)

	// 6. HTTP Handlers
	authH := httpHandler.NewAuthHandler(authService)
	catalogH := httpHandler.NewCatalogHandler(catalogService)
	orderH := httpHandler.NewOrderHandler(orderService, hub)
	posH := httpHandler.NewPOSHandler(paymentService)
	studentH := httpHandler.NewStudentHandler(paymentService, notifService)
	financeH := httpHandler.NewFinanceHandler(paymentService)
	uploadH := httpHandler.NewUploadHandler(cfg.UploadDir, db)

	// 7. Fiber App
	app := fiber.New(fiber.Config{
		AppName:      "Kantin Digital Backend v2.0 (Golang)",
		ServerHeader: "Go-Fiber",
		BodyLimit:    20 * 1024 * 1024, // 20 MB max payload for images
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOriginsFunc: func(origin string) bool {
			if cfg.AppEnv == "development" || cfg.AppEnv == "" {
				if origin == "" || strings.HasPrefix(origin, "http://localhost") || strings.HasPrefix(origin, "http://127.0.0.1") || strings.HasPrefix(origin, "https://localhost") {
					return true
				}
			}
			if cfg.CORSOrigins == "*" {
				return true
			}
			for _, allowed := range strings.Split(cfg.CORSOrigins, ",") {
				if strings.TrimSpace(allowed) == origin {
					return true
				}
			}
			return false
		},
		AllowHeaders:     "Origin, Content-Type, Accept, Authorization, X-Requested-With",
		AllowMethods:     "GET, POST, PUT, DELETE, PATCH, OPTIONS",
		AllowCredentials: true,
	}))

	// Static Files (Uploaded images)
	app.Static("/uploads", cfg.UploadDir, fiber.Static{
		Compress:      true,
		ByteRange:     true,
		Browse:        false,
		CacheDuration: 24 * time.Hour,
		MaxAge:        86400,
	})

	// Health Check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"service": "Kantin Digital Go API",
			"time":    time.Now().Format(time.RFC3339),
		})
	})

	// WebSocket Route with JWT Authentication & Room Authorization
	app.Use("/ws", func(c *fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			tokenStr := c.Query("token")
			if tokenStr == "" {
				tokenStr = c.Cookies("access_token")
			}

			room := c.Query("room", "all")
			if room != "all" && room != "public" {
				if tokenStr == "" {
					return fiber.NewError(fiber.StatusUnauthorized, "Token autentikasi wajib untuk bergabung ke room privat")
				}
				claims, err := tokenMaker.VerifyToken(tokenStr)
				if err != nil {
					return fiber.NewError(fiber.StatusUnauthorized, "Token autentikasi tidak valid")
				}
				c.Locals("user_claims", claims)
			}

			c.Locals("allowed", true)
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	})

	app.Get("/ws", websocket.New(func(c *websocket.Conn) {
		room := c.Query("room", "all")
		user := "guest"
		if claimsVal := c.Locals("user_claims"); claimsVal != nil {
			if claims, ok := claimsVal.(*token.JWTClaims); ok {
				user = claims.UserID
			}
		}
		wsHandler.ServeWS(hub, room, user)(c)
	}))

	// API v1 Routing
	api := app.Group("/api/v1")

	// Public Routes
	api.Post("/auth/login", authH.Login)
	api.Get("/canteens", catalogH.ListCanteens)
	api.Get("/canteens/:id/reviews", orderH.ListCanteenReviews)
	api.Get("/products", catalogH.ListProducts)
	api.Get("/student/lookup", studentH.LookupStudent)

	// Protected Routes
	authRequired := api.Group("", middleware.AuthMiddleware(tokenMaker))
	{
		authRequired.Get("/auth/me", authH.Me)
		authRequired.Post("/auth/change-password", authH.ChangePassword)

		// Uploads
		authRequired.Post("/upload/product-image", uploadH.UploadProductImage)
		authRequired.Post("/upload/avatar", uploadH.UploadAvatar)

		// Universal Notifications (Available for all authenticated roles)
		authRequired.Get("/student/notifications", studentH.GetNotifications)
		authRequired.Get("/notifications", studentH.GetNotifications)
		authRequired.Patch("/student/notifications/read-all", studentH.MarkAllNotificationsRead)
		authRequired.Patch("/notifications/read-all", studentH.MarkAllNotificationsRead)
		authRequired.Patch("/student/notifications/:id/read", studentH.MarkNotificationRead)
		authRequired.Patch("/notifications/:id/read", studentH.MarkNotificationRead)

		// Student Routes
		studentGroup := authRequired.Group("/student", middleware.RequireRoles(domain.RoleStudent))
		{
			studentGroup.Get("/me", studentH.GetMyProfile)
			studentGroup.Get("/transactions", studentH.GetTransactions)
		}

		// Orders
		authRequired.Post("/orders", orderH.CreateOrder)
		authRequired.Get("/orders/student", orderH.ListStudentOrders)
		authRequired.Get("/orders/operator", middleware.RequireRoles(domain.RolePetugasKantin), orderH.ListOperatorOrders)
		authRequired.Patch("/orders/:id/status", middleware.RequireRoles(domain.RolePetugasKantin), orderH.UpdateStatus)
		authRequired.Post("/orders/:id/messages", orderH.SendMessage)
		authRequired.Get("/orders/:id/messages", orderH.GetMessages)
		authRequired.Patch("/orders/:id/messages/read", orderH.MarkMessagesAsRead)
		authRequired.Post("/orders/:id/presence", orderH.UpdatePresence)
		authRequired.Get("/orders/:id/presence", orderH.GetPresence)
		authRequired.Post("/orders/:id/review", orderH.SubmitReview)
		authRequired.Get("/orders/:id/review", orderH.GetReview)

		// Canteen Operator & POS
		posGroup := authRequired.Group("/pos", middleware.RequireRoles(domain.RolePetugasKantin))
		{
			posGroup.Get("/scan-card", posH.ScanCard)
			posGroup.Post("/checkout", posH.Checkout)
			posGroup.Get("/sales-history", posH.SalesHistory)
			posGroup.Get("/activities", posH.Activities)
			posGroup.Patch("/delivery-settings", catalogH.UpdateDelivery)
			posGroup.Post("/products", catalogH.CreateProduct)
			posGroup.Put("/products/:id", catalogH.UpdateProduct)
			posGroup.Patch("/products/:id", catalogH.UpdateProduct)
			posGroup.Patch("/products/:id/availability", catalogH.UpdateAvailability)
			posGroup.Delete("/products/:id", catalogH.DeleteProduct)
		}

		// Finance Officer
		financeGroup := authRequired.Group("/finance", middleware.RequireRoles(domain.RolePetugasKeuangan))
		{
			financeGroup.Post("/topup", financeH.Topup)
		}
	}

	// 8. Server Start & Graceful Shutdown
	go func() {
		addr := fmt.Sprintf(":%s", cfg.Port)
		log.Printf("[START] Kantin Digital Go Backend running on port %s", cfg.Port)
		if err := app.Listen(addr); err != nil {
			log.Printf("[STOP] Server closed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("[SHUTDOWN] Menghentikan server secara aman...")
	_ = app.Shutdown()
}
