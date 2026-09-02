package http

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type CatalogHandler struct {
	catalogService *service.CatalogService
	tokenMaker     *token.TokenMaker
}

func NewCatalogHandler(catalogService *service.CatalogService, tokenMaker ...*token.TokenMaker) *CatalogHandler {
	var tm *token.TokenMaker
	if len(tokenMaker) > 0 {
		tm = tokenMaker[0]
	}
	return &CatalogHandler{catalogService: catalogService, tokenMaker: tm}
}

// resolveOptionalClaims performs best-effort authentication on public endpoints.
// Returns nil when no credential is presented or the token is invalid, instead of
// rejecting the request, so anonymous visitors still receive the sanitized payload.
func (h *CatalogHandler) resolveOptionalClaims(c *fiber.Ctx) *token.JWTClaims {
	if claimsVal := c.Locals(middleware.UserClaimsKey); claimsVal != nil {
		if claims, ok := claimsVal.(*token.JWTClaims); ok {
			return claims
		}
	}
	if h.tokenMaker == nil {
		return nil
	}

	tokenStr := ""
	if fields := strings.Fields(c.Get(middleware.AuthorizationHeader)); len(fields) >= 2 && strings.EqualFold(fields[0], middleware.AuthorizationType) {
		tokenStr = fields[1]
	}
	if tokenStr == "" {
		tokenStr = c.Cookies("access_token")
	}
	if tokenStr == "" {
		return nil
	}

	claims, err := h.tokenMaker.VerifyToken(tokenStr)
	if err != nil || claims == nil {
		return nil
	}
	return claims
}

// sanitizeCanteenList strips operator PII (email, username, phone number,
// gender, created_at) and merchant revenue (balance_earned) from the stall
// directory. Only authorized staff see the full records; a canteen operator
// keeps the full record for their own stall. Anonymous callers (claims == nil)
// are always sanitized.
func sanitizeCanteenList(canteens []domain.CanteenOperator, claims *token.JWTClaims) []domain.CanteenOperator {
	isStaff := false
	isOperator := false
	viewerID := ""
	if claims != nil {
		viewerID = claims.UserID
		switch claims.Role {
		case domain.RoleSuperAdmin, domain.RoleAdmin, domain.RolePetugasKeuangan:
			isStaff = true
		case domain.RolePetugasKantin:
			isOperator = true
		}
	}

	if isStaff {
		return canteens
	}

	for i := range canteens {
		// A canteen operator keeps the full record for their own stall only.
		if isOperator && viewerID != "" && strings.EqualFold(canteens[i].ID, viewerID) {
			continue
		}
		canteens[i].BalanceEarned = 0
		if p := canteens[i].Profile; p != nil {
			canteens[i].Profile = &domain.UserProfile{
				ID:        p.ID,
				FullName:  p.FullName,
				Role:      p.Role,
				IsActive:  p.IsActive,
				AvatarURL: p.AvatarURL,
			}
		}
	}
	return canteens
}

// ListCanteens serves the public stall directory. The underlying query joins
// public.profiles, so the raw rows carry operator PII (email, username, phone
// number, gender) and merchant revenue (balance_earned). Those fields are
// stripped for every requester that is not the stall owner or authorized staff,
// preventing anonymous enumeration of operator accounts.
func (h *CatalogHandler) ListCanteens(c *fiber.Ctx) error {
	canteens, err := h.catalogService.ListCanteens(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil data stan", err.Error())
	}

	canteens = sanitizeCanteenList(canteens, h.resolveOptionalClaims(c))
	return response.Success(c, fiber.StatusOK, "Daftar stan kantin", canteens)
}

type UpdateDeliveryRequest struct {
	IsDeliveryEnabled bool `json:"is_delivery_enabled"`
	DeliveryFee       int  `json:"delivery_fee"`
}

