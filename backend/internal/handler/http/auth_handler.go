package http

import (
	"errors"
	"strings"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

type AuthHandler struct {
	authService *service.AuthService
}

func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

type LoginRequest struct {
	Identifier string `json:"identifier"` // Email, Username, or NISN
	Password   string `json:"password"`
	Role       string `json:"role,omitempty"` // Optional expected role: "parent", "student", "petugas_kantin", etc.
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload request tidak valid", err.Error())
	}

	if req.Identifier == "" {
		return response.Error(c, fiber.StatusBadRequest, "Identitas login (Email/NISN/Username) wajib diisi", nil)
	}

	resp, err := h.authService.Login(c.Context(), req.Identifier, req.Password, req.Role)
	if err != nil {
		if errors.Is(err, postgres.ErrDatabaseNotReady) {
			return response.Error(c, fiber.StatusServiceUnavailable, "Database PostgreSQL sedang tidak terhubung. Silakan coba sesaat lagi.", nil)
		}
		if errors.Is(err, service.ErrAccountInactive) || strings.Contains(err.Error(), "dinonaktifkan") || strings.Contains(err.Error(), "diblokir") {
			return response.Error(c, fiber.StatusForbidden, err.Error(), fiber.Map{
				"error_code": "ACCOUNT_BLOCKED",
				"is_active":  false,
			})
		}
		return response.Error(c, fiber.StatusUnauthorized, err.Error(), nil)
	}

	// Set HttpOnly Cookie for Web Clients
	c.Cookie(&fiber.Cookie{
		Name:     "access_token",
		Value:    resp.Token,
		Expires:  resp.ExpiresAt,
		HTTPOnly: true,
		Secure:   false, // Set true in HTTPS production
		SameSite: "Lax",
	})

	return response.Success(c, fiber.StatusOK, "Login berhasil", resp)
}

func (h *AuthHandler) Me(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	return response.Success(c, fiber.StatusOK, "Profil terautentikasi", claims)
}

type ChangePasswordRequest struct {
	OldPassword string `json:"old_password"`
	NewPassword string `json:"new_password"`
}

func (h *AuthHandler) ChangePassword(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req ChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload request tidak valid", err.Error())
	}

	if len(req.NewPassword) < 6 {
		return response.Error(c, fiber.StatusBadRequest, "Kata sandi baru minimal 6 karakter", nil)
	}

	if err := h.authService.ChangePassword(c.Context(), claims.UserID, req.OldPassword, req.NewPassword); err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Kata sandi berhasil diperbarui", nil)
}

type UpdateProfileRequest struct {
	FullName    string  `json:"full_name"`
	PhoneNumber *string `json:"phone_number"`
	AvatarURL   *string `json:"avatar_url"`
}

func (h *AuthHandler) UpdateProfile(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req UpdateProfileRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload request tidak valid", err.Error())
	}

	user, err := h.authService.UpdateProfile(c.Context(), claims.UserID, req.FullName, req.PhoneNumber, req.AvatarURL)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui profil: "+err.Error(), err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Profil berhasil diperbarui", user)
}
