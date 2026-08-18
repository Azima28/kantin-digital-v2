package http

import (
	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type CatalogHandler struct {
	catalogService *service.CatalogService
}

func NewCatalogHandler(catalogService *service.CatalogService) *CatalogHandler {
	return &CatalogHandler{catalogService: catalogService}
}

func (h *CatalogHandler) ListCanteens(c *fiber.Ctx) error {
	canteens, err := h.catalogService.ListCanteens(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil data stan", err.Error())
	}
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

func (h *CatalogHandler) CreateProduct(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var p domain.Product
	if err := c.BodyParser(&p); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload produk tidak valid", err.Error())
	}

	p.OperatorID = claims.UserID
	if p.Name == "" || p.Price <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Nama dan harga produk wajib diisi dengan benar", nil)
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
