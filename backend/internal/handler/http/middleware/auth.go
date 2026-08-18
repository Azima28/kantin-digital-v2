package middleware

import (
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
)

const (
	AuthorizationHeader = "authorization"
	AuthorizationType   = "bearer"
	UserClaimsKey       = "user_claims"
)

func AuthMiddleware(tokenMaker *token.TokenMaker, userRepo ...*postgres.UserRepo) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get(AuthorizationHeader)
		if authHeader == "" {
			// Also check cookie for Web Clients
			cookieToken := c.Cookies("access_token")
			if cookieToken != "" {
				authHeader = "Bearer " + cookieToken
			} else {
				return response.Error(c, fiber.StatusUnauthorized, "Header otorisasi tidak ditemukan", nil)
			}
		}

		fields := strings.Fields(authHeader)
		if len(fields) < 2 || strings.ToLower(fields[0]) != AuthorizationType {
			return response.Error(c, fiber.StatusUnauthorized, "Format token tidak valid (wajib Bearer)", nil)
		}

		accessToken := fields[1]
		claims, err := tokenMaker.VerifyToken(accessToken)
		if err != nil {
			return response.Error(c, fiber.StatusUnauthorized, "Sesi login kadaluarsa atau tidak valid", nil)
		}

		// Security check: Verify if the user's account is still active in database
		if len(userRepo) > 0 && userRepo[0] != nil && claims.UserID != "" {
			user, userErr := userRepo[0].FindByID(c.Context(), claims.UserID)
			if userErr == nil && user != nil && !user.IsActive {
				return response.Error(c, fiber.StatusForbidden, "Akun Anda sedang dinonaktifkan / diblokir oleh pihak sekolah", fiber.Map{
					"error_code": "ACCOUNT_BLOCKED",
					"is_active":  false,
				})
			}
		}

		// Sliding Session: Auto-renew token if remaining lifetime is less than 50%
		if claims.ExpiresAt != nil {
			timeLeft := time.Until(claims.ExpiresAt.Time)
			halfDuration := time.Duration(tokenMaker.DurationHours()/2) * time.Hour
			if timeLeft < halfDuration {
				renewedToken, newExpiry, renewErr := tokenMaker.RenewToken(claims)
				if renewErr == nil && renewedToken != "" {
					c.Set("X-Renewed-Token", renewedToken)
					c.Set("Access-Control-Expose-Headers", "X-Renewed-Token")
					if c.Cookies("access_token") != "" {
						c.Cookie(&fiber.Cookie{
							Name:     "access_token",
							Value:    renewedToken,
							Expires:  newExpiry,
							HTTPOnly: true,
							Secure:   false,
							SameSite: "Lax",
						})
					}
				}
			}
		}

		c.Locals(UserClaimsKey, claims)
		return c.Next()
	}
}

func RequireRoles(allowedRoles ...domain.Role) fiber.Handler {
	return func(c *fiber.Ctx) error {
		claimsVal := c.Locals(UserClaimsKey)
		if claimsVal == nil {
			return response.Error(c, fiber.StatusUnauthorized, "Pengguna tidak terautentikasi", nil)
		}

		claims, ok := claimsVal.(*token.JWTClaims)
		if !ok {
			return response.Error(c, fiber.StatusUnauthorized, "Klaim token tidak valid", nil)
		}

		for _, r := range allowedRoles {
			if claims.Role == r || claims.Role == domain.RoleSuperAdmin {
				return c.Next()
			}
		}

		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda tidak memiliki wewenang untuk aksi ini", nil)
	}
}
