package postgres

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

var (
	ErrInsufficientBalance = errors.New("saldo tidak mencukupi")
	ErrCardInactive        = errors.New("kartu atau akun siswa dalam status non-aktif")
	ErrDailyLimitExceeded  = errors.New("transaksi melebihi batas limit harian jajan siswa")
	ErrTransactionNotFound = errors.New("transaksi tidak ditemukan")
)

type TransactionRepo struct {
	db *DB
}

func NewTransactionRepo(db *DB) *TransactionRepo {
	return &TransactionRepo{db: db}
}

type CheckoutParams struct {
	StudentID      string
	OperatorID     string
	TotalAmount    int
	PurchaseMethod string
	DeliveryLoc    string
	Items          []domain.TransactionItem
}

// ProcessPurchase performs an atomic ACID checkout with Row-Level Locking
func (r *TransactionRepo) ProcessPurchase(ctx context.Context, p CheckoutParams) (*domain.Transaction, error) {
	tx, err := r.db.Pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return nil, fmt.Errorf("gagal memulai database transaksi: %w", err)
	}
	defer tx.Rollback(ctx)

	// 1. Authoritative price recalculation from database
	authoritativeTotal := 0
	for i := range p.Items {
		if p.Items[i].ProductID != nil && *p.Items[i].ProductID != "" {
			var dbPrice int
			err := tx.QueryRow(ctx, `SELECT price FROM public.products WHERE id = $1`, *p.Items[i].ProductID).Scan(&dbPrice)
			if err == nil && dbPrice > 0 {
				p.Items[i].UnitPrice = dbPrice
			}
		}
		if p.Items[i].Quantity <= 0 {
			p.Items[i].Quantity = 1
		}
		authoritativeTotal += p.Items[i].UnitPrice * p.Items[i].Quantity
	}
	if authoritativeTotal > 0 {
		p.TotalAmount = authoritativeTotal
	}

	// 2. Lock student row to prevent concurrent race condition (double spending)
	var currentBalance int
	var isActive bool
	var dailyLimit int
	err = tx.QueryRow(ctx, `
		SELECT balance, is_active, daily_limit
		FROM public.students
		WHERE id = $1
		FOR UPDATE`, p.StudentID).Scan(&currentBalance, &isActive, &dailyLimit)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}

	if !isActive {
		return nil, ErrCardInactive
	}

	if currentBalance < p.TotalAmount {
		return nil, fmt.Errorf("%w (Saldo saat ini: Rp %d, Tagihan: Rp %d)", ErrInsufficientBalance, currentBalance, p.TotalAmount)
	}

	// 3. Validate Daily Limit if configured (> 0)
	if dailyLimit > 0 {
		var todaySpent int
		now := time.Now().UTC()
		startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
		_ = tx.QueryRow(ctx, `
			SELECT COALESCE(SUM(total_amount), 0)
			FROM public.transactions
			WHERE student_id = $1 AND type = 'purchase' AND status = 'success' AND created_at >= $2`,
			p.StudentID, startOfDay).Scan(&todaySpent)

		if todaySpent+p.TotalAmount > dailyLimit {
			return nil, fmt.Errorf("%w (Limit: Rp %d, Terpakai hari ini: Rp %d)", ErrDailyLimitExceeded, dailyLimit, todaySpent)
		}
	}

	// 4. Deduct student balance
	_, err = tx.Exec(ctx, `
		UPDATE public.students
		SET balance = balance - $1
		WHERE id = $2`, p.TotalAmount, p.StudentID)
	if err != nil {
		return nil, fmt.Errorf("gagal memotong saldo siswa: %w", err)
	}

	// 5. Increment canteen operator earned balance
	_, err = tx.Exec(ctx, `
		UPDATE public.canteen_operators
		SET balance_earned = balance_earned + $1
		WHERE id = $2`, p.TotalAmount, p.OperatorID)
	if err != nil {
		// If operator is not a canteen_operator (e.g. admin or test), it's safe to ignore
	}

	// 5. Insert transaction record
	var txRecord domain.Transaction
	txRecord.StudentID = p.StudentID
	txRecord.OperatorID = p.OperatorID
	txRecord.TotalAmount = p.TotalAmount
	txRecord.Type = domain.TxTypePurchase
	txRecord.Status = domain.TxStatusSuccess
	txRecord.PurchaseMethod = p.PurchaseMethod
	if txRecord.PurchaseMethod == "" {
		txRecord.PurchaseMethod = "cashless"
	}

	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`,
		txRecord.StudentID, txRecord.OperatorID, txRecord.TotalAmount, txRecord.Type, txRecord.Status, txRecord.PurchaseMethod,
	).Scan(&txRecord.ID, &txRecord.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("gagal mencatat transaksi: %w", err)
	}

	// 6. Insert transaction items
	for i := range p.Items {
		var itemID string
		err = tx.QueryRow(ctx, `
			INSERT INTO public.transaction_items (transaction_id, product_id, quantity, unit_price, custom_notes)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id`,
			txRecord.ID, p.Items[i].ProductID, p.Items[i].Quantity, p.Items[i].UnitPrice, p.Items[i].CustomNotes,
		).Scan(&itemID)
		if err != nil {
			return nil, fmt.Errorf("gagal mencatat item transaksi: %w", err)
		}
		p.Items[i].ID = itemID
		p.Items[i].TransactionID = txRecord.ID
	}

	// 7. Insert notification
	notifMsg := fmt.Sprintf("Pembayaran sukses senilai Rp %d di kantin sekolah.", p.TotalAmount)
	if p.DeliveryLoc != "" {
		notifMsg = fmt.Sprintf("Pembayaran sukses senilai Rp %d (%s) telah dikirim ke kantin.", p.TotalAmount, p.DeliveryLoc)
	}

	_, _ = tx.Exec(ctx, `
		INSERT INTO public.notifications (student_id, title, message, type)
		VALUES ($1, $2, $3, 'purchase')`,
		p.StudentID, "Transaksi Berhasil! 🛒", notifMsg,
	)

	// Commit Transaction
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("gagal commit transaksi finansial: %w", err)
	}

	txRecord.Items = p.Items
	return &txRecord, nil
}

// ProcessTopup adds balance to student from finance officer
func (r *TransactionRepo) ProcessTopup(ctx context.Context, studentID, officerID string, amount int) (*domain.Transaction, error) {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// 1. Add balance to student
	_, err = tx.Exec(ctx, `
		UPDATE public.students
		SET balance = balance + $1
		WHERE id = $2`, amount, studentID)
	if err != nil {
		return nil, err
	}

	// 2. Add managed funds to finance officer
	_, _ = tx.Exec(ctx, `
		UPDATE public.finance_officers
		SET total_managed_funds = total_managed_funds + $1
		WHERE id = $2`, amount, officerID)

	// 3. Record transaction
	var txRecord domain.Transaction
	txRecord.StudentID = studentID
	txRecord.OperatorID = officerID
	txRecord.TotalAmount = amount
	txRecord.Type = domain.TxTypeTopup
	txRecord.Status = domain.TxStatusSuccess
	txRecord.PurchaseMethod = "cash"

	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`,
		txRecord.StudentID, txRecord.OperatorID, txRecord.TotalAmount, txRecord.Type, txRecord.Status, txRecord.PurchaseMethod,
	).Scan(&txRecord.ID, &txRecord.CreatedAt)
	if err != nil {
		return nil, err
	}

	// 4. Notification
	notifMsg := fmt.Sprintf("Top-up saldo sebesar Rp %d berhasil ditambahkan ke akun Anda.", amount)
	_, _ = tx.Exec(ctx, `
		INSERT INTO public.notifications (student_id, title, message, type)
		VALUES ($1, $2, $3, 'topup')`,
		studentID, "Top-Up Saldo Berhasil! 💳", notifMsg,
	)

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &txRecord, nil
}

