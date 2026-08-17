package http

import (
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
