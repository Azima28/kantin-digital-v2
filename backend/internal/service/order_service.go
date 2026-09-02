package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/repository/postgres"
)

type OrderService struct {
	orderRepo *postgres.OrderRepo
}

func NewOrderService(orderRepo *postgres.OrderRepo) *OrderService {
	return &OrderService{orderRepo: orderRepo}
}

type CreateOrderRequest struct {
	StudentID        string             `json:"student_id"`
	StudentName      string             `json:"student_name"`
	OperatorID       *string            `json:"operator_id"`
	DeliveryLocation *string            `json:"delivery_location"`
	TotalAmount      int                `json:"total_amount"`
	Items            []domain.OrderItem `json:"items"`
}

func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderRequest) (*domain.Order, error) {
	if len(req.Items) == 0 {
		return nil, errors.New("pesanan harus memiliki setidaknya 1 item")
	}

	order := &domain.Order{
		StudentID:        req.StudentID,
		StudentName:      req.StudentName,
		OperatorID:       req.OperatorID,
		Status:           domain.OrderStatusBaru,
		DeliveryLocation: req.DeliveryLocation,
		TotalAmount:      req.TotalAmount,
	}

	return s.orderRepo.CreateOrder(ctx, order, req.Items)
}

func (s *OrderService) GetOrderByID(ctx context.Context, orderID string) (*domain.Order, error) {
	return s.orderRepo.GetOrderByID(ctx, orderID)
}

func (s *OrderService) ListStudentOrders(ctx context.Context, studentID string) ([]domain.Order, error) {
	return s.orderRepo.ListOrdersByStudent(ctx, studentID)
}

func (s *OrderService) ListOperatorOrders(ctx context.Context, operatorID, status string) ([]domain.Order, error) {
	return s.orderRepo.ListOrdersByOperator(ctx, operatorID, status)
}

func (s *OrderService) UpdateOrderStatus(ctx context.Context, orderID, callerUserID string, callerRole domain.Role, newStatus domain.OrderStatus) error {
	order, err := s.orderRepo.GetOrderByID(ctx, orderID)
	if err != nil {
		return err
	}

	// Verify merchant ownership strictly for canteen operators
	if callerRole == domain.RolePetugasKantin {
		if order.OperatorID == nil || !strings.EqualFold(*order.OperatorID, callerUserID) {
			return errors.New("akses ditolak: pesanan ini bukan milik stan Anda")
		}
	} else if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
		return errors.New("akses ditolak: Anda tidak memiliki wewenang untuk mengubah status pesanan")
	}

	// Validate the requested move against the order state machine. Reaching
	// Selesai releases the escrow to the stall and reaching Dibatalkan refunds
	// the student, so a settled order must never be re-opened: without this,
	// PATCHing Selesai -> Baru -> Selesai pays the stall again on every lap.
	// The repository re-checks this inside its FOR UPDATE transaction; that is
	// the authoritative layer, this one exists to return a readable error.
	if !domain.IsValidOrderStatus(newStatus) {
		return fmt.Errorf("status pesanan tidak dikenal: %s", newStatus)
	}
	if domain.IsTerminalOrderStatus(order.Status) && newStatus != order.Status {
		return fmt.Errorf("pesanan sudah %s dan tidak dapat diubah lagi", order.Status)
	}
	if !domain.CanTransitionOrderStatus(order.Status, newStatus) {
		return fmt.Errorf("perubahan status dari %s ke %s tidak diizinkan", order.Status, newStatus)
	}

	return s.orderRepo.UpdateOrderStatus(ctx, orderID, newStatus)
}

