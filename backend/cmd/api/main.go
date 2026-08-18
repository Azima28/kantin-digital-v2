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
	paymentService := service.NewPaymentService(txRepo, userRepo, auditRepo, productRepo)
	notifService := service.NewNotificationService(notifRepo)

	// 6. HTTP Handlers
	authH := httpHandler.NewAuthHandler(authService)
	catalogH := httpHandler.NewCatalogHandler(catalogService)
	orderH := httpHandler.NewOrderHandler(orderService, hub)
	posH := httpHandler.NewPOSHandler(paymentService)
	studentH := httpHandler.NewStudentHandler(paymentService, notifService)
	financeH := httpHandler.NewFinanceHandler(paymentService)
	adminH := httpHandler.NewAdminHandler(paymentService, catalogService, hub)
	parentH := httpHandler.NewParentHandler(paymentService)
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
		ExposeHeaders:    "X-Renewed-Token",
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
		api.Get("/academic-structure", catalogH.GetPublicAcademicStructure)

	// Protected Routes
	authRequired := api.Group("", middleware.AuthMiddleware(tokenMaker, userRepo))
	{
		authRequired.Get("/auth/me", authH.Me)
		authRequired.Post("/auth/change-password", authH.ChangePassword)

		// Uploads
		authRequired.Post("/upload/product-image", uploadH.UploadProductImage)
		authRequired.Post("/upload/avatar", uploadH.UploadAvatar)

		// Profile Updates
		authRequired.Patch("/auth/profile", authH.UpdateProfile)
		authRequired.Put("/auth/profile", authH.UpdateProfile)

		// Universal Notifications (Available for all authenticated roles)
		authRequired.Get("/student/notifications", studentH.GetNotifications)
		authRequired.Get("/notifications", studentH.GetNotifications)
		authRequired.Patch("/student/notifications/read-all", studentH.MarkAllNotificationsRead)
		authRequired.Patch("/notifications/read-all", studentH.MarkAllNotificationsRead)
		authRequired.Patch("/student/notifications/:id/read", studentH.MarkNotificationRead)
		authRequired.Patch("/notifications/:id/read", studentH.MarkNotificationRead)

		// Student Routes
		studentGroup := authRequired.Group("/student", middleware.RequireRoles(domain.RoleStudent, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan))
		{
			studentGroup.Get("/me", studentH.GetMyProfile)
			studentGroup.Get("/transactions", studentH.GetTransactions)
			studentGroup.Post("/topup", financeH.Topup)
		}

		// Orders
		authRequired.Post("/orders", orderH.CreateOrder)
		authRequired.Get("/orders/student", orderH.ListStudentOrders)
		authRequired.Get("/orders/operator", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan), orderH.ListOperatorOrders)
		authRequired.Get("/orders/:id", orderH.GetOrderByID)
		authRequired.Patch("/orders/:id/status", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleSuperAdmin, domain.RoleAdmin), orderH.UpdateStatus)
		authRequired.Post("/orders/:id/messages", orderH.SendMessage)
		authRequired.Get("/orders/:id/messages", orderH.GetMessages)
		authRequired.Patch("/orders/:id/messages/read", orderH.MarkMessagesAsRead)
		authRequired.Post("/orders/:id/presence", orderH.UpdatePresence)
		authRequired.Get("/orders/:id/presence", orderH.GetPresence)
		authRequired.Post("/orders/:id/review", orderH.SubmitReview)
		authRequired.Get("/orders/:id/review", orderH.GetReview)

		// Canteen Operator & POS
		posGroup := authRequired.Group("/pos", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan))
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
		financeGroup := authRequired.Group("/finance", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin))
		{
			financeGroup.Get("/dashboard", financeH.Dashboard)
			financeGroup.Get("/students", financeH.ListStudents)
			financeGroup.Get("/history", financeH.History)
			financeGroup.Get("/audit-logs", adminH.ListAuditLogs)
			financeGroup.Get("/users", adminH.ListUsers)
			financeGroup.Get("/student/:id", adminH.GetStudentDetail)
			financeGroup.Get("/merchant/:id", adminH.GetMerchantDetail)
			financeGroup.Get("/parent/:id", adminH.GetParentDetail)
			financeGroup.Post("/topup", financeH.Topup)
			financeGroup.Post("/correction", financeH.Correction)
			financeGroup.Get("/report", financeH.Report)
		}

		// Parent Portal & Student Management
		parentGroup := authRequired.Group("/parent", middleware.RequireRoles(domain.RoleParent, domain.RoleSuperAdmin, domain.RoleAdmin))
		{
			parentGroup.Get("/dashboard/:studentId", parentH.Dashboard)
			parentGroup.Post("/topup", financeH.Topup)
		}
		authRequired.Patch("/student/settings", parentH.UpdateStudentSettings)
		authRequired.Patch("/student/card-status", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), studentH.UpdateCardStatus)
		authRequired.Patch("/users/:id/status", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateStatus)

		// Super Admin & Admin / Finance Management
		adminGroup := authRequired.Group("/admin", middleware.RequireRoles(domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan))
		{
			adminGroup.Get("/dashboard", adminH.Dashboard)
			adminGroup.Get("/users", adminH.ListUsers)
			adminGroup.Post("/users", adminH.CreateUser)
			adminGroup.Post("/students", adminH.CreateUser)
			adminGroup.Put("/students/:id", adminH.UpdateStudent)
			adminGroup.Patch("/students/:id", adminH.UpdateStudent)
			adminGroup.Put("/users/:id", adminH.UpdateUser)
			adminGroup.Patch("/users/:id", adminH.UpdateUser)
			adminGroup.Post("/users/password", adminH.AdminChangePassword)
			adminGroup.Delete("/users/:id", adminH.DeleteUser)
			adminGroup.Get("/audit-logs", adminH.ListAuditLogs)
			adminGroup.Get("/student/:id", adminH.GetStudentDetail)
			adminGroup.Get("/merchant/:id", adminH.GetMerchantDetail)
			adminGroup.Get("/parent/:id", adminH.GetParentDetail)
			adminGroup.Get("/finance/:id", adminH.GetFinanceDetail)
			adminGroup.Get("/academic-structure", adminH.GetAcademicStructure)
			adminGroup.Post("/academic-structure", adminH.SaveAcademicStructure)
			adminGroup.Put("/academic-structure", adminH.SaveAcademicStructure)
			adminGroup.Get("/settings", adminH.GetSettings)
			adminGroup.Post("/settings", adminH.SaveSettings)
			adminGroup.Put("/settings", adminH.SaveSettings)
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
