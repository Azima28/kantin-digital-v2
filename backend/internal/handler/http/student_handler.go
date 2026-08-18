package http

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type StudentHandler struct {
	paymentService *service.PaymentService
	notifService   *service.NotificationService
}

func NewStudentHandler(paymentService *service.PaymentService, notifService *service.NotificationService) *StudentHandler {
	return &StudentHandler{
		paymentService: paymentService,
		notifService:   notifService,
	}
}

func (h *StudentHandler) LookupStudent(c *fiber.Ctx) error {
	studentID := c.Query("id", "")
	if studentID == "" {
		studentID = c.Query("student_id", "")
	}
	if studentID != "" {
		student, err := h.paymentService.GetStudentDetail(c.Context(), studentID)
		if err != nil {
			return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
		}
		return response.Success(c, fiber.StatusOK, "Data detail siswa ditemukan", student)
	}

	search := c.Query("search", "")
	if search == "" {
		search = c.Query("q", "")
	}
	if search != "" {
		students, err := h.paymentService.SearchStudents(c.Context(), search)
		if err != nil {
			return response.Error(c, fiber.StatusInternalServerError, "Gagal mencari data siswa", err.Error())
		}
		return response.Success(c, fiber.StatusOK, "Hasil pencarian siswa", students)
	}

	nisn := c.Query("nisn", "")
	if nisn == "" {
		nisn = c.Query("nis", "")
	}
	if nisn == "" {
		return response.Error(c, fiber.StatusBadRequest, "NISN / Kode Siswa wajib disertakan", nil)
	}

	student, err := h.paymentService.GetStudentByNISN(c.Context(), nisn)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Data siswa ditemukan", student.Profile)
}

func (h *StudentHandler) GetMyProfile(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	student, err := h.paymentService.GetStudentDetail(c.Context(), claims.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Profil siswa", student)
}

func (h *StudentHandler) GetTransactions(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	targetStudentID := claims.UserID
	if (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan) && c.Query("student_id") != "" {
		targetStudentID = c.Query("student_id")
	}

	limitStr := c.Query("limit", "15")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 15
	}

	pageStr := c.Query("page", "1")
	page, _ := strconv.Atoi(pageStr)
	if page <= 0 {
		page = 1
	}

	offsetStr := c.Query("offset", "")
	var offset int
	if offsetStr != "" {
		offset, _ = strconv.Atoi(offsetStr)
	} else {
		offset = (page - 1) * limit
	}

	txType := c.Query("type", "")
	status := c.Query("status", "")
	search := c.Query("search", "")

	txs, total, err := h.paymentService.ListStudentTransactionsPaged(c.Context(), targetStudentID, limit, offset, txType, status, search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil riwayat", err.Error())
	}

	hasMore := (offset + len(txs)) < total

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi siswa", fiber.Map{
		"items":    txs,
		"total":    total,
		"limit":    limit,
		"offset":   offset,
		"page":     page,
		"has_more": hasMore,
	})
}

func (h *StudentHandler) GetNotifications(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	notifs, err := h.notifService.ListByStudent(c.Context(), claims.UserID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Notifikasi siswa", notifs)
}

func (h *StudentHandler) MarkNotificationRead(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	notifID := c.Params("id")

	if err := h.notifService.MarkAsRead(c.Context(), notifID, claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Notifikasi ditandai dibaca", nil)
}

func (h *StudentHandler) MarkAllNotificationsRead(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if err := h.notifService.MarkAllAsRead(c.Context(), claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui notifikasi", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Semua notifikasi ditandai dibaca", nil)
}

type UpdateCardStatusRequest struct {
	StudentID string  `json:"student_id"`
	RfidUID   *string `json:"rfid_uid"`
	IsActive  *bool   `json:"is_active"`
}

func (h *StudentHandler) UpdateCardStatus(c *fiber.Ctx) error {
	var req UpdateCardStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tidak valid", err.Error())
	}
	if req.StudentID == "" {
		return response.Error(c, fiber.StatusBadRequest, "Student ID wajib diisi", nil)
	}

	if err := h.paymentService.UpdateStudentCardStatus(c.Context(), req.StudentID, req.RfidUID, req.IsActive); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui status kartu: "+err.Error(), err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Status kartu berhasil diperbarui", nil)
}
