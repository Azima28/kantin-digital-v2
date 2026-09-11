package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/limiter"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/gofiber/websocket/v2"

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

// loginRateKey buckets credential attempts per identifier instead of per address.
//
// A school reaches the internet through one NAT address, so keying a tight limit on
// c.IP() alone would let a single student fat-fingering their password lock out
// everyone behind the same gateway. The body is read only to build the key; fasthttp
// keeps it buffered, so the handler still parses the same request afterwards.
func loginRateKey(c *fiber.Ctx) string {
	var body struct {
		Identifier string `json:"identifier"`
	}
	_ = json.Unmarshal(c.Body(), &body)

	identifier := strings.ToLower(strings.TrimSpace(body.Identifier))
	if identifier == "" {
		return c.IP() + "|-"
	}
	return c.IP() + "|" + identifier
}

// passwordRateKey follows the account rather than the network, since these routes
// already ran through authentication by the time the limiter sees them.
func passwordRateKey(c *fiber.Ctx) string {
	if claims, ok := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims); ok && claims != nil && claims.UserID != "" {
		return "pwd:" + claims.UserID
	}
	return "pwd:" + c.IP()
}

// throttled answers a rate-limited request in the same envelope as every other
// error, so the app surfaces the message instead of a bare status code.
func throttled(message string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		return response.Error(c, fiber.StatusTooManyRequests, message, fiber.Map{
			"error_code": "RATE_LIMITED",
		})
	}
}

