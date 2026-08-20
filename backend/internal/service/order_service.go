package service

import (
	"context"
	"errors"
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

	calculatedItemsTotal := 0
	for _, it := range req.Items {
		if it.Quantity <= 0 {
			return nil, errors.New("jumlah item harus lebih dari 0")
		}
		if it.Price < 0 {
			return nil, errors.New("harga item tidak boleh negatif")
		}
		calculatedItemsTotal += it.Price * it.Quantity
	}

	if req.TotalAmount < calculatedItemsTotal {
		req.TotalAmount = calculatedItemsTotal
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

	// Verify merchant ownership
	if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin {
		if order.OperatorID == nil || *order.OperatorID != callerUserID {
			return errors.New("akses ditolak: pesanan ini bukan milik stan Anda")
		}
	}

	return s.orderRepo.UpdateOrderStatus(ctx, orderID, newStatus)
}

func (s *OrderService) SendMessage(ctx context.Context, msg *domain.OrderMessage, callerRole domain.Role) (*domain.OrderMessage, error) {
	order, err := s.orderRepo.GetOrderByID(ctx, msg.OrderID)
	if err == nil && order != nil {
		// Verify participant authorization strictly (Admins & Finance Officers are universally authorized)
		if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
			isParticipant := (callerRole == domain.RoleStudent && strings.EqualFold(msg.SenderID, order.StudentID)) ||
				(callerRole == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(msg.SenderID, *order.OperatorID))
			if !isParticipant {
				return nil, errors.New("akses ditolak: Anda bukan partisipan dalam pesanan ini")
			}
		}
	}

	err = s.orderRepo.AddOrderMessage(ctx, msg)
	return msg, err
}

func (s *OrderService) GetMessages(ctx context.Context, orderID, callerUserID string, callerRole domain.Role) ([]domain.OrderMessage, error) {
	order, err := s.orderRepo.GetOrderByID(ctx, orderID)
	if err != nil {
		// If order ID is not in orders table (e.g. direct POS transaction ID), list existing messages or return empty
		return s.orderRepo.ListOrderMessages(ctx, orderID)
	}

	// Verify participant authorization gracefully (Admins & Finance Officers are universally authorized)
	if callerRole != domain.RoleSuperAdmin && callerRole != domain.RoleAdmin && callerRole != domain.RolePetugasKeuangan {
		isParticipant := (callerRole == domain.RoleStudent && strings.EqualFold(callerUserID, order.StudentID)) ||
			(callerRole == domain.RolePetugasKantin && order.OperatorID != nil && strings.EqualFold(callerUserID, *order.OperatorID))
		if !isParticipant {
			return []domain.OrderMessage{}, nil
		}
	}

	return s.orderRepo.ListOrderMessages(ctx, orderID)
}

func (s *OrderService) MarkMessagesAsRead(ctx context.Context, orderID, callerUserID string) error {
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

func (s *OrderService) ListCanteenReviews(ctx context.Context, canteenID string) ([]domain.OrderReview, error) {
	return s.orderRepo.ListCanteenReviews(ctx, canteenID, 20)
}
