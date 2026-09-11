package http

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
	"kantin-backend/internal/handler/websocket"
)

type FinanceHandler struct {
	paymentService *service.PaymentService
	hub            *websocket.Hub
}

func NewFinanceHandler(paymentService *service.PaymentService, hub *websocket.Hub) *FinanceHandler {
	return &FinanceHandler{paymentService: paymentService, hub: hub}
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

func parseReportDate(dateStr string, isEndOfDay bool) (time.Time, bool) {
	dateStr = strings.TrimSpace(dateStr)
	if dateStr == "" {
		return time.Time{}, false
	}

	formats := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.999999999",
		"2006-01-02T15:04:05.999",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}

	for _, format := range formats {
		if t, err := time.ParseInLocation(format, dateStr, time.Local); err == nil {
			if isEndOfDay {
				// If date has no time or is midnight, set to very end of that day
				if format == "2006-01-02" || (t.Hour() == 0 && t.Minute() == 0 && t.Second() == 0) {
					return time.Date(t.Year(), t.Month(), t.Day(), 23, 59, 59, 999999999, t.Location()), true
				}
			} else {
				if format == "2006-01-02" {
					return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location()), true
				}
			}
			return t, true
		}
	}
	return time.Time{}, false
}

func (h *FinanceHandler) Report(c *fiber.Ctx) error {
	startStr := c.Query("start_date", "")
	endStr := c.Query("end_date", "")

	startDate := time.Now().AddDate(0, 0, -30)
	endDate := time.Now()

	if t, ok := parseReportDate(startStr, false); ok {
		startDate = t
	}

	if t, ok := parseReportDate(endStr, true); ok {
		endDate = t
	}

	if startDate.After(endDate) {
		startDate, endDate = endDate, startDate
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
	if claims.Role != domain.RolePetugasKeuangan && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Hanya Petugas Keuangan atau Administrator yang berwenang memproses top-up tunai", nil)
	}

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

	actorName := claims.Email
	if claims.FullName != "" {
		actorName = claims.FullName
	}
	studentName := ""
	if tx.StudentName != nil {
		studentName = *tx.StudentName
	}
	balBefore := 0
	if tx.BalanceBefore != nil {
		balBefore = *tx.BalanceBefore
	}
	balAfter := balBefore + req.Amount
	if tx.BalanceAfter != nil {
		balAfter = *tx.BalanceAfter
	}

	// A cash top-up creates balance out of nothing as far as the database is
	// concerned, so who did it, for whom, and from where has to be recorded.
	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "STUDENT_TOPUP", "students", req.StudentID,
		auditJSON(map[string]interface{}{
			"balance":        balBefore,
			"balance_before": balBefore,
			"status":         "Aktif",
		}),
		auditJSON(map[string]interface{}{
			"amount":         req.Amount,
			"total_amount":   req.Amount,
			"balance":        balAfter,
			"balance_before": balBefore,
			"balance_after":  balAfter,
			"transaction_id": tx.ID,
			"actor_role":     claims.Role,
			"actor_name":     actorName,
			"student_name":   studentName,
			"method":         "cash",
			"status":         "Sukses",
		}), c.IP())

	return response.Success(c, fiber.StatusOK, "Top-up saldo berhasil", tx)
}

type CorrectionRequest struct {
	StudentID string `json:"student_id"`
	Amount    int    `json:"amount"`
	Type      string `json:"type"` // "add" or "deduct"
	Reason    string `json:"reason"`
}

