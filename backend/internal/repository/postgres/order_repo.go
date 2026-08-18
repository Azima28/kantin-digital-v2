package postgres

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

type OrderRepo struct {
	db *DB
}

func NewOrderRepo(db *DB) *OrderRepo {
	return &OrderRepo{db: db}
}

func (r *OrderRepo) CreateOrder(ctx context.Context, order *domain.Order, items []domain.OrderItem) (*domain.Order, error) {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// 1. Authoritative price calculation from products table
	calculatedTotal := 0
	for i := range items {
		var dbPrice int
		var dbName string
		err := tx.QueryRow(ctx, `SELECT price, name FROM public.products WHERE LOWER(name) = LOWER($1) OR id::text = $1 LIMIT 1`, items[i].ProductName).Scan(&dbPrice, &dbName)
		if err == nil {
			items[i].Price = dbPrice
			items[i].ProductName = dbName
		}
		if items[i].Quantity <= 0 {
			items[i].Quantity = 1
		}
		calculatedTotal += items[i].Price * items[i].Quantity
	}

	// 2. Add delivery fee if applicable
	if order.OperatorID != nil && *order.OperatorID != "" {
		var deliveryFee int
		var isDeliveryEnabled bool
		err := tx.QueryRow(ctx, `SELECT delivery_fee, is_delivery_enabled FROM public.canteen_operators WHERE id = $1`, *order.OperatorID).Scan(&deliveryFee, &isDeliveryEnabled)
		if err == nil && isDeliveryEnabled && order.DeliveryLocation != nil && *order.DeliveryLocation != "" {
			calculatedTotal += deliveryFee
		}
	}

	order.TotalAmount = calculatedTotal

	// 3. Lock student balance row
	var currentBalance int
	var isActive bool
	err = tx.QueryRow(ctx, `SELECT balance, is_active FROM public.students WHERE id = $1 FOR UPDATE`, order.StudentID).Scan(&currentBalance, &isActive)
	if err != nil {
		return nil, errors.New("data siswa tidak ditemukan")
	}
	if !isActive {
		return nil, errors.New("kartu atau akun siswa sedang dinonaktifkan")
	}
	if currentBalance < order.TotalAmount {
		return nil, fmt.Errorf("saldo tidak mencukupi (Saldo: Rp %d, Total Tagihan: Rp %d)", currentBalance, order.TotalAmount)
	}

	// 4. Deduct student balance
	_, err = tx.Exec(ctx, `UPDATE public.students SET balance = balance - $1 WHERE id = $2`, order.TotalAmount, order.StudentID)
	if err != nil {
		return nil, fmt.Errorf("gagal memotong saldo: %w", err)
	}

	// 5. Insert order
	queryOrder := `
		INSERT INTO public.orders (student_id, student_name, operator_id, status, delivery_location, total_amount)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`

	err = tx.QueryRow(ctx, queryOrder,
		order.StudentID, order.StudentName, order.OperatorID, order.Status, order.DeliveryLocation, order.TotalAmount,
	).Scan(&order.ID, &order.CreatedAt)
	if err != nil {
		return nil, err
	}

	for i := range items {
		optJSON, _ := json.Marshal(items[i].SelectedOptions)
		queryItem := `
			INSERT INTO public.order_items (order_id, product_name, quantity, price, selected_options)
			VALUES ($1, $2, $3, $4, $5::jsonb)
			RETURNING id`
		err = tx.QueryRow(ctx, queryItem,
			order.ID, items[i].ProductName, items[i].Quantity, items[i].Price, optJSON,
		).Scan(&items[i].ID)
		if err != nil {
			return nil, err
		}
		items[i].OrderID = order.ID
	}

	// 6. Record transaction with status 'pending' (escrow)
	_, _ = tx.Exec(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
		VALUES ($1, $2, $3, 'purchase', 'pending', 'app_order')`,
		order.StudentID, order.OperatorID, order.TotalAmount,
	)

	// 7. Notification
	notifMsg := fmt.Sprintf("Pesanan senilai Rp %d berhasil dibuat.", order.TotalAmount)
	if order.DeliveryLocation != nil && *order.DeliveryLocation != "" {
		notifMsg = fmt.Sprintf("Pesanan senilai Rp %d (%s) telah dikirim ke kantin.", order.TotalAmount, *order.DeliveryLocation)
	}
	_, _ = tx.Exec(ctx, `
		INSERT INTO public.notifications (student_id, title, message, type)
		VALUES ($1, $2, $3, 'purchase')`,
		order.StudentID, "Pesanan Berhasil Disimpan! 🛒", notifMsg,
	)

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	order.Items = items
	return order, nil
}

func (r *OrderRepo) GetOrderByID(ctx context.Context, orderID string) (*domain.Order, error) {
	query := `
		SELECT o.id, o.student_id, o.student_name, o.operator_id, o.status, o.delivery_location, o.total_amount, o.cancel_request_reason, o.created_at,
		       c.canteen_name
		FROM public.orders o
		LEFT JOIN public.canteen_operators c ON c.id = o.operator_id
		WHERE o.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, orderID)
	var o domain.Order
	var canteenName *string
	err := row.Scan(
		&o.ID, &o.StudentID, &o.StudentName, &o.OperatorID, &o.Status, &o.DeliveryLocation, &o.TotalAmount, &o.CancelRequestReason, &o.CreatedAt,
		&canteenName,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("pesanan tidak ditemukan")
		}
		return nil, err
	}

	if o.OperatorID != nil && canteenName != nil {
		o.Operator = &domain.CanteenOperator{
			ID:          *o.OperatorID,
			CanteenName: *canteenName,
		}
	}

	// Fetch items
	itemsQuery := `
		SELECT id, order_id, product_name, quantity, price, selected_options
		FROM public.order_items
		WHERE order_id = $1`

	itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orderID)
	if err == nil {
		defer itemRows.Close()
		for itemRows.Next() {
			var it domain.OrderItem
			var optBytes []byte
			if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductName, &it.Quantity, &it.Price, &optBytes); err == nil {
				if len(optBytes) > 0 {
					_ = json.Unmarshal(optBytes, &it.SelectedOptions)
				}
				o.Items = append(o.Items, it)
			}
		}
	}

	return &o, nil
}

