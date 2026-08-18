package http

import (
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

type FinanceHandler struct {
	paymentService *service.PaymentService
}

func NewFinanceHandler(paymentService *service.PaymentService) *FinanceHandler {
	return &FinanceHandler{paymentService: paymentService}
}

func (h *FinanceHandler) Dashboard(c *fiber.Ctx) error {
	summary, err := h.paymentService.GetFinanceSummary(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat ringkasan keuangan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Ringkasan dasbor keuangan", summary)
}

func (h *FinanceHandler) ListStudents(c *fiber.Ctx) error {
	students, err := h.paymentService.ListAllStudents(c.Context())
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat daftar siswa", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar siswa", students)
}

func (h *FinanceHandler) History(c *fiber.Ctx) error {
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 50
	}

	offsetStr := c.Query("offset", "0")
	offset, _ := strconv.Atoi(offsetStr)

	txType := c.Query("type", "")
	status := c.Query("status", "")
	search := c.Query("search", "")

	txs, total, err := h.paymentService.ListTransactionsPaged(c.Context(), "", limit, offset, txType, status, search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat riwayat transaksi", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi keuangan", map[string]interface{}{
		"transactions": txs,
		"total":        total,
	})
}

type CorrectionRequest struct {
	StudentID string `json:"student_id"`
	Amount    int    `json:"amount"`
	Reason    string `json:"reason"`
}

func (h *FinanceHandler) Correction(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req CorrectionRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload koreksi tidak valid", err.Error())
	}

	if req.StudentID == "" || req.Amount == 0 {
		return response.Error(c, fiber.StatusBadRequest, "Student ID dan nominal koreksi wajib diisi", nil)
	}

	tx, err := h.paymentService.ProcessCorrection(c.Context(), req.StudentID, claims.UserID, req.Amount, req.Reason)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Koreksi saldo berhasil diproses", tx)
}

func (h *FinanceHandler) Report(c *fiber.Ctx) error {
	startStr := c.Query("start_date", "")
	endStr := c.Query("end_date", "")

	startDate := time.Now().AddDate(0, 0, -30)
	endDate := time.Now()

	if startStr != "" {
		if t, err := time.Parse(time.RFC3339, startStr); err == nil {
			startDate = t
		} else if t, err := time.Parse("2006-01-02", startStr); err == nil {
			startDate = t
		}
	}

	if endStr != "" {
		if t, err := time.Parse(time.RFC3339, endStr); err == nil {
			endDate = t
		} else if t, err := time.Parse("2006-01-02", endStr); err == nil {
			endDate = t.Add(23*time.Hour + 59*time.Minute + 59*time.Second)
		}
	}

	report, err := h.paymentService.GetFinanceReport(c.Context(), startDate, endDate)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat laporan keuangan", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Laporan keuangan", report)
}

type TopupRequest struct {
	StudentID string `json:"student_id"`
	Amount    int    `json:"amount"`
}

func (h *FinanceHandler) Topup(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req TopupRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload top-up tidak valid", err.Error())
	}

	if req.StudentID == "" || req.Amount <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Student ID dan nominal top-up wajib valid", nil)
	}

	tx, err := h.paymentService.ProcessTopup(c.Context(), req.StudentID, claims.UserID, req.Amount)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Top-up saldo berhasil", tx)
}
