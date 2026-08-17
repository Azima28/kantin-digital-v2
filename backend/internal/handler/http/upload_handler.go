package http

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
)

type UploadHandler struct {
	uploadDir string
	db        *postgres.DB
}

func NewUploadHandler(uploadDir string, db *postgres.DB) *UploadHandler {
	return &UploadHandler{uploadDir: uploadDir, db: db}
}

func (h *UploadHandler) UploadProductImage(c *fiber.Ctx) error {
	file, err := c.FormFile("image")
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, "File gambar tidak ditemukan dalam form-data", err.Error())
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return response.Error(c, fiber.StatusBadRequest, "Format file harus berupa JPG, PNG, atau WebP", nil)
	}

	targetDir := filepath.Join(h.uploadDir, "products")
	_ = os.MkdirAll(targetDir, 0755)

	newFilename := fmt.Sprintf("product_%d_%s%s", time.Now().UnixMilli(), uuid.New().String()[:8], ext)
	savePath := filepath.Join(targetDir, newFilename)

	if err := c.SaveFile(file, savePath); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan file gambar ke server", err.Error())
	}

	// Generate absolute or relative URL
	publicURL := fmt.Sprintf("/uploads/products/%s", newFilename)
	return response.Success(c, fiber.StatusOK, "Gambar produk berhasil diupload", map[string]string{
		"file_name": newFilename,
		"url":       publicURL,
	})
}

func (h *UploadHandler) UploadAvatar(c *fiber.Ctx) error {
	file, err := c.FormFile("avatar")
	if err != nil {
		file, err = c.FormFile("image")
	}
	if err != nil {
		file, err = c.FormFile("file")
	}
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, "File avatar tidak ditemukan dalam form-data", err.Error())
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return response.Error(c, fiber.StatusBadRequest, "Format file harus berupa JPG, PNG, atau WebP", nil)
	}

	targetDir := filepath.Join(h.uploadDir, "avatars")
	_ = os.MkdirAll(targetDir, 0755)

	newFilename := fmt.Sprintf("avatar_%d_%s%s", time.Now().UnixMilli(), uuid.New().String()[:8], ext)
	savePath := filepath.Join(targetDir, newFilename)

	if err := c.SaveFile(file, savePath); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan avatar ke server", err.Error())
	}

	publicURL := fmt.Sprintf("/uploads/avatars/%s", newFilename)

	// Automatically persist avatar_url to user profile in database
	if claimsVal := c.Locals(middleware.UserClaimsKey); claimsVal != nil {
		if claims, ok := claimsVal.(*token.JWTClaims); ok && claims.UserID != "" {
			if h.db != nil && h.db.Pool != nil {
				_, _ = h.db.Pool.Exec(c.Context(), `UPDATE public.profiles SET avatar_url = $1 WHERE id = $2`, publicURL, claims.UserID)
			}
		}
	}

	return response.Success(c, fiber.StatusOK, "Avatar berhasil diupload", map[string]string{
		"file_name": newFilename,
		"url":       publicURL,
	})
}