func (r *OrderRepo) ListOrdersByStudent(ctx context.Context, studentID string) ([]domain.Order, error) {
	query := `
		SELECT o.id, o.student_id, o.student_name, o.operator_id, o.status, o.delivery_location, o.total_amount, o.cancel_request_reason, o.created_at,
		       c.canteen_name
		FROM public.orders o
		LEFT JOIN public.canteen_operators c ON c.id = o.operator_id
		WHERE o.student_id = $1
		ORDER BY o.created_at DESC`

	rows, err := r.db.Pool.Query(ctx, query, studentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []domain.Order
	for rows.Next() {
		var o domain.Order
		var canteenName *string
		err := rows.Scan(
			&o.ID, &o.StudentID, &o.StudentName, &o.OperatorID, &o.Status, &o.DeliveryLocation, &o.TotalAmount, &o.CancelRequestReason, &o.CreatedAt,
			&canteenName,
		)
		if err != nil {
			return nil, err
		}
		if o.OperatorID != nil && canteenName != nil {
			o.Operator = &domain.CanteenOperator{
				ID:          *o.OperatorID,
				CanteenName: *canteenName,
			}
		}
		orders = append(orders, o)
	}

	// Fetch items for all student orders
	for i := range orders {
		itemsQuery := `
			SELECT oi.id, oi.order_id, oi.product_name, oi.quantity, oi.price, oi.selected_options, p.image_url
			FROM public.order_items oi
			LEFT JOIN public.products p ON LOWER(p.name) = LOWER(oi.product_name)
			WHERE oi.order_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orders[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.OrderItem
				var optBytes []byte
				if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductName, &it.Quantity, &it.Price, &optBytes, &it.ImageURL); err == nil {
					if len(optBytes) > 0 {
						_ = json.Unmarshal(optBytes, &it.SelectedOptions)
					}
					orders[i].Items = append(orders[i].Items, it)
				}
			}
			itemRows.Close()
		}
	}
	return orders, nil
}

func (r *OrderRepo) ListOrdersByOperator(ctx context.Context, operatorID string, status string) ([]domain.Order, error) {
	query := `
		SELECT o.id, o.student_id, o.student_name, o.operator_id, o.status, o.delivery_location, o.total_amount, o.cancel_request_reason, o.created_at
		FROM public.orders o
		WHERE o.operator_id = $1
		  AND ($2 = '' OR o.status = $2)
		ORDER BY o.created_at DESC`

	rows, err := r.db.Pool.Query(ctx, query, operatorID, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []domain.Order
	for rows.Next() {
		var o domain.Order
		err := rows.Scan(
			&o.ID, &o.StudentID, &o.StudentName, &o.OperatorID, &o.Status, &o.DeliveryLocation, &o.TotalAmount, &o.CancelRequestReason, &o.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		orders = append(orders, o)
	}

	// Fetch items for all operator orders
	for i := range orders {
		itemsQuery := `
			SELECT oi.id, oi.order_id, oi.product_name, oi.quantity, oi.price, oi.selected_options, p.image_url
			FROM public.order_items oi
			LEFT JOIN public.products p ON LOWER(p.name) = LOWER(oi.product_name)
			WHERE oi.order_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orders[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.OrderItem
				var optBytes []byte
				if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductName, &it.Quantity, &it.Price, &optBytes, &it.ImageURL); err == nil {
					if len(optBytes) > 0 {
						_ = json.Unmarshal(optBytes, &it.SelectedOptions)
					}
					orders[i].Items = append(orders[i].Items, it)
				}
			}
			itemRows.Close()
		}
	}
	return orders, nil
}

