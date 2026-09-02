package http

import (
	"errors"
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

// validateImageBytes strictly validates file magic bytes and MIME types without allowing octet-stream bypass
func validateImageBytes(buf []byte, ext string) error {
	if len(buf) < 12 {
		return errors.New("file terlalu kecil untuk diverifikasi sebagai gambar yang valid")
	}

	mimeType := http.DetectContentType(buf)

	switch ext {
	case ".jpg", ".jpeg":
		if mimeType != "image/jpeg" {
			return fmt.Errorf("MIME type tidak sesuai (%s), wajib image/jpeg", mimeType)
		}
		if buf[0] != 0xFF || buf[1] != 0xD8 || buf[2] != 0xFF {
			return errors.New("header magic bytes JPEG tidak valid")
		}
	case ".png":
		if mimeType != "image/png" {
			return fmt.Errorf("MIME type tidak sesuai (%s), wajib image/png", mimeType)
		}
		if buf[0] != 0x89 || buf[1] != 0x50 || buf[2] != 0x4E || buf[3] != 0x47 {
			return errors.New("header magic bytes PNG tidak valid")
		}
	case ".webp":
		if buf[0] != 'R' || buf[1] != 'I' || buf[2] != 'F' || buf[3] != 'F' || buf[8] != 'W' || buf[9] != 'E' || buf[10] != 'B' || buf[11] != 'P' {
			return errors.New("header magic bytes WebP (RIFF/WEBP) tidak valid")
		}
	default:
		return errors.New("format file tidak didukung")
	}

	return nil
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

	// Validate MIME type & magic bytes strictly
	f, err := file.Open()
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal membaca header file gambar", err.Error())
	}
	buf := make([]byte, 512)
	n, _ := f.Read(buf)
	f.Close()

	if err := validateImageBytes(buf[:n], ext); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Verifikasi integritas gambar gagal: "+err.Error(), nil)
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

	// Validate MIME type & magic bytes strictly
	f, err := file.Open()
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal membaca header file avatar", err.Error())
	}
	buf := make([]byte, 512)
	n, _ := f.Read(buf)
	f.Close()

	if err := validateImageBytes(buf[:n], ext); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Verifikasi integritas avatar gagal: "+err.Error(), nil)
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

	// Persist avatar_url to the profile row. Swallowing a failure here is exactly
	// what makes a client report success while the old photo stays on screen: the
	// file lands on disk, the response carries a URL, and no profile ever points at
	// it. So a profile that was not updated is reported as a failure, and the file
	// that nothing references is removed instead of being left behind.
	claims, _ := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if claims == nil || claims.UserID == "" {
		_ = os.Remove(savePath)
		return response.Error(c, fiber.StatusUnauthorized, "Sesi tidak valid, foto profil tidak disimpan", nil)
	}
	if h.db == nil || h.db.Pool == nil {
		_ = os.Remove(savePath)
		return response.Error(c, fiber.StatusServiceUnavailable, "Database tidak terhubung, foto profil gagal disimpan", nil)
	}

	tag, err := h.db.Pool.Exec(c.Context(), `UPDATE public.profiles SET avatar_url = $1 WHERE id = $2`, publicURL, claims.UserID)
	if err != nil {
		_ = os.Remove(savePath)
		return response.Error(c, fiber.StatusInternalServerError, "Foto profil gagal disimpan ke database", err.Error())
	}
	if tag.RowsAffected() == 0 {
		_ = os.Remove(savePath)
		return response.Error(c, fiber.StatusNotFound, "Profil pengguna tidak ditemukan, foto profil gagal disimpan", nil)
	}

	return response.Success(c, fiber.StatusOK, "Avatar berhasil diupload", map[string]string{
		"file_name": newFilename,
		"url":       publicURL,
	})
}
