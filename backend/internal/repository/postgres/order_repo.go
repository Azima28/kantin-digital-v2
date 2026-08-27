package postgres

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strconv"
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

// parseOptionAddonPrice extracts extra addon price from an option string like "telur (+Rp 3.000)" -> 3000
func parseOptionAddonPrice(optionStr string) int {
	re := regexp.MustCompile(`\(\+\s*(?:Rp\s*)?([0-9\.\,]+)\)`)
	matches := re.FindStringSubmatch(optionStr)
	if len(matches) > 1 {
		clean := strings.ReplaceAll(matches[1], ".", "")
		clean = strings.ReplaceAll(clean, ",", "")
		clean = strings.ReplaceAll(clean, " ", "")
		val, err := strconv.Atoi(clean)
		if err == nil && val > 0 {
			return val
		}
	}
	return 0
}

func (r *OrderRepo) CreateOrder(ctx context.Context, order *domain.Order, items []domain.OrderItem) (*domain.Order, error) {
	if len(items) == 0 {
		return nil, errors.New("pesanan harus memiliki setidaknya 1 item")
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// 1. Authoritative price and product validation strictly from database
	calculatedTotal := 0
	for i := range items {
		productRef := ""
		if items[i].ProductID != nil && strings.TrimSpace(*items[i].ProductID) != "" {
			productRef = strings.TrimSpace(*items[i].ProductID)
		} else if strings.TrimSpace(items[i].ProductName) != "" {
			productRef = strings.TrimSpace(items[i].ProductName)
		}

		if productRef == "" {
			return nil, errors.New("setiap item pesanan wajib menyertakan ID produk (product_id)")
		}

		var dbID string
		var dbOperatorID string
		var dbName string
		var dbPrice int
		var isAvailable bool
		var optBytes []byte

		// Query product strictly by ID (or fallback to exact name if legacy)
		queryProduct := `
			SELECT id, operator_id, name, price, is_available, customizable_options
			FROM public.products
			WHERE id::text = $1 OR LOWER(name) = LOWER($1)
			LIMIT 1`
		err := tx.QueryRow(ctx, queryProduct, productRef).Scan(
			&dbID, &dbOperatorID, &dbName, &dbPrice, &isAvailable, &optBytes,
		)
		if err != nil {
			return nil, fmt.Errorf("produk '%s' tidak ditemukan di menu kantin", productRef)
		}

		if !isAvailable {
			return nil, fmt.Errorf("produk '%s' sedang tidak tersedia (stok habis)", dbName)
		}

		if order.OperatorID != nil && *order.OperatorID != "" && !strings.EqualFold(dbOperatorID, *order.OperatorID) {
			return nil, fmt.Errorf("produk '%s' bukan milik stan yang dipilih", dbName)
		}

		// Ensure order.OperatorID is locked to the product's operator
		if order.OperatorID == nil || *order.OperatorID == "" {
			order.OperatorID = &dbOperatorID
		}

		// Calculate extra topping / option prices from authoritative DB options
		var dbOptions []string
		if len(optBytes) > 0 {
			_ = json.Unmarshal(optBytes, &dbOptions)
		}

		addonPrice := 0
		var validatedOptions []string
		for _, userOpt := range items[i].SelectedOptions {
			trimmedUserOpt := strings.TrimSpace(userOpt)
			if trimmedUserOpt == "" {
				continue
			}
			matched := false
			for _, validOpt := range dbOptions {
				if strings.EqualFold(validOpt, trimmedUserOpt) ||
					strings.HasPrefix(strings.ToLower(validOpt), strings.ToLower(trimmedUserOpt)) ||
					strings.HasPrefix(strings.ToLower(trimmedUserOpt), strings.ToLower(validOpt)) {
					addonPrice += parseOptionAddonPrice(validOpt)
					validatedOptions = append(validatedOptions, validOpt)
					matched = true
					break
				}
			}
			if !matched {
				extra := parseOptionAddonPrice(trimmedUserOpt)
				if extra > 0 {
					addonPrice += extra
				}
				validatedOptions = append(validatedOptions, trimmedUserOpt)
			}
		}

		unitPrice := dbPrice + addonPrice
		if items[i].Quantity <= 0 {
			items[i].Quantity = 1
		}

		items[i].ProductID = &dbID
		items[i].ProductName = dbName
		items[i].Price = unitPrice
		items[i].SelectedOptions = validatedOptions

		calculatedTotal += unitPrice * items[i].Quantity
	}

	// 2. Add delivery fee if applicable
	if order.OperatorID != nil && *order.OperatorID != "" {
		var deliveryFee int
		var isDeliveryEnabled bool
		err := tx.QueryRow(ctx, `SELECT delivery_fee, is_delivery_enabled FROM public.canteen_operators WHERE id = $1`, *order.OperatorID).Scan(&deliveryFee, &isDeliveryEnabled)
		if err == nil && isDeliveryEnabled && order.DeliveryLocation != nil && strings.TrimSpace(*order.DeliveryLocation) != "" && !strings.Contains(strings.ToLower(*order.DeliveryLocation), "pickup") && !strings.Contains(strings.ToLower(*order.DeliveryLocation), "ambil sendiri") {
			calculatedTotal += deliveryFee
		}
	}

	order.TotalAmount = calculatedTotal

	// 3. Lock student balance row & validate account/card status
	var currentBalance int
	var isCardActive bool
	var isProfileActive bool
	var rfidUID *string
	err = tx.QueryRow(ctx, `
		SELECT s.balance, s.is_active, p.is_active, s.rfid_uid
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, order.StudentID).Scan(&currentBalance, &isCardActive, &isProfileActive, &rfidUID)
	if err != nil {
		return nil, errors.New("data siswa tidak ditemukan")
	}
	if !isProfileActive {
		return nil, errors.New("transaksi ditolak: Akun siswa sedang dinonaktifkan / diblokir oleh admin")
	}
	if !isCardActive {
		return nil, errors.New("transaksi ditolak: Kartu RFID siswa sedang diblokir / dibekukan")
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
			INSERT INTO public.order_items (order_id, product_id, product_name, quantity, price, selected_options, notes)
			VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)
			RETURNING id`
		err = tx.QueryRow(ctx, queryItem,
			order.ID, items[i].ProductID, items[i].ProductName, items[i].Quantity, items[i].Price, optJSON, items[i].Notes,
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

	// Fetch items with image_url joined
	itemsQuery := `
		SELECT oi.id, oi.order_id, oi.product_id, oi.product_name, oi.quantity, oi.price, oi.selected_options, COALESCE(oi.notes, ''), p.image_url
		FROM public.order_items oi
		LEFT JOIN public.products p ON p.id = oi.product_id OR (oi.product_id IS NULL AND LOWER(TRIM(p.name)) = LOWER(TRIM(oi.product_name)))
		WHERE oi.order_id = $1`

	itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orderID)
	if err == nil {
		defer itemRows.Close()
		for itemRows.Next() {
			var it domain.OrderItem
			var optBytes []byte
			if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductID, &it.ProductName, &it.Quantity, &it.Price, &optBytes, &it.Notes, &it.ImageURL); err == nil {
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
			SELECT oi.id, oi.order_id, oi.product_id, oi.product_name, oi.quantity, oi.price, oi.selected_options, COALESCE(oi.notes, ''), p.image_url
			FROM public.order_items oi
			LEFT JOIN public.products p ON p.id = oi.product_id OR (oi.product_id IS NULL AND LOWER(TRIM(p.name)) = LOWER(TRIM(oi.product_name)))
			WHERE oi.order_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orders[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.OrderItem
				var optBytes []byte
				if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductID, &it.ProductName, &it.Quantity, &it.Price, &optBytes, &it.Notes, &it.ImageURL); err == nil {
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
			SELECT oi.id, oi.order_id, oi.product_id, oi.product_name, oi.quantity, oi.price, oi.selected_options, COALESCE(oi.notes, ''), p.image_url
			FROM public.order_items oi
			LEFT JOIN public.products p ON p.id = oi.product_id OR (oi.product_id IS NULL AND LOWER(TRIM(p.name)) = LOWER(TRIM(oi.product_name)))
			WHERE oi.order_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, orders[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.OrderItem
				var optBytes []byte
				if err := itemRows.Scan(&it.ID, &it.OrderID, &it.ProductID, &it.ProductName, &it.Quantity, &it.Price, &optBytes, &it.Notes, &it.ImageURL); err == nil {
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
		return errors.New("pesanan tidak ditemukan")
	}

	if prevStatus == newStatus {
		return nil
	}

	// 1. If transitioning to Selesai: Release escrow funds to canteen operator
	if newStatus == domain.OrderStatusSelesai && prevStatus != domain.OrderStatusSelesai {
		if operatorID != nil && *operatorID != "" {
			_, err = tx.Exec(ctx, `UPDATE public.canteen_operators SET balance_earned = balance_earned + $1 WHERE id = $2`, totalAmount, *operatorID)
			if err != nil {
				return fmt.Errorf("gagal menambahkan saldo pendapatan stan: %w", err)
			}
		}

		// Update transaction status to 'success'
		_, _ = tx.Exec(ctx, `
			UPDATE public.transactions
			SET status = 'success'
			WHERE student_id = $1 AND operator_id = $2 AND total_amount = $3 AND status = 'pending'`,
			studentID, operatorID, totalAmount,
		)

		// Send notification to student
		_, _ = tx.Exec(ctx, `
			INSERT INTO public.notifications (student_id, title, message, type)
			VALUES ($1, 'Pesanan Selesai! 🎉', 'Pesanan Anda telah selesai diproses oleh stan.', 'general')`,
			studentID,
		)
	}

	// 2. If transitioning to Dibatalkan: Refund escrow funds back to student balance
	if newStatus == domain.OrderStatusDibatalkan && prevStatus != domain.OrderStatusDibatalkan {
		_, err = tx.Exec(ctx, `UPDATE public.students SET balance = balance + $1 WHERE id = $2`, totalAmount, studentID)
		if err != nil {
			return fmt.Errorf("gagal mengembalikan saldo siswa: %w", err)
		}

		// Update transaction status to 'refunded'
		_, _ = tx.Exec(ctx, `
			UPDATE public.transactions
			SET status = 'refunded'
			WHERE student_id = $1 AND operator_id = $2 AND total_amount = $3 AND status = 'pending'`,
			studentID, operatorID, totalAmount,
		)

		// Send notification to student
		_, _ = tx.Exec(ctx, `
			INSERT INTO public.notifications (student_id, title, message, type)
			VALUES ($1, 'Pesanan Dibatalkan ↩️', $2, 'general')`,
			studentID, fmt.Sprintf("Pesanan dibatalkan. Dana sebesar Rp %d telah dikembalikan ke saldo kartu Anda.", totalAmount),
		)
	}

	// Update order status in orders table
	_, err = tx.Exec(ctx, `UPDATE public.orders SET status = $1 WHERE id = $2`, newStatus, orderID)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func (r *OrderRepo) AddOrderMessage(ctx context.Context, msg *domain.OrderMessage) error {
	query := `
		INSERT INTO public.order_messages (order_id, sender_id, sender_role, message)
		VALUES ($1, $2, $3, $4)
		RETURNING id, created_at`

	return r.db.Pool.QueryRow(ctx, query,
		msg.OrderID, msg.SenderID, msg.SenderRole, msg.Message,
	).Scan(&msg.ID, &msg.CreatedAt)
}

func (r *OrderRepo) ListOrderMessages(ctx context.Context, orderID string) ([]domain.OrderMessage, error) {
	query := `
		SELECT m.id, m.order_id, m.sender_id, m.sender_role, m.message, m.is_read, m.created_at,
		       COALESCE(p.full_name, 'Pengguna') as sender_name
		FROM public.order_messages m
		LEFT JOIN public.profiles p ON p.id = m.sender_id
		WHERE m.order_id = $1
		ORDER BY m.created_at ASC`

	rows, err := r.db.Pool.Query(ctx, query, orderID)
	if err != nil {
		return make([]domain.OrderMessage, 0), err
	}
	defer rows.Close()

	messages := make([]domain.OrderMessage, 0)
	for rows.Next() {
		var m domain.OrderMessage
		err := rows.Scan(
			&m.ID, &m.OrderID, &m.SenderID, &m.SenderRole, &m.Message, &m.IsRead, &m.CreatedAt,
			&m.SenderName,
		)
		if err != nil {
			return make([]domain.OrderMessage, 0), err
		}
		messages = append(messages, m)
	}
	return messages, nil
}

func (r *OrderRepo) MarkMessagesAsRead(ctx context.Context, orderID, readerID string) error {
	query := `
		UPDATE public.order_messages
		SET is_read = true
		WHERE order_id = $1 AND sender_id != $2`

	_, err := r.db.Pool.Exec(ctx, query, orderID, readerID)
	return err
}

func (r *OrderRepo) CreateReview(ctx context.Context, rev *domain.OrderReview) (*domain.OrderReview, error) {
	query := `
		INSERT INTO public.order_reviews (order_id, student_id, operator_id, rating, review_text, tags, is_anonymous)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at`

	err := r.db.Pool.QueryRow(ctx, query,
		rev.OrderID, rev.StudentID, rev.OperatorID, rev.Rating, rev.ReviewText, rev.Tags, rev.IsAnonymous,
	).Scan(&rev.ID, &rev.CreatedAt)
	if err != nil {
		return nil, err
	}
	return rev, nil
}

func (r *OrderRepo) GetReviewByOrderID(ctx context.Context, orderID string) (*domain.OrderReview, error) {
	query := `
		SELECT r.id, r.order_id, r.student_id, r.operator_id, r.rating, r.review_text, r.tags, r.is_anonymous, r.created_at,
		       p.full_name, p.avatar_url
		FROM public.order_reviews r
		LEFT JOIN public.profiles p ON p.id = r.student_id
		WHERE r.order_id = $1`

	row := r.db.Pool.QueryRow(ctx, query, orderID)
	var rev domain.OrderReview
	var fullName, avatarURL *string
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
		if fullName != nil {
			rev.StudentName = *fullName
		}
		rev.AvatarURL = avatarURL
	}

	return &rev, nil
}

func (r *OrderRepo) ListCanteenReviews(ctx context.Context, canteenID string, limit int) ([]domain.OrderReview, error) {
	query := `
		SELECT r.id, r.order_id, r.student_id, r.operator_id, r.rating, r.review_text, r.tags, r.is_anonymous, r.created_at,
		       p.full_name, p.avatar_url
		FROM public.order_reviews r
		LEFT JOIN public.profiles p ON p.id = r.student_id
		WHERE r.operator_id = $1
		ORDER BY r.created_at DESC
		LIMIT $2`

	rows, err := r.db.Pool.Query(ctx, query, canteenID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reviews []domain.OrderReview
	for rows.Next() {
		var rev domain.OrderReview
		var fullName, avatarURL *string
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
			if fullName != nil {
				rev.StudentName = *fullName
			}
			rev.AvatarURL = avatarURL
		}
		reviews = append(reviews, rev)
	}
	return reviews, nil
}
