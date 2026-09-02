package http

import (
	"fmt"
	"strings"
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

	// Broadcast Realtime Event to targeted Canteen Stall Operator & Student rooms
	if order.OperatorID != nil {
		room := fmt.Sprintf("canteen:%s", *order.OperatorID)
		h.hub.BroadcastToRoom(room, "order:new", order)
	}
	studentRoom := fmt.Sprintf("student:%s", order.StudentID)
	h.hub.BroadcastToRoom(studentRoom, "order:new", order)

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

func (h *OrderHandler) GetOrderByID(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")
	order, err := h.orderService.GetOrderByID(c.Context(), orderID)
	if err != nil {
		return response.Error(c, fiber.StatusNotFound, "Pesanan tidak ditemukan", err.Error())
	}

	// Verify participant authorization
	if claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin && claims.Role != domain.RolePetugasKeuangan {
		isStudent := claims.Role == domain.RoleStudent && strings.EqualFold(claims.UserID, order.StudentID)
		isOperator := claims.Role == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, claims.UserID)
		if !isStudent && !isOperator {
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda bukan partisipan dalam pesanan ini", nil)
		}
	}

	return response.Success(c, fiber.StatusOK, "Detail pesanan", order)
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

	// Broadcast status update event strictly to order and participant rooms
	statusPayload := map[string]interface{}{
		"order_id": orderID,
		"status":   req.Status,
	}
	h.hub.BroadcastToRoom(fmt.Sprintf("order:%s", orderID), "order:status_updated", statusPayload)

	order, _ := h.orderService.GetOrderByID(c.Context(), orderID)
	if order != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", order.StudentID), "order:status_updated", statusPayload)
		if order.OperatorID != nil {
			h.hub.BroadcastToRoom(fmt.Sprintf("canteen:%s", *order.OperatorID), "order:status_updated", statusPayload)
		}
	}

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
	} else if claims.Role == domain.RolePetugasKeuangan || claims.Role == domain.RoleSuperAdmin || claims.Role == domain.RoleAdmin {
		roleStr = "admin"
	}
	msg.SenderRole = roleStr
	if msg.SenderName == "" {
		msg.SenderName = claims.FullName
	}

	savedMsg, err := h.orderService.SendMessage(c.Context(), &msg, claims.Role)
	if err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}

	// Broadcast chat message strictly to the order room and participant rooms
	h.hub.BroadcastToRoom(fmt.Sprintf("order:%s", orderID), "order:message", savedMsg)
	order, _ := h.orderService.GetOrderByID(c.Context(), orderID)
	if order != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", order.StudentID), "order:message", savedMsg)
		if order.OperatorID != nil {
			h.hub.BroadcastToRoom(fmt.Sprintf("canteen:%s", *order.OperatorID), "order:message", savedMsg)
		}
	}

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
	if err := h.orderService.MarkMessagesAsRead(c.Context(), orderID, claims.UserID, claims.Role); err != nil {
		return response.Error(c, fiber.StatusForbidden, err.Error(), nil)
	}
	readPayload := map[string]interface{}{
		"order_id":  orderID,
		"reader_id": claims.UserID,
	}
	h.hub.BroadcastToRoom(fmt.Sprintf("order:%s", orderID), "order:messages_read", readPayload)
	order, _ := h.orderService.GetOrderByID(c.Context(), orderID)
	if order != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("student:%s", order.StudentID), "order:messages_read", readPayload)
		if order.OperatorID != nil {
			h.hub.BroadcastToRoom(fmt.Sprintf("canteen:%s", *order.OperatorID), "order:messages_read", readPayload)
		}
	}
	return response.Success(c, fiber.StatusOK, "Pesan ditandai telah dibaca", nil)
}

func (h *OrderHandler) UpdatePresence(c *fiber.Ctx) error {
	claims := c.Locals(middleware.UserClaimsKey).(*token.JWTClaims)
	orderID := c.Params("id")

	order, err := h.orderService.GetOrderByID(c.Context(), orderID)
	if err != nil || order == nil {
		return response.Error(c, fiber.StatusNotFound, "Pesanan tidak ditemukan", nil)
	}

	if claims.Role != domain.RoleSuperAdmin && claims.Role != domain.RoleAdmin && claims.Role != domain.RolePetugasKeuangan {
		isStudent := claims.Role == domain.RoleStudent && strings.EqualFold(claims.UserID, order.StudentID)
		isOperator := claims.Role == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, claims.UserID)
		if !isStudent && !isOperator {
			return response.Error(c, fiber.StatusForbidden, "Akses ditolak: Anda bukan partisipan dalam pesanan ini", nil)
		}
	}

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

	presencePayload := map[string]interface{}{
		"order_id": orderID,
		"role":     roleStr,
	}
	h.hub.BroadcastToRoom(fmt.Sprintf("order:%s", orderID), "order:presence", presencePayload)

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

// sanitizeReviewForBroadcast returns a copy of a review that is safe to push over
// the WebSocket. SubmitReview builds the review from the caller's own JWT, so the
// object it returns always carries the reviewer's real student_id and full name --
// correct for the HTTP response that goes straight back to that student, but the
// very same object is also broadcast to the order room and to the stall's operator
// room. When the student asked to stay anonymous, every handle that leads back to
// them is dropped here, so the realtime event cannot undo the anonymity that the
// public reviews endpoint already enforces. order_id goes too: for the order room
// it is redundant (the room name carries it) and for the stall room it is exactly
// the correlation handle that would name the buyer.
func sanitizeReviewForBroadcast(rev *domain.OrderReview) *domain.OrderReview {
	if rev == nil || !rev.IsAnonymous {
		return rev
	}
	safe := *rev
	safe.StudentName = "Siswa (Anonim)"
	safe.AvatarURL = nil
	safe.StudentID = ""
	safe.OrderID = ""
	return &safe
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

	// Broadcast review event strictly to the order room and the canteen stall room,
	// with the reviewer's identity stripped when the review is anonymous.
	broadcast := sanitizeReviewForBroadcast(review)
	h.hub.BroadcastToRoom(fmt.Sprintf("order:%s", orderID), "order:reviewed", broadcast)
	if review.OperatorID != nil {
		h.hub.BroadcastToRoom(fmt.Sprintf("canteen:%s", *review.OperatorID), "order:reviewed", broadcast)
	}
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
	productID := c.Query("product_id", "")
	reviews, err := h.orderService.ListCanteenReviews(c.Context(), canteenID, productID)
	if err != nil {
		return response.Error(c, fiber.StatusInternalServerError, "Gagal mengambil ulasan stan", err.Error())
	}
	return response.Success(c, fiber.StatusOK, "Daftar ulasan stan", reviews)
}
