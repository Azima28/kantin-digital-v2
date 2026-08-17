package service

import (
	"context"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/repository/postgres"
)

type NotificationService struct {
	notifRepo *postgres.NotificationRepo
}

func NewNotificationService(notifRepo *postgres.NotificationRepo) *NotificationService {
	return &NotificationService{notifRepo: notifRepo}
}

func (s *NotificationService) ListByStudent(ctx context.Context, studentID string, limit int) ([]domain.Notification, error) {
	return s.notifRepo.ListByStudent(ctx, studentID, limit)
}

func (s *NotificationService) MarkAsRead(ctx context.Context, notifID, studentID string) error {
	return s.notifRepo.MarkAsRead(ctx, notifID, studentID)
}

func (s *NotificationService) MarkAllAsRead(ctx context.Context, studentID string) error {
	return s.notifRepo.MarkAllAsRead(ctx, studentID)
}
