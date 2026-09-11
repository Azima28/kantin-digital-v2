package middleware

import (
	"context"
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

// sessionIsDead decides whether a cryptographically valid token still belongs to
// a live session. Two independent signals say no:
//
//   - revoked: this exact jti was blacklisted, which is what logout does.
//   - the user's not_before watermark is newer than the token's iat, which is
//     what a password change or an admin-forced reset does to every session at
//     once.
//
// A zero notBefore means no watermark was ever set for this user, so the second
// signal is simply absent -- it must not be read as "issued at the beginning of
// time, therefore stale". Conversely a zero issuedAt with a watermark present is
// treated as stale: legacy tokens predate both jti and iat, so there is nothing
// to compare and nothing to blacklist, and refusing them is the only way a bulk
// revocation can reach them at all.
func sessionIsDead(revoked bool, notBefore, issuedAt time.Time) bool {
	if revoked {
		return true
	}
	if notBefore.IsZero() {
		return false
	}
	return issuedAt.IsZero() || issuedAt.Before(notBefore)
}

// SessionAlive reports whether the session behind an already signature-verified
// token still exists. It is the single place that answers that question, because
// the HTTP middleware is not the only door into the application: the WebSocket
// upgrade also accepts a token, and a logout that closed one but not the other
// would leave the realtime channel alive after the session it belonged to ended.
//
// A nil sessionRepo (tests) or a token without a user id means there is nothing
// to check, so the session is treated as alive. A database error is also treated
// as alive, deliberately: an outage must not disconnect every logged-in user at
// once. That matches how the blocked-account check already fails open.
func SessionAlive(ctx context.Context, sessionRepo *postgres.SessionRepo, claims *token.JWTClaims) bool {
	if sessionRepo == nil || claims == nil || claims.UserID == "" {
		return true
	}
	revoked, notBefore, err := sessionRepo.CheckRevocation(ctx, claims.ID, claims.UserID)
	if err != nil {
		return true
	}
	issuedAt := time.Time{}
	if claims.IssuedAt != nil {
		issuedAt = claims.IssuedAt.Time
	}
	return !sessionIsDead(revoked, notBefore, issuedAt)
}

// AuthMiddleware authenticates a request and enforces that the session behind the
// token is still alive.
//
// userRepo and sessionRepo are required positionally rather than optional: a
// caller that forgets one silently loses the blocked-account check or the whole
// revocation layer, so the compiler should be the one to notice. Passing nil is
// allowed and is what tests do when they only exercise signature verification.
func AuthMiddleware(tokenMaker *token.TokenMaker, userRepo *postgres.UserRepo, sessionRepo *postgres.SessionRepo) fiber.Handler {
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

		// Revocation check: a valid signature is not proof the session still exists.
		// Logout blacklists this exact session id; a password change or an admin
		// reset moves the user's not_before watermark forward, which invalidates
		// every token issued before it -- including tokens minted before jti existed
		// at all, which have no id to blacklist. A database error here is treated as
		// "not revoked", matching how the blocked-account check below already fails
		// open: an outage must not lock out every logged-in user at once.
		if !SessionAlive(c.Context(), sessionRepo, claims) {
			// Drop the cookie too, so a browser stops replaying a dead session
			// on every subsequent request.
			if c.Cookies("access_token") != "" {
				c.Cookie(&fiber.Cookie{
					Name:     "access_token",
					Value:    "",
					Expires:  time.Now().Add(-time.Hour),
					HTTPOnly: true,
					SameSite: "Lax",
					Path:     "/",
				})
			}
			return response.Error(c, fiber.StatusUnauthorized, "Sesi Anda telah berakhir. Silakan login kembali.", fiber.Map{
				"error_code": "SESSION_REVOKED",
			})
		}

		// Security check: Verify if the user's account is still active in database
		if userRepo != nil && claims.UserID != "" {
			user, userErr := userRepo.FindByID(c.Context(), claims.UserID)
			if userErr == nil && user != nil && !user.IsActive {
				return response.Error(c, fiber.StatusForbidden, "Akun Anda sedang dinonaktifkan / diblokir oleh pihak sekolah", fiber.Map{
					"error_code": "ACCOUNT_BLOCKED",
					"is_active":  false,
				})
			}
		}

		// Maintenance mode guard: block non-admin requests while maintenance mode is active
		if userRepo != nil && userRepo.IsMaintenanceMode(c.Context()) {
			if claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin {
				return response.Error(c, fiber.StatusServiceUnavailable, "Sistem sedang dalam mode pemeliharaan (maintenance). Akses non-admin sedang diblokir sementara.", fiber.Map{
					"error_code":  "MAINTENANCE_MODE",
					"maintenance": true,
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
						isSecure := c.Protocol() == "https" || c.Get("X-Forwarded-Proto") == "https" || strings.Contains(c.Hostname(), "zitech.web.id")
						c.Cookie(&fiber.Cookie{
							Name:     "access_token",
							Value:    renewedToken,
							Expires:  newExpiry,
							HTTPOnly: true,
							Secure:   isSecure,
							SameSite: "Lax",
							Path:     "/",
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