func (s *OrderService) SendMessage(ctx context.Context, msg *domain.OrderMessage, callerRole domain.Role) (*domain.OrderMessage, error) {
	order, err := s.orderRepo.GetOrderByID(ctx, msg.OrderID)
	if err != nil || order == nil {
		return nil, errors.New("pesanan tidak ditemukan")
	}

	// Verify participant authorization strictly
	if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
		isStudent := callerRole == domain.RoleStudent && strings.EqualFold(msg.SenderID, order.StudentID)
		isOperator := callerRole == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, msg.SenderID)
		if !isStudent && !isOperator {
			return nil, errors.New("akses ditolak: Anda bukan partisipan dalam pesanan ini")
		}
	}

	err = s.orderRepo.AddOrderMessage(ctx, msg)
	return msg, err
}

func (s *OrderService) GetMessages(ctx context.Context, orderID, callerUserID string, callerRole domain.Role) ([]domain.OrderMessage, error) {
	order, err := s.orderRepo.GetOrderByID(ctx, orderID)
	if err != nil || order == nil {
		return nil, errors.New("pesanan tidak ditemukan")
	}

	// Verify participant authorization strictly
	if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
		isStudent := callerRole == domain.RoleStudent && strings.EqualFold(callerUserID, order.StudentID)
		isOperator := callerRole == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, callerUserID)
		if !isStudent && !isOperator {
			return nil, errors.New("akses ditolak: Anda bukan partisipan dalam pesanan ini")
		}
	}

	return s.orderRepo.ListOrderMessages(ctx, orderID)
}

func (s *OrderService) MarkMessagesAsRead(ctx context.Context, orderID, callerUserID string, callerRole domain.Role) error {
	order, err := s.orderRepo.GetOrderByID(ctx, orderID)
	if err != nil || order == nil {
		return errors.New("pesanan tidak ditemukan")
	}

	// Verify participant authorization strictly
	if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
		isStudent := callerRole == domain.RoleStudent && strings.EqualFold(callerUserID, order.StudentID)
		isOperator := callerRole == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(*order.OperatorID, callerUserID)
		if !isStudent && !isOperator {
			return errors.New("akses ditolak: Anda bukan partisipan dalam pesanan ini")
		}
	}

	return s.orderRepo.MarkMessagesAsRead(ctx, orderID, callerUserID)
}

type SubmitReviewRequest struct {
	Rating      int      `json:"rating"`
	ReviewText  string   `json:"review_text"`
	Tags        []string `json:"tags"`
	IsAnonymous bool     `json:"is_anonymous"`
}

func (s *OrderService) SubmitReview(ctx context.Context, orderID, studentID, studentName string, req SubmitReviewRequest) (*domain.OrderReview, error) {
	if req.Rating < 1 || req.Rating > 5 {
		return nil, errors.New("rating harus antara 1 sampai 5 bintang")
	}

	order, err := s.orderRepo.GetOrderByID(ctx, orderID)
	if err != nil {
		return nil, err
	}

	if order.StudentID != studentID {
		return nil, errors.New("akses ditolak: Anda hanya dapat memberi ulasan pada pesanan Anda sendiri")
	}

	if order.Status != domain.OrderStatusSelesai {
		return nil, errors.New("ulasan hanya dapat diberikan setelah pesanan berstatus Selesai")
	}

	rev := &domain.OrderReview{
		OrderID:     orderID,
		StudentID:   studentID,
		StudentName: studentName,
		OperatorID:  order.OperatorID,
		Rating:      req.Rating,
		ReviewText:  strings.TrimSpace(req.ReviewText),
		Tags:        req.Tags,
		IsAnonymous: req.IsAnonymous,
	}

	return s.orderRepo.CreateReview(ctx, rev)
}

func (s *OrderService) GetReviewByOrderID(ctx context.Context, orderID string) (*domain.OrderReview, error) {
	return s.orderRepo.GetReviewByOrderID(ctx, orderID)
}

func (s *OrderService) ListCanteenReviews(ctx context.Context, canteenID, productID string) ([]domain.OrderReview, error) {
	return s.orderRepo.ListCanteenReviews(ctx, canteenID, productID, 20)
}
