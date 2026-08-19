package http

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	ws "kantin-backend/internal/handler/websocket"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

type AdminHandler struct {
	paymentService *service.PaymentService
	catalogService *service.CatalogService
	hub            *ws.Hub
}

func NewAdminHandler(paymentService *service.PaymentService, catalogService *service.CatalogService, hub ...*ws.Hub) *AdminHandler {
	var h *ws.Hub
	if len(hub) > 0 {
		h = hub[0]
	}
	return &AdminHandler{
		paymentService: paymentService,
		catalogService: catalogService,
		hub:            h,
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
	Relation    *string     `json:"relation"`
	StudentNISN *string     `json:"student_nisn"`
	CanteenName string      `json:"canteen_name"`
	RfidUID     *string     `json:"rfid_uid"`
	Class       *string     `json:"class"`
}

func (h *AdminHandler) CreateUser(c *fiber.Ctx) error {
	var req CreateUserRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pengguna tidak valid", err.Error())
	}

	if req.FullName == "" {
		return response.Error(c, fiber.StatusBadRequest, "Nama lengkap wajib diisi", nil)
	}

	// Default role to student if endpoint was /admin/students or role empty
	if req.Role == "" {
		req.Role = domain.RoleStudent
	}

	user := &domain.UserProfile{
		FullName:    req.FullName,
		Email:       req.Email,
		Username:    req.Username,
		Role:        req.Role,
		NISN:        req.NISN,
		PhoneNumber: req.PhoneNumber,
		Relation:    req.Relation,
		IsActive:    true,
	}

	if err := h.paymentService.CreateUser(c.Context(), user, req.Password, req.CanteenName, req.RfidUID, req.StudentNISN, req.Class); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menambahkan pengguna: "+err.Error(), err.Error())
	}

	return response.Success(c, fiber.StatusCreated, "Pengguna berhasil ditambahkan", user)
}

type UpdateUserStatusRequest struct {
	IsActive bool `json:"is_active"`
}

func (h *AdminHandler) UpdateStatus(c *fiber.Ctx) error {
	id := c.Params("id")
	var req UpdateUserStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}

	if err := h.paymentService.UpdateUserStatus(c.Context(), id, req.IsActive); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengubah status: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "account_status_changed", fiber.Map{
			"user_id":   id,
			"is_active": req.IsActive,
		})
		h.hub.BroadcastToRoom(id, "account_status_changed", fiber.Map{
			"user_id":   id,
			"is_active": req.IsActive,
		})
	}

	return response.Success(c, fiber.StatusOK, "Status pengguna berhasil diperbarui", nil)
}

type AdminChangePasswordRequest struct {
	UserID      string `json:"user_id"`
	NewPassword string `json:"new_password"`
}

func (h *AdminHandler) AdminChangePassword(c *fiber.Ctx) error {
	var req AdminChangePasswordRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}
	if req.UserID == "" || req.NewPassword == "" {
		return response.Error(c, fiber.StatusBadRequest, "User ID dan kata sandi baru wajib diisi", nil)
	}

	if err := h.paymentService.AdminChangePassword(c.Context(), req.UserID, req.NewPassword); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengubah kata sandi: "+err.Error(), err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Kata sandi berhasil diperbarui", nil)
}

type UpdateStudentRequest struct {
	FullName    string  `json:"full_name"`
	Email       *string `json:"email"`
	Username    *string `json:"username"`
	NISN        *string `json:"nisn"`
	PhoneNumber *string `json:"phone_number"`
	DailyLimit  *int    `json:"daily_limit"`
	RfidUID     *string `json:"rfid_uid"`
	Class       *string `json:"class"`
	IsActive    *bool   `json:"is_active"`
}

func (h *AdminHandler) UpdateStudent(c *fiber.Ctx) error {
	id := c.Params("id")
	var req UpdateStudentRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload update siswa tidak valid", err.Error())
	}

	params := postgres.UpdateStudentFullParams{
		ID:          id,
		FullName:    req.FullName,
		Email:       req.Email,
		Username:    req.Username,
		NISN:        req.NISN,
		PhoneNumber: req.PhoneNumber,
		DailyLimit:  req.DailyLimit,
		RfidUID:     req.RfidUID,
		Class:       req.Class,
		IsActive:    req.IsActive,
	}

	if err := h.paymentService.UpdateStudentFull(c.Context(), params); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui data siswa: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "student_updated", fiber.Map{"student_id": id})
		h.hub.BroadcastToRoom(id, "student_updated", fiber.Map{"student_id": id})
	}

	return response.Success(c, fiber.StatusOK, "Profil siswa berhasil diperbarui", nil)
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

func (h *AdminHandler) GetMerchantDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetMerchantDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data stan / operator tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail operator stan", detail)
}

func (h *AdminHandler) GetParentDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetParentDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data orang tua tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail orang tua", detail)
}

func (h *AdminHandler) GetFinanceDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetFinanceOfficerDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data petugas keuangan tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Detail petugas keuangan", detail)
}

func (h *AdminHandler) ListFinanceOfficersLedger(c *fiber.Ctx) error {
	list, err := h.paymentService.ListFinanceOfficersLedger(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat rekap pembukuan petugas keuangan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Rekap pembukuan kas petugas keuangan", list)
}

func (h *AdminHandler) GetFinanceOfficerLedgerDetail(c *fiber.Ctx) error {
	id := c.Params("id")
	detail, err := h.paymentService.GetFinanceOfficerLedgerDetail(c.Context(), id)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Detail buku kas petugas keuangan tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Buku kas dan jurnal transaksi petugas keuangan", detail)
}

func (h *AdminHandler) GetAcademicStructure(c *fiber.Ctx) error {
	structData, err := h.catalogService.GetAcademicStructure(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat master struktur akademik", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Master struktur akademik sekolah", structData)
}

func (h *AdminHandler) SaveAcademicStructure(c *fiber.Ctx) error {
	var req domain.AcademicStructure
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format master struktur akademik tidak valid", err.Error())
	}

	if err := h.catalogService.SaveAcademicStructure(c.Context(), &req); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan master struktur akademik: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "academic_structure_updated", req)
	}

	return response.Success(c, fiber.StatusOK, "Master struktur jenjang, jurusan, dan rombel sekolah berhasil disimpan", req)
}

func (h *AdminHandler) GetSettings(c *fiber.Ctx) error {
	settings, err := h.catalogService.GetGlobalSettings(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat setelan sistem", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Setelan sistem", settings)
}

func (h *AdminHandler) SaveSettings(c *fiber.Ctx) error {
	var req map[string]interface{}
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload setelan tidak valid", err.Error())
	}

	if err := h.catalogService.SaveGlobalSettings(c.Context(), req); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal menyimpan setelan: "+err.Error(), err.Error())
	}

	if h.hub != nil {
		h.hub.BroadcastToRoom("all", "system_settings_updated", req)
	}

	return response.Success(c, fiber.StatusOK, "Setelan sistem berhasil disimpan", req)
}