// ListTransactionsByStudent retrieves student transaction ledger
func (r *TransactionRepo) ListTransactionsByStudent(ctx context.Context, studentID string, limit int) ([]domain.Transaction, error) {
	list, _, err := r.ListTransactionsByStudentPaged(ctx, studentID, limit, 0, "", "", "")
	return list, err
}

// ListTransactionsByStudentPaged retrieves student transaction ledger with pagination, filters, and total count
func (r *TransactionRepo) ListTransactionsByStudentPaged(ctx context.Context, studentID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	if limit <= 0 {
		limit = 15
	}
	if offset < 0 {
		offset = 0
	}

	whereClause := ` WHERE t.student_id = $1`
	args := []interface{}{studentID}
	argIdx := 2

	if txType != "" && txType != "all" {
		whereClause += fmt.Sprintf(` AND t.type = $%d`, argIdx)
		args = append(args, txType)
		argIdx++
	}

	if status != "" && status != "all" {
		whereClause += fmt.Sprintf(` AND t.status = $%d`, argIdx)
		args = append(args, status)
		argIdx++
	}

	if search != "" {
		whereClause += fmt.Sprintf(` AND (COALESCE(c.canteen_name, p.full_name, '') ILIKE $%d OR t.id::text ILIKE $%d)`, argIdx, argIdx)
		args = append(args, "%"+search+"%")
		argIdx++
	}

	// 1. Total Count Query
	countQuery := `
		SELECT COUNT(t.id)
		FROM public.transactions t
		LEFT JOIN public.canteen_operators c ON c.id = t.operator_id
		LEFT JOIN public.profiles p ON p.id = t.operator_id` + whereClause

	var totalCount int
	_ = r.db.Pool.QueryRow(ctx, countQuery, args...).Scan(&totalCount)

	// 2. Data Query
	dataQuery := `
		SELECT t.id, t.student_id, t.operator_id, t.total_amount, t.type, t.status, t.purchase_method, t.created_at,
		       COALESCE(c.canteen_name, p.full_name, 'Kantin Sekolah') AS canteen_name
		FROM public.transactions t
		LEFT JOIN public.canteen_operators c ON c.id = t.operator_id
		LEFT JOIN public.profiles p ON p.id = t.operator_id` + whereClause +
		fmt.Sprintf(` ORDER BY t.created_at DESC LIMIT $%d OFFSET $%d`, argIdx, argIdx+1)

	args = append(args, limit, offset)

	rows, err := r.db.Pool.Query(ctx, dataQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var list []domain.Transaction
	for rows.Next() {
		var t domain.Transaction
		err := rows.Scan(
			&t.ID, &t.StudentID, &t.OperatorID, &t.TotalAmount, &t.Type, &t.Status, &t.PurchaseMethod, &t.CreatedAt,
			&t.CanteenName,
		)
		if err != nil {
			return nil, 0, err
		}
		list = append(list, t)
	}

	// Fetch items & product images for each student transaction
	for i := range list {
		itemsQuery := `
			SELECT ti.id, ti.transaction_id, ti.product_id, COALESCE(p.name, ''), ti.quantity, ti.unit_price, ti.custom_notes, p.image_url
			FROM public.transaction_items ti
			LEFT JOIN public.products p ON p.id = ti.product_id
			WHERE ti.transaction_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, list[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.TransactionItem
				var pName string
				if err := itemRows.Scan(&it.ID, &it.TransactionID, &it.ProductID, &pName, &it.Quantity, &it.UnitPrice, &it.CustomNotes, &it.ImageURL); err == nil {
					it.ProductName = &pName
					list[i].Items = append(list[i].Items, it)
					if list[i].ImageURL == nil && it.ImageURL != nil && *it.ImageURL != "" {
						list[i].ImageURL = it.ImageURL
					}
				}
			}
			itemRows.Close()
		}

		if len(list[i].Items) == 0 && list[i].Type == domain.TxTypePurchase {
			orderQuery := `
				SELECT oi.product_name, oi.quantity, oi.price, p.image_url
				FROM public.orders o
				JOIN public.order_items oi ON oi.order_id = o.id
				LEFT JOIN public.products p ON LOWER(p.name) = LOWER(oi.product_name)
				WHERE o.student_id = $1 AND o.operator_id = $2 AND o.total_amount = $3
				ORDER BY o.created_at DESC LIMIT 5`
			oRows, err := r.db.Pool.Query(ctx, orderQuery, list[i].StudentID, list[i].OperatorID, list[i].TotalAmount)
			if err == nil {
				for oRows.Next() {
					var pName string
					var qty, price int
					var imgURL *string
					if err := oRows.Scan(&pName, &qty, &price, &imgURL); err == nil {
						list[i].Items = append(list[i].Items, domain.TransactionItem{
							TransactionID: list[i].ID,
							ProductName:   &pName,
							Quantity:      qty,
							UnitPrice:     price,
							ImageURL:      imgURL,
						})
						if list[i].ImageURL == nil && imgURL != nil && *imgURL != "" {
							list[i].ImageURL = imgURL
						}
					}
				}
				oRows.Close()
			}
		}
	}

	return list, totalCount, nil
}

// ListTransactionsByOperator retrieves canteen stall transaction history
func (r *TransactionRepo) ListTransactionsByOperator(ctx context.Context, operatorID string, limit int) ([]domain.Transaction, error) {
	if limit <= 0 {
		limit = 50
	}

	query := `
		SELECT t.id, t.student_id, t.operator_id, t.total_amount, t.type, t.status, t.purchase_method, t.created_at,
		       p.full_name AS student_name
		FROM public.transactions t
		LEFT JOIN public.profiles p ON p.id = t.student_id
		WHERE t.operator_id = $1
		ORDER BY t.created_at DESC
		LIMIT $2`

	rows, err := r.db.Pool.Query(ctx, query, operatorID, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Transaction
	for rows.Next() {
		var t domain.Transaction
		err := rows.Scan(
			&t.ID, &t.StudentID, &t.OperatorID, &t.TotalAmount, &t.Type, &t.Status, &t.PurchaseMethod, &t.CreatedAt,
			&t.StudentName,
		)
		if err != nil {
			return nil, err
		}
		list = append(list, t)
	}

	for i := range list {
		itemsQuery := `
			SELECT ti.id, ti.transaction_id, ti.product_id, COALESCE(p.name, ''), ti.quantity, ti.unit_price, ti.custom_notes, p.image_url
			FROM public.transaction_items ti
			LEFT JOIN public.products p ON p.id = ti.product_id
			WHERE ti.transaction_id = $1`
		itemRows, err := r.db.Pool.Query(ctx, itemsQuery, list[i].ID)
		if err == nil {
			for itemRows.Next() {
				var it domain.TransactionItem
				var pName string
				if err := itemRows.Scan(&it.ID, &it.TransactionID, &it.ProductID, &pName, &it.Quantity, &it.UnitPrice, &it.CustomNotes, &it.ImageURL); err == nil {
					it.ProductName = &pName
					list[i].Items = append(list[i].Items, it)
					if list[i].ImageURL == nil && it.ImageURL != nil && *it.ImageURL != "" {
						list[i].ImageURL = it.ImageURL
					}
				}
			}
			itemRows.Close()
		}

		if len(list[i].Items) == 0 && list[i].Type == domain.TxTypePurchase {
			orderQuery := `
				SELECT oi.product_name, oi.quantity, oi.price, p.image_url
				FROM public.orders o
				JOIN public.order_items oi ON oi.order_id = o.id
				LEFT JOIN public.products p ON LOWER(p.name) = LOWER(oi.product_name)
				WHERE o.student_id = $1 AND o.operator_id = $2 AND o.total_amount = $3
				ORDER BY o.created_at DESC LIMIT 5`
			oRows, err := r.db.Pool.Query(ctx, orderQuery, list[i].StudentID, list[i].OperatorID, list[i].TotalAmount)
			if err == nil {
				for oRows.Next() {
					var pName string
					var qty, price int
					var imgURL *string
					if err := oRows.Scan(&pName, &qty, &price, &imgURL); err == nil {
						list[i].Items = append(list[i].Items, domain.TransactionItem{
							TransactionID: list[i].ID,
							ProductName:   &pName,
							Quantity:      qty,
							UnitPrice:     price,
							ImageURL:      imgURL,
						})
						if list[i].ImageURL == nil && imgURL != nil && *imgURL != "" {
							list[i].ImageURL = imgURL
						}
					}
				}
				oRows.Close()
			}
		}
	}

	return list, nil
}
