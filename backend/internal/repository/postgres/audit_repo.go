package postgres

import (
	"context"
	"fmt"

	"kantin-backend/internal/domain"
)

type AuditRepo struct {
	db *DB
}

func NewAuditRepo(db *DB) *AuditRepo {
	return &AuditRepo{db: db}
}

func (r *AuditRepo) LogAction(ctx context.Context, log *domain.AuditLog) error {
	oldJSON := "{}"
	if log.OldValue != nil && *log.OldValue != "" {
		oldJSON = *log.OldValue
	}
	newJSON := "{}"
	if log.NewValue != nil && *log.NewValue != "" {
		newJSON = *log.NewValue
	}

	query := `
		INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, old_data, new_data, ip_address)
		VALUES ($1, $2, $3, $4, $5::jsonb, $6::jsonb, $7)
		RETURNING id, created_at`
	return r.db.Pool.QueryRow(ctx, query,
		log.ActorID, log.ActionType, log.Description, log.TargetID, oldJSON, newJSON, log.IPAddress,
	).Scan(&log.ID, &log.CreatedAt)
}

func (r *AuditRepo) List(ctx context.Context, limit int) ([]domain.AuditLog, error) {
	if limit <= 0 {
		limit = 100
	}
	query := `
		SELECT a.id, a.user_id, a.action, a.entity_name, a.entity_id,
		       COALESCE(a.old_data::text, '{}'), COALESCE(a.new_data::text, '{}'), a.ip_address, a.created_at,
		       COALESCE(p.full_name, 'Sistem')
		FROM public.audit_logs a
		LEFT JOIN public.profiles p ON p.id = a.user_id
		ORDER BY a.created_at DESC
		LIMIT $1`

	rows, err := r.db.Pool.Query(ctx, query, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.AuditLog
	for rows.Next() {
		var a domain.AuditLog
		var action, entityName, fullName string
		var oldData, newData string
		if err := rows.Scan(
			&a.ID, &a.ActorID, &action, &entityName, &a.TargetID,
			&oldData, &newData, &a.IPAddress, &a.CreatedAt,
			&fullName,
		); err != nil {
			return nil, err
		}
		a.ActorName = fullName
		a.ActionType = action
		a.Description = fmt.Sprintf("%s pada %s", action, entityName)
		a.OldValue = &oldData
		a.NewValue = &newData
		list = append(list, a)
	}
	return list, nil
}

func (r *AuditRepo) ListByOperator(ctx context.Context, operatorID string, limit int) ([]domain.AuditLog, error) {
	if limit <= 0 {
		limit = 50
	}
	query := `
		SELECT a.id, a.user_id, a.action, a.entity_name, a.entity_id,
		       COALESCE(a.old_data::text, '{}'), COALESCE(a.new_data::text, '{}'), a.ip_address, a.created_at,
		       COALESCE(p.full_name, 'Kasir')
		FROM public.audit_logs a
		LEFT JOIN public.profiles p ON p.id = a.user_id
		WHERE a.user_id = $1 OR a.entity_id IN (SELECT id::text FROM public.orders WHERE operator_id = $1)
		ORDER BY a.created_at DESC
		LIMIT $2`

	rows, err := r.db.Pool.Query(ctx, query, operatorID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.AuditLog
	for rows.Next() {
		var a domain.AuditLog
		var action, entityName, fullName string
		var oldData, newData string
		if err := rows.Scan(
			&a.ID, &a.ActorID, &action, &entityName, &a.TargetID,
			&oldData, &newData, &a.IPAddress, &a.CreatedAt,
			&fullName,
		); err != nil {
			return nil, err
		}
		a.ActorName = fullName
		a.ActionType = action
		a.Description = fmt.Sprintf("%s pada %s", action, entityName)
		a.OldValue = &oldData
		a.NewValue = &newData
		list = append(list, a)
	}
	return list, nil
}
