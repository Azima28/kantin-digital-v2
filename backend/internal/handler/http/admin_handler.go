package http

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/service"
)

type AdminHandler struct {
	paymentService *service.PaymentService
	catalogService *service.CatalogService
}

func NewAdminHandler(paymentService *service.PaymentService, catalogService *service.CatalogService) *AdminHandler {
	return &AdminHandler{
		paymentService: paymentService,
		catalogService: catalogService,
	}
}

func (h *AdminHandler) Dashboard(c *fiber.Ctx) error {
	summary, err := h.paymentService.GetAdminSummary(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat ringkasan admin", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Ringkasan dasbor admin", summary)
}

func (h *AdminHandler) ListUsers(c *fiber.Ctx) error {
	role := c.Query("role", "")
	users, err := h.paymentService.ListAllUsers(c.Context(), role)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat daftar pengguna", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar pengguna", users)
}

type CreateUserRequest struct {
	FullName    string      `json:"full_name"`
	Email       *string     `json:"email"`
	Username    *string     `json:"username"`
	Password    string      `json:"password"`
	Role        domain.Role `json:"role"`
	NISN        *string     `json:"nisn"`
	PhoneNumber *string     `json:"phone_number"`
	CanteenName string      `json:"canteen_name"`
	RfidUID     *string     `json:"rfid_uid"`
}

func (h *AdminHandler) CreateUser(c *fiber.Ctx) error {
	var req CreateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pengguna tidak valid", err.Error())
	}

	if req.FullName == "" || req.Role == "" {
		return response.Error(c, fiber.StatusBadRequest, "Nama lengkap dan role wajib diisi", nil)
	}

	user := &domain.UserProfile{
		FullName:    req.FullName,
		Email:       req.Email,
		Username:    req.Username,
		Role:        req.Role,
		NISN:        req.NISN,
		PhoneNumber: req.PhoneNumber,
		IsActive:    true,
	}

	if err := h.paymentService.CreateUser(c.Context(), user, req.Password, req.CanteenName, req.RfidUID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menambahkan pengguna: "+err.Error(), err.Error())
	}

	return response.Success(c, fiber.StatusCreated, "Pengguna berhasil ditambahkan", user)
}

func (h *AdminHandler) UpdateUser(c *fiber.Ctx) error {
	id := c.Params("id")
	var req domain.UserProfile
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update tidak valid", err.Error())
	}

	req.ID = id
	if err := h.paymentService.UpdateUser(c.Context(), &req); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui pengguna", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Pengguna berhasil diperbarui", req)
}

func (h *AdminHandler) DeleteUser(c *fiber.Ctx) error {
	id := c.Params("id")
	if err := h.paymentService.DeleteUser(c.Context(), id); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menghapus pengguna", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Pengguna berhasil dihapus", nil)
}

func (h *AdminHandler) ListAuditLogs(c *fiber.Ctx) error {
	limitStr := c.Query("limit", "100")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 100
	}

	logs, err := h.paymentService.ListAllAuditLogs(c.Context(), limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat log audit", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Log audit sistem", logs)
}

func (h *AdminHandler) GetStudentDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	student, err := h.paymentService.GetStudentDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	txs, _ := h.paymentService.ListStudentTransactions(c.Context(), id, 50)
	return response.Success(c, fiber.StatusOK, "Detail siswa", map[string]interface{}{
		"student":      student,
		"profile":      student.Profile,
		"transactions": txs,
	})
}