func (h *CatalogHandler) UpdateDelivery(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req UpdateDeliveryRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}

	if req.DeliveryFee < 0 {
		return response.Error(c, fiber.StatusBadRequest, "Biaya ongkir tidak boleh negatif", nil)
	}

	if err := h.catalogService.UpdateDeliverySettings(c.Context(), claims.UserID, req.IsDeliveryEnabled, req.DeliveryFee); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui pengaturan delivery", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Pengaturan delivery berhasil disimpan", nil)
}

func (h *CatalogHandler) ListProducts(c *fiber.Ctx) error {
	category := c.Query("category", "")
	canteenID := c.Query("canteen_id", "")
	if canteenID == "" {
		canteenID = c.Query("canteenId", "")
	}
	search := c.Query("search", "")

	products, err := h.catalogService.ListProducts(c.Context(), category, canteenID, search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil data produk", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Katalog produk kantin", products)
}

func sanitizeString(s string) string {
	s = strings.TrimSpace(s)
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

func sanitizeCategory(cat string) string {
	clean := strings.ToLower(strings.TrimSpace(cat))
	switch clean {
	case "makanan", "minuman", "camilan", "snack", "lainnya":
		if clean == "snack" {
			return "camilan"
		}
		return clean
	default:
		return "makanan"
	}
}

func (h *CatalogHandler) CreateProduct(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var p domain.Product
	if err := c.BodyParser(&p); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload produk tidak valid", err.Error())
	}

	p.OperatorID = claims.UserID
	p.Name = sanitizeString(p.Name)
	if p.Name == "" || p.Price <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Nama dan harga produk wajib diisi dengan benar", nil)
	}
	if len(p.Name) > 80 {
		p.Name = p.Name[:80]
	}
	p.Category = sanitizeCategory(p.Category)
	if p.Price < 100 || p.Price > 10000000 {
		return response.Error(c, fiber.StatusBadRequest, "Harga produk harus antara Rp 100 hingga Rp 10.000.000", nil)
	}

	if err := h.catalogService.CreateProduct(c.Context(), &p); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menambahkan produk", err.Error())
	}

	return response.Success(c, fiber.StatusCreated, "Produk berhasil ditambahkan", p)
}

func (h *CatalogHandler) UpdateProduct(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	productID := c.Params("id")
	var p domain.Product
	if err := c.BodyParser(&p); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload produk tidak valid", err.Error())
	}

	p.ID = productID
	p.OperatorID = claims.UserID
	if p.Name != "" {
		p.Name = sanitizeString(p.Name)
		if len(p.Name) > 80 {
			p.Name = p.Name[:80]
		}
	}
	if p.Category != "" {
		p.Category = sanitizeCategory(p.Category)
	}
	if p.Price != 0 && (p.Price < 100 || p.Price > 10000000) {
		return response.Error(c, fiber.StatusBadRequest, "Harga produk harus antara Rp 100 hingga Rp 10.000.000", nil)
	}

	if err := h.catalogService.UpdateProduct(c.Context(), &p); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui produk", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Produk berhasil diperbarui", p)
}

func (h *CatalogHandler) UpdateAvailability(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	productID := c.Params("id")
	var req struct {
		IsAvailable bool `json:"is_available"`
	}
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload status ketersediaan tidak valid", err.Error())
	}

	if err := h.catalogService.UpdateAvailability(c.Context(), productID, claims.UserID, req.IsAvailable); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui status ketersediaan produk", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Status ketersediaan berhasil diperbarui", map[string]interface{}{
		"id":           productID,
		"is_available": req.IsAvailable,
	})
}

func (h *CatalogHandler) DeleteProduct(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	productID := c.Params("id")

	if err := h.catalogService.DeleteProduct(c.Context(), productID, claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menghapus produk", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Produk berhasil dihapus", nil)
}

func (h *CatalogHandler) GetPublicAcademicStructure(c *fiber.Ctx) error {
	structData, err := h.catalogService.GetAcademicStructure(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat struktur akademik", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Master struktur akademik sekolah", structData)
}
