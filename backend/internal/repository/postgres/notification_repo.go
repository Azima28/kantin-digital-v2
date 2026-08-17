package postgres

import (
	"context"

	"kantin-backend/internal/domain"
)

type NotificationRepo struct {
	db *DB
}

func NewNotificationRepo(db *DB) *NotificationRepo {
	return &NotificationRepo{db: db}
}

func (r *NotificationRepo) ListByStudent(ctx context.Context, studentID string, limit int) ([]domain.Notification, error) {
	if limit <= 0 {
		limit = 50
	}
	query := `
		SELECT id, student_id, title, message, type, is_read, created_at
		FROM public.notifications
		WHERE student_id = $1
		ORDER BY created_at DESC
		LIMIT $2`

	rows, err := r.db.Pool.Query(ctx, query, studentID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Notification
	for rows.Next() {
		var n domain.Notification
		if err := rows.Scan(&n.ID, &n.StudentID, &n.Title, &n.Message, &n.Type, &n.IsRead, &n.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, n)
	}
	return list, nil
}

func (r *NotificationRepo) MarkAsRead(ctx context.Context, notifID, studentID string) error {
	query := `UPDATE public.notifications SET is_read = TRUE WHERE id = $1 AND student_id = $2`
	_, err := r.db.Pool.Exec(ctx, query, notifID, studentID)
	return err
}

func (r *NotificationRepo) MarkAllAsRead(ctx context.Context, studentID string) error {
	query := `UPDATE public.notifications SET is_read = TRUE WHERE student_id = $1`
	_, err := r.db.Pool.Exec(ctx, query, studentID)
	return err
}
