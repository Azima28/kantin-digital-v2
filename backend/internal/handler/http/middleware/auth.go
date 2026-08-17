package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
)

const (
	AuthorizationHeader = "authorization"
	AuthorizationType   = "bearer"
	UserClaimsKey       = "user_claims"
)

func AuthMiddleware(tokenMaker *token.TokenMaker) fiber.Handler {
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