func (r *OrderRepo) UpdateOrderStatus(ctx context.Context, orderID string, newStatus domain.OrderStatus) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// Fetch current order data with row lock
	var prevStatus domain.OrderStatus
	var totalAmount int
	var operatorID *string
	var studentID string
	err = tx.QueryRow(ctx, `SELECT status, total_amount, operator_id, student_id FROM public.orders WHERE id = $1 FOR UPDATE`, orderID).Scan(
		&prevStatus, &totalAmount, &operatorID, &studentID,
	)
	if err != nil {
		return err
	}

	// 1. Idempotency Check: No-op if status is unchanged
	if prevStatus == newStatus {
		return nil
	}

	// 2. Strict State Machine Validation: Terminal states are immutable
	if prevStatus == domain.OrderStatusSelesai {
		return fmt.Errorf("pesanan sudah selesai dan tidak dapat diubah lagi")
	}
	if prevStatus == domain.OrderStatusDibatalkan {
		return fmt.Errorf("pesanan sudah dibatalkan dan tidak dapat diubah lagi")
	}

	// 3. Update status in orders table
	_, err = tx.Exec(ctx, `UPDATE public.orders SET status = $1, updated_at = NOW() WHERE id = $2`, newStatus, orderID)
	if err != nil {
		return err
	}

	// 4. Escrow Release: Transition to 'Selesai' exactly once
	if newStatus == domain.OrderStatusSelesai {
		if operatorID != nil && totalAmount > 0 {
			// Credit canteen operator balance
			_, err = tx.Exec(ctx, `UPDATE public.canteen_operators SET balance_earned = balance_earned + $1 WHERE id = $2`, totalAmount, *operatorID)
			if err != nil {
				return err
			}

			// Update corresponding transaction status to 'success'
			res, _ := tx.Exec(ctx, `
				UPDATE public.transactions
				SET status = 'success', updated_at = NOW()
				WHERE student_id = $1 AND operator_id = $2 AND total_amount = $3 AND status IN ('pending', 'pending_escrow')
			`, studentID, *operatorID, totalAmount)

			if res.RowsAffected() == 0 {
				_, _ = tx.Exec(ctx, `
					INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method, created_at)
					VALUES ($1, $2, $3, 'purchase', 'success', 'app_order', NOW())
				`, studentID, *operatorID, totalAmount)
			}

			notifMsg := fmt.Sprintf("Pesanan Anda senilai Rp %d telah selesai disiapkan oleh kantin.", totalAmount)
			_, _ = tx.Exec(ctx, `INSERT INTO public.notifications (student_id, title, message, type) VALUES ($1, 'Pesanan Selesai! 🎉', $2, 'system')`, studentID, notifMsg)

			_, _ = tx.Exec(ctx, `INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, created_at) VALUES ($1, 'SELESAI_PESANAN', 'orders', $2, NOW())`, *operatorID, orderID)
		}
	}

	// 5. Automatic Refund: Transition to 'Dibatalkan' exactly once
	if newStatus == domain.OrderStatusDibatalkan {
		if totalAmount > 0 {
			// Refund student balance
			_, err = tx.Exec(ctx, `UPDATE public.students SET balance = balance + $1 WHERE id = $2`, totalAmount, studentID)
			if err != nil {
				return err
			}

			if operatorID != nil {
				// Mark corresponding transaction as refunded
				res, _ := tx.Exec(ctx, `
					UPDATE public.transactions
					SET status = 'refunded', updated_at = NOW()
					WHERE student_id = $1 AND operator_id = $2 AND total_amount = $3 AND status IN ('pending', 'pending_escrow')
				`, studentID, *operatorID, totalAmount)

				if res.RowsAffected() == 0 {
					_, _ = tx.Exec(ctx, `
						INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method, created_at)
						VALUES ($1, $2, $3, 'purchase', 'refunded', 'app_order', NOW())
					`, studentID, *operatorID, totalAmount)
				}

				_, _ = tx.Exec(ctx, `INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, created_at) VALUES ($1, 'BATAL_PESANAN', 'orders', $2, NOW())`, *operatorID, orderID)
			}

			notifMsg := fmt.Sprintf("Pesanan senilai Rp %d dibatalkan. Saldo telah dikembalikan ke akun Anda.", totalAmount)
			_, _ = tx.Exec(ctx, `INSERT INTO public.notifications (student_id, title, message, type) VALUES ($1, 'Pesanan Dibatalkan ❌', $2, 'refund')`, studentID, notifMsg)
		}
	}

	return tx.Commit(ctx)
}