func main() {
	cfg := config.LoadConfig()

	// 1. Database Connection with Auto-Retry
	var db *postgres.DB
	for attempt := 1; attempt <= 3; attempt++ {
		connectCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		var err error
		db, err = postgres.NewDB(connectCtx, cfg.DatabaseURL)
		cancel()
		if err == nil {
			log.Printf("[SUCCESS] Terhubung ke PostgreSQL database (Percobaan %d)", attempt)
			defer db.Close()
			break
		}
		log.Printf("[WARN] Percobaan %d gagal terhubung ke PostgreSQL: %v", attempt, err)
		if attempt < 3 {
			time.Sleep(1 * time.Second)
		}
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
	shiftRepo := postgres.NewShiftRepo(db)
	sessionRepo := postgres.NewSessionRepo(db)

	// 5. Services
	authService := service.NewAuthService(userRepo, tokenMaker)
	catalogService := service.NewCatalogService(productRepo, userRepo)
	orderService := service.NewOrderService(orderRepo)
	paymentService := service.NewPaymentService(txRepo, userRepo, auditRepo, productRepo, shiftRepo)
	notifService := service.NewNotificationService(notifRepo)

	// 6. HTTP Handlers
	authH := httpHandler.NewAuthHandler(authService, sessionRepo)
	catalogH := httpHandler.NewCatalogHandler(catalogService, tokenMaker)
	orderH := httpHandler.NewOrderHandler(orderService, hub)
	posH := httpHandler.NewPOSHandler(paymentService)
	studentH := httpHandler.NewStudentHandler(paymentService, notifService, tokenMaker)
	financeH := httpHandler.NewFinanceHandler(paymentService, hub)
	adminH := httpHandler.NewAdminHandler(paymentService, catalogService, sessionRepo, hub)
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

	// Security response headers.
	//
	// No Content-Security-Policy on purpose: this process also serves the uploaded
	// images under /uploads, and a policy tight enough to be worth having here would
	// have to be loosened for those anyway. Resource policy is cross-origin because
	// the web build is served from a different host than the API and has to be able
	// to load those images. HSTS is production-only, and helmet already limits it to
	// requests that arrived over https, so a local http run is unaffected.
	hstsMaxAge := 0
	if cfg.AppEnv == "production" {
		hstsMaxAge = 31536000
	}
	app.Use(helmet.New(helmet.Config{
		XSSProtection:             "0",
		ContentTypeNosniff:        "nosniff",
		XFrameOptions:             "DENY",
		ReferrerPolicy:            "strict-origin-when-cross-origin",
		CrossOriginEmbedderPolicy: "unsafe-none",
		CrossOriginOpenerPolicy:   "same-origin",
		CrossOriginResourcePolicy: "cross-origin",
		OriginAgentCluster:        "?1",
		XDNSPrefetchControl:       "off",
		XDownloadOptions:          "noopen",
		XPermittedCrossDomain:     "none",
		HSTSMaxAge:                hstsMaxAge,
	}))

	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOriginsFunc: func(origin string) bool {
			if origin == "null" {
				return false
			}
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

	// Static Files (Uploaded images) with anti-MIME sniffing protection
	app.Use("/uploads", func(c *fiber.Ctx) error {
		c.Set("X-Content-Type-Options", "nosniff")
		return c.Next()
	})
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
			var claims *token.JWTClaims
			if tokenStr != "" {
				// A signature that still verifies is not proof the session is alive.
				// Without the same revocation check the HTTP middleware runs, a token
				// that had already been logged out would keep opening private realtime
				// rooms until it expired on its own -- the one door logout left open.
				// A dead session is treated as no token at all, so public rooms still
				// connect as a guest while every private room below rejects it.
				if verified, verifyErr := tokenMaker.VerifyToken(tokenStr); verifyErr == nil && verified != nil &&
					middleware.SessionAlive(c.Context(), sessionRepo, verified) {
					claims = verified
					c.Locals("user_claims", verified)
				}
			}

			if room != "all" && room != "public" {
				if claims == nil {
					return fiber.NewError(fiber.StatusUnauthorized, "Token autentikasi valid wajib untuk bergabung ke room privat")
				}

				// Verify room access control based on room prefix
				if strings.HasPrefix(room, "student:") {
					targetID := strings.TrimPrefix(room, "student:")
					if claims.UserID != targetID && claims.Role != domain.RoleAdmin && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RolePetugasKeuangan {
						return fiber.NewError(fiber.StatusForbidden, "Akses room siswa ditolak")
					}
				} else if strings.HasPrefix(room, "canteen:") {
					targetID := strings.TrimPrefix(room, "canteen:")
					if claims.UserID != targetID && claims.Role != domain.RoleAdmin && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RolePetugasKeuangan {
						return fiber.NewError(fiber.StatusForbidden, "Akses room kantin ditolak")
					}
				} else if strings.HasPrefix(room, "order:") {
					orderID := strings.TrimPrefix(room, "order:")
					if claims.Role != domain.RoleAdmin && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RolePetugasKeuangan {
						order, err := orderRepo.GetOrderByID(c.Context(), orderID)
						if err != nil || order == nil {
							return fiber.NewError(fiber.StatusNotFound, "Pesanan tidak ditemukan")
						}
						isStudent := strings.EqualFold(order.StudentID, claims.UserID)
						isOperator := claims.Role == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, claims.UserID)
						if !isStudent && !isOperator {
							return fiber.NewError(fiber.StatusForbidden, "Akses chat room pesanan ditolak")
						}
					}
				}
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

	// Brute-force protection on the credential endpoints.
	//
	// Two limiters in series, because one key cannot cover both threats. The tight one
	// counts only failed attempts against a single identifier, which is what stops
	// password guessing without punishing a user who simply logs in a lot. The loose
	// one counts every request from an address and is the backstop against spraying
	// one password across hundreds of accounts -- deliberately generous, because the
	// whole school shares that address.
	loginAttemptLimiter := limiter.New(limiter.Config{
		Max:                    8,
		Expiration:             5 * time.Minute,
		SkipSuccessfulRequests: true,
		KeyGenerator:           loginRateKey,
		LimitReached:           throttled("Terlalu banyak percobaan login gagal untuk akun ini. Coba lagi dalam beberapa menit."),
	})
	loginAddressLimiter := limiter.New(limiter.Config{
		Max:        90,
		Expiration: 1 * time.Minute,
		KeyGenerator: func(c *fiber.Ctx) string {
			return "login:" + c.IP()
		},
		LimitReached: throttled("Permintaan login dari jaringan ini terlalu banyak. Coba lagi sebentar."),
	})
	passwordLimiter := limiter.New(limiter.Config{
		Max:          10,
		Expiration:   10 * time.Minute,
		KeyGenerator: passwordRateKey,
		LimitReached: throttled("Terlalu banyak percobaan ganti kata sandi. Coba lagi nanti."),
	})

	// Public Routes
	api.Post("/auth/login", loginAddressLimiter, loginAttemptLimiter, authH.Login)
	api.Get("/canteens", catalogH.ListCanteens)
	api.Get("/canteens/:id/reviews", orderH.ListCanteenReviews)
	api.Get("/products", catalogH.ListProducts)
	api.Get("/student/lookup", studentH.LookupStudent)
	api.Get("/academic-structure", catalogH.GetPublicAcademicStructure)

	// Protected Routes
	authRequired := api.Group("", middleware.AuthMiddleware(tokenMaker, userRepo, sessionRepo))
	{
		authRequired.Get("/auth/me", authH.Me)
		authRequired.Post("/auth/logout", authH.Logout)
		authRequired.Post("/auth/change-password", passwordLimiter, authH.ChangePassword)

		// Uploads (Protected with role verification for products)
		authRequired.Post("/upload/product-image", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleAdmin, domain.RoleSuperAdmin), uploadH.UploadProductImage)
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
		authRequired.Delete("/student/notifications", studentH.DeleteAllNotifications)
		authRequired.Delete("/notifications", studentH.DeleteAllNotifications)
		authRequired.Delete("/student/notifications/:id", studentH.DeleteNotification)
		authRequired.Delete("/notifications/:id", studentH.DeleteNotification)

		// Student Routes
		studentGroup := authRequired.Group("/student", middleware.RequireRoles(domain.RoleStudent, domain.RoleParent, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan))
		{
			studentGroup.Get("/me", studentH.GetMyProfile)
			studentGroup.Get("/transactions", studentH.GetTransactions)
			studentGroup.Post("/topup", studentH.Topup)
			studentGroup.Patch("/settings", parentH.UpdateStudentSettings)
			studentGroup.Patch("/card-status", studentH.UpdateCardStatus)
			studentGroup.Post("/change-pin", studentH.ChangePin)
			studentGroup.Post("/verify-pin", studentH.VerifyPin)
		}
		authRequired.Post("/student/change-pin", studentH.ChangePin)
		authRequired.Post("/student/verify-pin", studentH.VerifyPin)

		// Orders
		authRequired.Post("/orders", orderH.CreateOrder)
		authRequired.Get("/orders/student", orderH.ListStudentOrders)
		authRequired.Get("/orders/operator", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan), orderH.ListOperatorOrders)
		authRequired.Get("/orders/:id", orderH.GetOrderByID)
		authRequired.Patch("/orders/:id/status", middleware.RequireRoles(domain.RolePetugasKantin, domain.RoleStudent, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan), orderH.UpdateStatus)
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
			financeGroup.Post("/students", adminH.CreateUser)
			financeGroup.Put("/students/:id", adminH.UpdateStudent)
			financeGroup.Patch("/students/:id", adminH.UpdateStudent)
			financeGroup.Get("/history", financeH.History)
			financeGroup.Get("/audit-logs", adminH.ListAuditLogs)
			financeGroup.Get("/users", adminH.ListUsers)
			financeGroup.Post("/users", adminH.CreateUser)
			financeGroup.Post("/users/password", passwordLimiter, adminH.AdminChangePassword)
			financeGroup.Post("/users/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			financeGroup.Post("/students/:id/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			financeGroup.Post("/student/:id/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			financeGroup.Get("/student/:id", adminH.GetStudentDetail)
			financeGroup.Get("/merchant/:id", adminH.GetMerchantDetail)
			financeGroup.Get("/parent/:id", adminH.GetParentDetail)
			financeGroup.Put("/canteen-operators/:id", adminH.UpdateCanteenOperator)
			financeGroup.Patch("/canteen-operators/:id", adminH.UpdateCanteenOperator)
			financeGroup.Post("/topup", financeH.Topup)
			financeGroup.Post("/merchant/withdraw", financeH.MerchantWithdraw)
			financeGroup.Get("/report", financeH.Report)
			financeGroup.Get("/academic-structure", adminH.GetAcademicStructure)

			// Continuous Shift Ledger Routes
			financeGroup.Get("/shift/current", financeH.GetCurrentShift)
			financeGroup.Post("/shift/close", financeH.CloseShift)
			financeGroup.Get("/shift/history", financeH.ListShiftHistory)
		}

		// Parent Portal & Student Management
		parentGroup := authRequired.Group("/parent", middleware.RequireRoles(domain.RoleParent, domain.RoleSuperAdmin, domain.RoleAdmin))
		{
			parentGroup.Get("/dashboard/:studentId", parentH.Dashboard)
			parentGroup.Post("/topup", studentH.Topup)
			parentGroup.Patch("/student/settings", parentH.UpdateStudentSettings)
			parentGroup.Patch("/settings", parentH.UpdateStudentSettings)
		}
		authRequired.Patch("/student/settings", middleware.RequireRoles(domain.RoleParent, domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan), parentH.UpdateStudentSettings)
		authRequired.Patch("/student/card-status", middleware.RequireRoles(domain.RoleStudent, domain.RoleParent, domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), studentH.UpdateCardStatus)
		authRequired.Patch("/users/:id/status", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateStatus)
		authRequired.Put("/students/:id", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateStudent)
		authRequired.Patch("/students/:id", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateStudent)
		authRequired.Post("/users/password", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), passwordLimiter, adminH.AdminChangePassword)
		authRequired.Post("/users/pin", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), passwordLimiter, adminH.AdminChangeStudentPin)
		authRequired.Post("/students/:id/pin", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), passwordLimiter, adminH.AdminChangeStudentPin)
		authRequired.Post("/student/:id/pin", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), passwordLimiter, adminH.AdminChangeStudentPin)
		authRequired.Get("/admin/merchant/:id", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.GetMerchantDetail)
		authRequired.Put("/admin/canteen-operators/:id", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateCanteenOperator)
		authRequired.Patch("/admin/canteen-operators/:id", middleware.RequireRoles(domain.RolePetugasKeuangan, domain.RoleSuperAdmin, domain.RoleAdmin), adminH.UpdateCanteenOperator)

		// Super Admin & Admin Management ONLY (RolePetugasKeuangan excluded)
		adminGroup := authRequired.Group("/admin", middleware.RequireRoles(domain.RoleSuperAdmin, domain.RoleAdmin))
		{
			adminGroup.Get("/dashboard", adminH.Dashboard)
			adminGroup.Get("/users", adminH.ListUsers)
			adminGroup.Post("/users", adminH.CreateUser)
			adminGroup.Post("/students", adminH.CreateUser)
			adminGroup.Put("/students/:id", adminH.UpdateStudent)
			adminGroup.Patch("/students/:id", adminH.UpdateStudent)
			adminGroup.Put("/users/:id", adminH.UpdateUser)
			adminGroup.Patch("/users/:id", adminH.UpdateUser)

			// Role-scoped edits. The admin app has been calling these three paths all
			// along; they were never registered, so every save from the merchant,
			// finance and parent edit sheets came back 404.
			adminGroup.Put("/canteen-operators/:id", adminH.UpdateCanteenOperator)
			adminGroup.Patch("/canteen-operators/:id", adminH.UpdateCanteenOperator)
			adminGroup.Put("/finance-officers/:id", adminH.UpdateFinanceOfficer)
			adminGroup.Patch("/finance-officers/:id", adminH.UpdateFinanceOfficer)
			adminGroup.Put("/parents/:id", adminH.UpdateParent)
			adminGroup.Patch("/parents/:id", adminH.UpdateParent)
			adminGroup.Post("/users/password", passwordLimiter, adminH.AdminChangePassword)
			adminGroup.Post("/users/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			adminGroup.Post("/students/:id/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			adminGroup.Post("/student/:id/pin", passwordLimiter, adminH.AdminChangeStudentPin)
			adminGroup.Delete("/users/:id", adminH.DeleteUser)
			adminGroup.Get("/audit-logs", adminH.ListAuditLogs)
			adminGroup.Get("/student/:id", adminH.GetStudentDetail)
			adminGroup.Get("/merchant/:id", adminH.GetMerchantDetail)
			adminGroup.Get("/parent/:id", adminH.GetParentDetail)
			adminGroup.Get("/finance/:id", adminH.GetFinanceDetail)
			adminGroup.Get("/finance-officers/ledger", adminH.ListFinanceOfficersLedger)
			adminGroup.Get("/finance-officers/:id/ledger", adminH.GetFinanceOfficerLedgerDetail)
			adminGroup.Post("/merchant/withdraw", financeH.MerchantWithdraw)
			adminGroup.Get("/academic-structure", adminH.GetAcademicStructure)
			adminGroup.Post("/academic-structure", adminH.SaveAcademicStructure)
			adminGroup.Put("/academic-structure", adminH.SaveAcademicStructure)
			adminGroup.Get("/settings", adminH.GetSettings)
			adminGroup.Post("/settings", adminH.SaveSettings)
			adminGroup.Put("/settings", adminH.SaveSettings)
			adminGroup.Post("/broadcast", adminH.Broadcast)

			// Super Admin Shift Review & Verification Routes
			adminGroup.Get("/finance/shifts", financeH.AdminListAllShifts)
			adminGroup.Post("/finance/shift/:id/verify", financeH.AdminVerifyShift)
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
