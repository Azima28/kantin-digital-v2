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

	operatorID := c.Query("operator_id", "")
	studentID := c.Query("student_id", "")
	txs, total, err := h.paymentService.ListTransactionsPaged(c.Context(), studentID, operatorID, limit, offset, txType, status, search)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat riwayat transaksi", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi keuangan", map[string]interface{}{
		"transactions": txs,
		"total":        total,
	})
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

	if req.Amount < 10000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal top-up minimal Rp 10.000", nil)
	}

	if req.Amount > 2000000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal top-up maksimal Rp 2.000.000 per transaksi", nil)
	}

	tx, err := h.paymentService.ProcessTopup(c.Context(), req.StudentID, claims.UserID, req.Amount)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Top-up saldo berhasil", tx)
}

type MerchantWithdrawRequest struct {
	OperatorID string `json:"operator_id"`
	Amount     int    `json:"amount"`
	Notes      string `json:"notes"`
	Method     string `json:"method"`
}

func (h *FinanceHandler) MerchantWithdraw(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req MerchantWithdrawRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pencairan dana tidak valid", err.Error())
	}

	if req.OperatorID == "" || req.Amount <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Operator ID dan nominal pencairan wajib diisi", nil)
	}

	tx, err := h.paymentService.ProcessMerchantWithdrawal(c.Context(), req.OperatorID, claims.UserID, req.Amount, req.Notes, req.Method)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Pencairan dana stan berhasil diproses", tx)
}

// ── Sesi Shift Kasir (Continuous Shift Ledger) ──────────────────────────────

func (h *FinanceHandler) GetCurrentShift(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	summary, err := h.paymentService.GetCurrentShiftSummary(c.Context(), claims.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat sesi shift kasir", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Sesi shift kasir aktif", summary)
}

type CloseShiftRequest struct {
	ActualPhysicalCash int    `json:"actual_physical_cash"`
	Notes              string `json:"notes"`
}

func (h *FinanceHandler) CloseShift(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req CloseShiftRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload tutup kasir tidak valid", err.Error())
	}

	if req.ActualPhysicalCash < 0 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal fisik uang tidak boleh negatif", nil)
	}

	shift, err := h.paymentService.CloseCurrentShift(c.Context(), claims.UserID, req.ActualPhysicalCash, req.Notes)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Sesi shift kasir berhasil ditutup dan disetor", shift)
}

func (h *FinanceHandler) ListShiftHistory(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "20")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 20
	}
	offsetStr := c.Query("offset", "0")
	offset, _ := strconv.Atoi(offsetStr)

	shifts, total, err := h.paymentService.ListShifts(c.Context(), claims.UserID, limit, offset)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat riwayat sesi shift", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Riwayat sesi shift kasir", map[string]interface{}{
		"shifts": shifts,
		"total":  total,
	})
}

// ── Super Admin Shift Endpoints ────────────────────────────────────────────

func (h *FinanceHandler) AdminListAllShifts(c *fiber.Ctx) error {
	officerID := c.Query("officer_id", "")
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 {
		limit = 50
	}
	offsetStr := c.Query("offset", "0")
	offset, _ := strconv.Atoi(offsetStr)

	shifts, total, err := h.paymentService.ListShifts(c.Context(), officerID, limit, offset)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memuat daftar shift kasir", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Daftar seluruh sesi shift kasir", map[string]interface{}{
		"shifts": shifts,
		"total":  total,
	})
}

func (h *FinanceHandler) AdminVerifyShift(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	shiftID := c.Params("id", "")
	if shiftID == "" {
		return response.Error(c, fiber.StatusBadRequest, "ID shift wajib disertakan", nil)
	}

	shift, err := h.paymentService.VerifyShift(c.Context(), shiftID, claims.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Serah terima shift berhasil diverifikasi", shift)
}