func (r *OrderRepo) AddOrderMessage(ctx context.Context, msg *domain.OrderMessage) error {
	query := `
		INSERT INTO public.order_messages (order_id, sender_id, sender_role, sender_name, message)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id, created_at`
	return r.db.Pool.QueryRow(ctx, query, msg.OrderID, msg.SenderID, msg.SenderRole, msg.SenderName, msg.Message).Scan(&msg.ID, &msg.CreatedAt)
}

func (r *OrderRepo) ListOrderMessages(ctx context.Context, orderID string) ([]domain.OrderMessage, error) {
	query := `
		SELECT id, order_id, sender_id, sender_role, COALESCE(sender_name, ''), message, COALESCE(is_read, false), created_at
		FROM public.order_messages
		WHERE order_id = $1
		ORDER BY created_at ASC`

	rows, err := r.db.Pool.Query(ctx, query, orderID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.OrderMessage
	for rows.Next() {
		var m domain.OrderMessage
		if err := rows.Scan(&m.ID, &m.OrderID, &m.SenderID, &m.SenderRole, &m.SenderName, &m.Message, &m.IsRead, &m.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, m)
	}
	return list, nil
}

func (r *OrderRepo) MarkMessagesAsRead(ctx context.Context, orderID, myUserID string) error {
	query := `UPDATE public.order_messages SET is_read = true WHERE order_id = $1 AND sender_id != $2`
	_, err := r.db.Pool.Exec(ctx, query, orderID, myUserID)
	return err
}

func (r *OrderRepo) CreateReview(ctx context.Context, review *domain.OrderReview) (*domain.OrderReview, error) {
	query := `
		INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
		ON CONFLICT (order_id) DO UPDATE
		SET rating = EXCLUDED.rating, review_text = EXCLUDED.review_text, tags = EXCLUDED.tags, is_anonymous = EXCLUDED.is_anonymous, created_at = NOW()
		RETURNING id, created_at`

	err := r.db.Pool.QueryRow(ctx, query,
		review.OrderID, review.StudentID, review.OperatorID, review.Rating, review.ReviewText, review.Tags, review.IsAnonymous,
	).Scan(&review.ID, &review.CreatedAt)
	if err != nil {
		return nil, err
	}

	// Send categorized notification to canteen operator with type 'review'
	reviewerName := "Siswa"
	if !review.IsAnonymous {
		_ = r.db.Pool.QueryRow(ctx, `SELECT full_name FROM public.profiles WHERE id = $1`, review.StudentID).Scan(&reviewerName)
	}
	notifTitle := fmt.Sprintf("Ulasan Baru (★ %d)", review.Rating)
	notifMsg := fmt.Sprintf("%s memberi rating ★ %d untuk pesananmu.", reviewerName, review.Rating)
	if review.ReviewText != "" {
		notifMsg = fmt.Sprintf("%s: \"%s\"", reviewerName, review.ReviewText)
	} else if len(review.Tags) > 0 {
		notifMsg = fmt.Sprintf("%s: %s", reviewerName, strings.Join(review.Tags, ", "))
	}

	_, _ = r.db.Pool.Exec(ctx, `
		INSERT INTO public.notifications (user_id, student_id, title, message, type, is_read, created_at)
		VALUES ($1, NULL, $2, $3, 'review', false, NOW())`,
		review.OperatorID, notifTitle, notifMsg,
	)

	return review, nil
}

func (r *OrderRepo) GetReviewByOrderID(ctx context.Context, orderID string) (*domain.OrderReview, error) {
	query := `
		SELECT r.id, r.order_id, r.student_id, r.operator_id, r.rating, r.review_text, r.tags, r.is_anonymous, r.created_at,
		       p.full_name, p.avatar_url
		FROM public.order_reviews r
		JOIN public.profiles p ON p.id = r.student_id
		WHERE r.order_id = $1`

	row := r.db.Pool.QueryRow(ctx, query, orderID)
	var rev domain.OrderReview
	var fullName string
	var avatarURL *string
	err := row.Scan(
		&rev.ID, &rev.OrderID, &rev.StudentID, &rev.OperatorID, &rev.Rating, &rev.ReviewText, &rev.Tags, &rev.IsAnonymous, &rev.CreatedAt,
		&fullName, &avatarURL,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}

	if rev.IsAnonymous {
		rev.StudentName = "Siswa (Anonim)"
		rev.AvatarURL = nil
	} else {
		rev.StudentName = fullName
		rev.AvatarURL = avatarURL
	}
	return &rev, nil
}

func (r *OrderRepo) ListCanteenReviews(ctx context.Context, operatorID string, limit int) ([]domain.OrderReview, error) {
	if limit <= 0 {
		limit = 20
	}
	query := `
		SELECT r.id, r.order_id, r.student_id, r.operator_id, r.rating, r.review_text, r.tags, r.is_anonymous, r.created_at,
		       p.full_name, p.avatar_url
		FROM public.order_reviews r
		JOIN public.profiles p ON p.id = r.student_id
		WHERE r.operator_id = $1
		ORDER BY r.created_at DESC
		LIMIT $2`

	rows, err := r.db.Pool.Query(ctx, query, operatorID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.OrderReview
	for rows.Next() {
		var rev domain.OrderReview
		var fullName string
		var avatarURL *string
		err := rows.Scan(
			&rev.ID, &rev.OrderID, &rev.StudentID, &rev.OperatorID, &rev.Rating, &rev.ReviewText, &rev.Tags, &rev.IsAnonymous, &rev.CreatedAt,
			&fullName, &avatarURL,
		)
		if err != nil {
			return nil, err
		}
		if rev.IsAnonymous {
			rev.StudentName = "Siswa (Anonim)"
			rev.AvatarURL = nil
		} else {
			rev.StudentName = fullName
			rev.AvatarURL = avatarURL
		}
		list = append(list, rev)
	}
	return list, nil
}
