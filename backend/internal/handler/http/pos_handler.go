package http

import (
	"strconv"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
	"kantin-backend/internal/service"
)

type POSHandler struct {
	paymentService *service.PaymentService
}

func NewPOSHandler(paymentService *service.PaymentService) *POSHandler {
	return &POSHandler{paymentService: paymentService}
}

func (h *POSHandler) ScanCard(c *fiber.Ctx) error {
	rfid := c.Query("rfid", "")
	if rfid == "" {
		rfid = c.Query("uid", "")
	}
	if rfid == "" {
		return response.Error(c, fiber.StatusBadRequest, "Nomor UID RFID kartu wajib disertakan", nil)
	}

	student, err := h.paymentService.GetStudentByRFID(c.Context(), rfid)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Kartu RFID tidak terdaftar pada sistem", nil)
	}

	if !student.IsActive {
		return response.Error(c, fiber.StatusForbidden, "Kartu RFID siswa ini sedang diblokir / dibekukan", nil)
	}

	return response.Success(c, fiber.StatusOK, "Data kartu siswa ditemukan", student)
}

type CheckoutRequest struct {
	StudentID      string                   `json:"student_id"`
	TotalAmount    int                      `json:"total_amount"`
	PurchaseMethod string                   `json:"purchase_method"`
	DeliveryLoc    string                   `json:"delivery_location"`
	Items          []domain.TransactionItem `json:"items"`
}

func (h *POSHandler) Checkout(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req CheckoutRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload checkout tidak valid", err.Error())
	}

	if req.StudentID == "" || req.TotalAmount <= 0 {
		return response.Error(c, fiber.StatusBadRequest, "Student ID dan total tagihan wajib valid", nil)
	}

	params := postgres.CheckoutParams{
		StudentID:      req.StudentID,
		OperatorID:     claims.UserID,
		TotalAmount:    req.TotalAmount,
		PurchaseMethod: req.PurchaseMethod,
		DeliveryLoc:    req.DeliveryLoc,
		Items:          req.Items,
	}

	tx, err := h.paymentService.ProcessPurchase(c.Context(), params)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	return response.Success(c, fiber.StatusOK, "Pembayaran berhasil diproses", tx)
}

func (h *POSHandler) SalesHistory(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "100")
	limit, _ := strconv.Atoi(limitStr)

	operatorID := claims.UserID
	if (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan) {
		if qOp := c.Query("operator_id"); qOp != "" {
			operatorID = qOp
		} else if qOff := c.Query("officer_id"); qOff != "" {
			operatorID = qOff
		}
	}

	transactions, err := h.paymentService.ListOperatorTransactions(c.Context(), operatorID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil riwayat transaksi", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Riwayat transaksi stan", transactions)
}

func (h *POSHandler) Activities(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	limitStr := c.Query("limit", "50")
	limit, _ := strconv.Atoi(limitStr)

	operatorID := claims.UserID
	if (claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin || claims.Role == domain.RolePetugasKeuangan) {
		if qOp := c.Query("operator_id"); qOp != "" {
			operatorID = qOp
		} else if qOff := c.Query("officer_id"); qOff != "" {
			operatorID = qOff
		}
	}

	activities, err := h.paymentService.ListOperatorActivities(c.Context(), operatorID, limit)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil aktivitas stan", err.Error())
	}

	return response.Success(c, fiber.StatusOK, "Aktivitas stan kantin", activities)
}
