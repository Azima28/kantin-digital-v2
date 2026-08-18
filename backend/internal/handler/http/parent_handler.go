package http

import (
	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type ParentHandler struct {
	paymentService *service.PaymentService
}

func NewParentHandler(paymentService *service.PaymentService) *ParentHandler {
	return &ParentHandler{paymentService: paymentService}
}

func (h *ParentHandler) Dashboard(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	studentID := c.Params("studentId")

	// Verify parent relation if caller is parent
	if claims.Role == "parent" {
		children, err := h.paymentService.GetParentChildren(c.Context(), claims.UserID)
		if err != nil {
			return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat relasi anak", err.Error())
		}
		isLinked := false
		for _, child := range children {
			if child.ID == studentID {
				isLinked = true
				break
			}
		}
		if !isLinked && len(children) > 0 {
			studentID = children[0].ID
		}
	}

	student, err := h.paymentService.GetStudentDetail(c.Context(), studentID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Data siswa tidak ditemukan", err.Error())
	}

	txs, _ := h.paymentService.ListStudentTransactions(c.Context(), studentID, 30)
	stats, _ := h.paymentService.GetStudentSpendingStats(c.Context(), studentID)

	return response.Success(c, fiber.StatusOK, "Dasbor orang tua", map[string]interface{}{
		"student":           student,
		"profile":           student.Profile,
		"transactions":      txs,
		"weekly_spending":   stats.WeeklySpending,
		"favorite_products": stats.FavoriteProducts,
	})
}

type UpdateStudentSettingsRequest struct {
	StudentID   string  `json:"student_id"`
	DailyLimit  *int    `json:"daily_limit"`
	IsActive    *bool   `json:"is_active"`
	WaEnabled   *bool   `json:"wa_notifications_enabled"`
	ParentPhone *string `json:"parent_phone"`
}

func (h *ParentHandler) UpdateStudentSettings(c *fiber.Ctx) error {
	var req UpdateStudentSettingsRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pengaturan siswa tidak valid", err.Error())
	}

	if req.StudentID == "" {
		return response.Error(c, fiber.StatusBadRequest, "Student ID wajib disertakan", nil)
	}

	if err := h.paymentService.UpdateStudentSettings(c.Context(), req.StudentID, req.DailyLimit, req.IsActive, req.WaEnabled, req.ParentPhone); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui pengaturan siswa", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Pengaturan siswa berhasil disimpan", nil)
}
