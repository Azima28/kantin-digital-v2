package http

import (
	"fmt"
	"net/http"
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

const maxUploadSize = 5 * 1024 * 1024 // 5 MB

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

	if file.Size > maxUploadSize {
		return response.Error(c, fiber.StatusBadRequest, "Ukuran file gambar maksimal 5 MB", nil)
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return response.Error(c, fiber.StatusBadRequest, "Format file harus berupa JPG, PNG, atau WebP", nil)
	}

	// Validate MIME type via magic bytes
	f, err := file.Open()
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal membaca header file gambar", err.Error())
	}
	buf := make([]byte, 512)
	n, _ := f.Read(buf)
	f.Close()

	mimeType := http.DetectContentType(buf[:n])
	if !strings.HasPrefix(mimeType, "image/") && mimeType != "application/octet-stream" {
		return response.Error(c, fiber.StatusBadRequest, "File yang diunggah bukan format gambar yang valid", nil)
	}

	targetDir := filepath.Join(h.uploadDir, "products")
	_ = os.MkdirAll(targetDir, 0755)

	newFilename := fmt.Sprintf("product_%d_%s%s", time.Now().UnixMilli(), uuid.New().String()[:8], ext)
	savePath := filepath.Join(targetDir, newFilename)

	if err := c.SaveFile(file, savePath); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan file gambar ke server", err.Error())
	}

	// Generate absolute URL
	baseURL := c.BaseURL()
	if c.Get("X-Forwarded-Proto") == "https" || strings.Contains(c.Hostname(), "zitech.web.id") {
		baseURL = strings.Replace(baseURL, "http://", "https://", 1)
	}
	if baseURL == "" || strings.Contains(baseURL, "localhost:655") || strings.Contains(baseURL, "localhost:591") {
		baseURL = "http://127.0.0.1:8000"
	}
	publicURL := fmt.Sprintf("%s/uploads/products/%s", baseURL, newFilename)
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

	if file.Size > maxUploadSize {
		return response.Error(c, fiber.StatusBadRequest, "Ukuran file avatar maksimal 5 MB", nil)
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" && ext != ".webp" {
		return response.Error(c, fiber.StatusBadRequest, "Format file harus berupa JPG, PNG, atau WebP", nil)
	}

	// Validate MIME type via magic bytes
	f, err := file.Open()
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal membaca header file avatar", err.Error())
	}
	buf := make([]byte, 512)
	n, _ := f.Read(buf)
	f.Close()

	mimeType := http.DetectContentType(buf[:n])
	if !strings.HasPrefix(mimeType, "image/") && mimeType != "application/octet-stream" {
		return response.Error(c, fiber.StatusBadRequest, "File yang diunggah bukan format gambar yang valid", nil)
	}

	targetDir := filepath.Join(h.uploadDir, "avatars")
	_ = os.MkdirAll(targetDir, 0755)

	newFilename := fmt.Sprintf("avatar_%d_%s%s", time.Now().UnixMilli(), uuid.New().String()[:8], ext)
	savePath := filepath.Join(targetDir, newFilename)

	if err := c.SaveFile(file, savePath); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan avatar ke server", err.Error())
	}

	baseURL := c.BaseURL()
	if c.Get("X-Forwarded-Proto") == "https" || strings.Contains(c.Hostname(), "zitech.web.id") {
		baseURL = strings.Replace(baseURL, "http://", "https://", 1)
	}
	if baseURL == "" || strings.Contains(baseURL, "localhost:655") || strings.Contains(baseURL, "localhost:591") {
		baseURL = "http://127.0.0.1:8000"
	}
	publicURL := fmt.Sprintf("%s/uploads/avatars/%s", baseURL, newFilename)

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
