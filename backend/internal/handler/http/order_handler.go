package http

import (
	"fmt"
	"sync"
	"time"

	"github.com/gofiber/fiber/v2"
	"kantin-backend/internal/domain"
	"kantin-backend/internal/handler/http/middleware"
	"kantin-backend/internal/handler/websocket"
	"kantin-backend/internal/pkg/response"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/service"
)

var (
	presenceLock     sync.RWMutex
	orderPresenceMap = make(map[string]map[string]time.Time)
)

type OrderHandler struct {
	orderService *service.OrderService
	hub          *websocket.Hub
}

func NewOrderHandler(orderService *service.OrderService, hub *websocket.Hub) *OrderHandler {
	return &OrderHandler{
		orderService: orderService,
		hub:          hub,
	}
}

func (h *OrderHandler) CreateOrder(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	var req service.CreateOrderRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pesanan tidak valid", err.Error())
	}

	req.StudentID = claims.UserID
	req.StudentName = claims.FullName

	order, err := h.orderService.CreateOrder(c.Context(), req)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	// Broadcast Realtime Event to Canteen Stall Operator & Global room
	h.hub.BroadcastToRoom("all", "order:new", order)
	if order.OperatorID != nil {
		room := fmt.Sprintf("canteen:%s", *order.OperatorID)
		h.hub.BroadcastToRoom(room, "order:new", order)
	}

	return response.Success(c, fiber.StatusCreated, "Pesanan berhasil dibuat", order)
}

func (h *OrderHandler) ListStudentOrders(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orders, err := h.orderService.ListStudentOrders(c.Context(), claims.UserID)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil pesanan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar pesanan siswa", orders)
}

func (h *OrderHandler) ListOperatorOrders(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	status := c.Query("status", "")
	orders, err := h.orderService.ListOperatorOrders(c.Context(), claims.UserID, status)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil pesanan kasir", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar pesanan masuk", orders)
}

type UpdateStatusRequest struct {
	Status domain.OrderStatus `json:"status"`
}

func (h *OrderHandler) UpdateStatus(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")
	var req UpdateStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload status tidak valid", err.Error())
	}

	if err := h.orderService.UpdateOrderStatus(c.Context(), orderID, claims.UserID, claims.Role, req.Status); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Gagal memperbarui status pesanan: "+err.Error(), err.Error())
	}

	// Broadcast status update event
	h.hub.BroadcastToRoom("all", "order:status_updated", map[string]interface{}{
		"order_id": orderID,
		"status":   req.Status,
	})

	return response.Success(c, fiber.StatusOK, "Status pesanan berhasil diperbarui", nil)
}

func (h *OrderHandler) SendMessage(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")

	var msg domain.OrderMessage
	if err := c.BodyParser(&msg); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Payload pesan tidak valid", err.Error())
	}

	msg.OrderID = orderID
	msg.SenderID = claims.UserID
	roleStr := string(claims.Role)
	if claims.Role == domain.RolePetugasKantin {
		roleStr = "canteen_operator"
	} else if claims.Role == domain.RoleStudent {
		roleStr = "student"
	}
	msg.SenderRole = roleStr
	if msg.SenderName == "" {
		msg.SenderName = claims.FullName
	}

	savedMsg, err := h.orderService.SendMessage(c.Context(), &msg, claims.Role)
	if err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	// Broadcast chat message to order room
	room := fmt.Sprintf("order:%s", orderID)
	h.hub.BroadcastToRoom(room, "order:message", savedMsg)

	return response.Success(c, fiber.StatusCreated, "Pesan terkirim", savedMsg)
}

func (h *OrderHandler) GetMessages(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")
	messages, err := h.orderService.GetMessages(c.Context(), orderID, claims.UserID, claims.Role)
	if err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}
	return response.Success(c, fiber.StatusOK, "Percakapan pesanan", messages)
}

func (h *OrderHandler) MarkMessagesAsRead(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")
	if err := h.orderService.MarkMessagesAsRead(c.Context(), orderID, claims.UserID); err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal memperbarui status pesan", err.Error())
	}
	h.hub.BroadcastToRoom("all", "order:messages_read", map[string]interface{}{
		"order_id":  orderID,
		"reader_id": claims.UserID,
	})
	return response.Success(c, fiber.StatusOK, "Pesan ditandai telah dibaca", nil)
}

func (h *OrderHandler) UpdatePresence(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")

	roleStr := "student"
	if claims.Role == domain.RolePetugasKantin {
		roleStr = "canteen_operator"
	}

	presenceLock.Lock()
	if _, ok := orderPresenceMap[orderID]; !ok {
		orderPresenceMap[orderID] = make(map[string]time.Time)
	}
	orderPresenceMap[orderID][roleStr] = time.Now()
	presenceLock.Unlock()

	return h.GetPresence(c)
}

func (h *OrderHandler) GetPresence(c *fiber.Ctx) error {
	orderID := c.Params("id")
	now := time.Now()

	presenceLock.RLock()
	roleMap, ok := orderPresenceMap[orderID]
	activeRoles := make([]string, 0)
	if ok {
		for role, lastSeen := range roleMap {
			if now.Sub(lastSeen) < 15*time.Second {
				activeRoles = append(activeRoles, role)
			}
		}
	}
	presenceLock.RUnlock()

	return response.Success(c, fiber.StatusOK, "Active presence roles", activeRoles)
}

func (h *OrderHandler) SubmitReview(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")

	var req service.SubmitReviewRequest
	if err := c.BodyParser(&req); err != nil {
		return response.Error(c, fiber.StatusBadRequest, "Format ulasan tidak valid", err.Error())
	}

	review, err := h.orderService.SubmitReview(c.Context(), orderID, claims.UserID, claims.FullName, req)
	if err != nil {
		return response.Error(c, fiber.StatusBadRequest, err.Error(), nil)
	}

	// Broadcast review event
	h.hub.BroadcastToRoom("all", "order:reviewed", review)
	return response.Success(c, fiber.StatusOK, "Ulasan berhasil dikirim. Terima kasih!", review)
}

func (h *OrderHandler) GetReview(c *fiber.Ctx) error {
	orderID := c.Params("id")
	review, err := h.orderService.GetReviewByOrderID(c.Context(), orderID)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil ulasan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Ulasan pesanan", review)
}

func (h *OrderHandler) ListCanteenReviews(c *fiber.Ctx) error {
	canteenID := c.Params("id")
	reviews, err := h.orderService.ListCanteenReviews(c.Context(), canteenID)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil ulasan stan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar ulasan stan", reviews)
}