func (h *FinanceHandler) Correction(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if claims.Role != domain.RolePetugasKeuangan && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Hanya Petugas Keuangan atau Administrator yang berwenang memproses koreksi saldo", nil)
	}

	var req CorrectionRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload koreksi saldo tidak valid", err.Error())
	}

	req.StudentID = strings.TrimSpace(req.StudentID)
	req.Reason = strings.TrimSpace(req.Reason)
	req.Type = strings.TrimSpace(strings.ToLower(req.Type))

	if req.StudentID == "" {
		return response.Error(c, fiber.StatusBadRequest, "Student ID wajib diisi", nil)
	}

	if req.Reason == "" {
		return response.Error(c, fiber.StatusBadRequest, "Alasan koreksi saldo wajib diisi", nil)
	}

	// Support direction via Type ("deduct" / "add") or via signed Amount
	delta := req.Amount
	if req.Type == "deduct" || req.Type == "pengurangan" || req.Type == "sub" {
		if delta > 0 {
			delta = -delta
		}
	} else if req.Type == "add" || req.Type == "penambahan" {
		if delta < 0 {
			delta = -delta
		}
	}

	if delta == 0 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal koreksi saldo tidak boleh nol", nil)
	}

	absAmount := delta
	if absAmount < 0 {
		absAmount = -absAmount
	}

	if absAmount < 1000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal koreksi saldo minimal Rp 1.000", nil)
	}

	if absAmount > 2000000 {
		return response.Error(c, fiber.StatusBadRequest, "Nominal koreksi saldo maksimal Rp 2.000.000 per transaksi", nil)
	}

	tx, err := h.paymentService.ProcessCorrection(c.Context(), req.StudentID, claims.UserID, delta, req.Reason)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	actorName := claims.Email
	if claims.FullName != "" {
		actorName = claims.FullName
	}
	studentName := ""
	if tx.StudentName != nil {
		studentName = *tx.StudentName
	}
	balBefore := 0
	if tx.BalanceBefore != nil {
		balBefore = *tx.BalanceBefore
	}
	balAfter := 0
	if tx.BalanceAfter != nil {
		balAfter = *tx.BalanceAfter
	}

	actionDirection := "PENAMBAHAN"
	if delta < 0 {
		actionDirection = "PENGURANGAN"
	}

	_ = h.paymentService.LogAudit(c.Context(), claims.UserID, "BALANCE_CORRECTION", "students", req.StudentID,
		auditJSON(map[string]interface{}{
			"balance":        balBefore,
			"balance_before": balBefore,
			"status":         "Aktif",
		}),
		auditJSON(map[string]interface{}{
			"amount":         delta,
			"abs_amount":     absAmount,
			"direction":      actionDirection,
			"reason":         req.Reason,
			"balance":        balAfter,
			"balance_before": balBefore,
			"balance_after":  balAfter,
			"transaction_id": tx.ID,
			"actor_role":     claims.Role,
			"actor_name":     actorName,
			"student_name":   studentName,
			"status":         "Sukses",
		}), c.IP())

	if h.hub != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", req.StudentID), "balance:updated", fiber.Map{
			"student_id":     req.StudentID,
			"balance":        balAfter,
			"delta":          delta,
			"abs_amount":     absAmount,
			"reason":         req.Reason,
			"transaction_id": tx.ID,
		})
		h.hub.BroadcastToRoom(req.StudentID, "balance:updated", fiber.Map{
			"student_id":     req.StudentID,
			"balance":        balAfter,
			"delta":          delta,
			"abs_amount":     absAmount,
			"reason":         req.Reason,
			"transaction_id": tx.ID,
		})
		h.hub.BroadcastToRoom("all", "balance:updated", fiber.Map{
			"student_id": req.StudentID,
		})
	}

	return response.Success(c, fiber.StatusOK, "Koreksi saldo berhasil diproses", tx)
}

type MerchantWithdrawRequest struct {
	OperatorID string `json:"operator_id"`
	Amount     int    `json:"amount"`
	Notes      string `json:"notes"`
	Method     string `json:"method"`
}

func (h *FinanceHandler) MerchantWithdraw(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	if claims.Role != domain.RolePetugasKeuangan && claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin {
		return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Hanya Petugas Keuangan atau Administrator yang berwenang memproses penarikan dana stan", nil)
	}

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
