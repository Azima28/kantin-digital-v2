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
	var isCardActive bool
	var dailyLimit int
	var isProfileActive bool
	var rfidUID *string

	err = tx.QueryRow(ctx, `
		SELECT s.balance, s.is_active, s.daily_limit, p.is_active, s.rfid_uid
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, p.StudentID).Scan(&currentBalance, &isCardActive, &dailyLimit, &isProfileActive, &rfidUID)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}

	if rfidUID == nil || *rfidUID == "" {
		return nil, fmt.Errorf("transaksi ditolak: Kartu RFID siswa belum didaftarkan")
	}

	if !isCardActive {
		return nil, fmt.Errorf("transaksi ditolak: Kartu RFID siswa sedang diblokir / dibekukan")
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

	// Validate student state
	var currentBalance int
	var isCardActive bool
	var isProfileActive bool
	var rfidUID *string

	err = tx.QueryRow(ctx, `
		SELECT s.balance, s.is_active, p.is_active, s.rfid_uid
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, studentID).Scan(&currentBalance, &isCardActive, &isProfileActive, &rfidUID)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}

	if rfidUID == nil || *rfidUID == "" {
		return nil, fmt.Errorf("top-up ditolak: Siswa belum memiliki kartu RFID yang terdaftar. Daftarkan kartu terlebih dahulu")
	}

	if !isCardActive {
		return nil, fmt.Errorf("top-up ditolak: Kartu RFID siswa sedang diblokir / dibekukan. Buka blokir kartu terlebih dahulu")
	}

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
	list, _, err := r.ListTransactionsPaged(ctx, studentID, "", limit, 0, "", "", "")
	return list, err
}

// ListTransactionsByStudentPaged retrieves student transaction ledger with pagination, filters, and total count
func (r *TransactionRepo) ListTransactionsByStudentPaged(ctx context.Context, studentID, operatorID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	return r.ListTransactionsPaged(ctx, studentID, operatorID, limit, offset, txType, status, search)
}

// ListTransactionsPaged retrieves transaction ledger with pagination, filters, and total count (optional studentID, optional operatorID)
func (r *TransactionRepo) ListTransactionsPaged(ctx context.Context, studentID, operatorID string, limit, offset int, txType, status, search string) ([]domain.Transaction, int, error) {
	if limit <= 0 {
		limit = 15
	}
	if offset < 0 {
		offset = 0
	}

	whereClause := ` WHERE 1=1`
	var args []interface{}
	argIdx := 1

	if studentID != "" {
		whereClause += fmt.Sprintf(` AND t.student_id = $%d`, argIdx)
		args = append(args, studentID)
		argIdx++
	}

	if operatorID != "" {
		whereClause += fmt.Sprintf(` AND t.operator_id = $%d`, argIdx)
		args = append(args, operatorID)
		argIdx++
	}

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
		       COALESCE(c.canteen_name, p.full_name, 'Kantin Sekolah') AS canteen_name,
		       COALESCE(p_st.full_name, 'Siswa') AS student_name,
		       p_st.nisn AS student_nisn
		FROM public.transactions t
		LEFT JOIN public.canteen_operators c ON c.id = t.operator_id
		LEFT JOIN public.profiles p ON p.id = t.operator_id
		LEFT JOIN public.profiles p_st ON p_st.id = t.student_id` + whereClause +
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
			&t.CanteenName, &t.StudentName, &t.StudentNISN,
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

// GetOperatorSalesStats computes daily and monthly sales aggregated for an operator
func (r *TransactionRepo) GetOperatorSalesStats(ctx context.Context, operatorID string) (dailySales, monthlySales float64, err error) {
	dailyQuery := `
		SELECT COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'purchase' AND status = 'success' AND created_at >= CURRENT_DATE`
	_ = r.db.Pool.QueryRow(ctx, dailyQuery, operatorID).Scan(&dailySales)

	monthlyQuery := `
		SELECT COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'purchase' AND status = 'success' AND created_at >= date_trunc('month', CURRENT_DATE)`
	_ = r.db.Pool.QueryRow(ctx, monthlyQuery, operatorID).Scan(&monthlySales)

	return dailySales, monthlySales, nil
}

// ListTransactionsByOperator retrieves canteen stall transaction history
func (r *TransactionRepo) ListTransactionsByOperator(ctx context.Context, operatorID string, limit int) ([]domain.Transaction, error) {
	if limit <= 0 {
		limit = 50
	}

	query := `
		SELECT t.id, t.student_id, t.operator_id, t.total_amount, t.type, t.status, t.purchase_method, t.created_at,
		       p.full_name AS student_name,
		       p.nisn AS student_nisn
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
			&t.StudentName, &t.StudentNISN,
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

type FinanceSummary struct {
	TotalCirculatingBalance int                  `json:"total_circulating_balance"`
	TopupTodayAmount        int                  `json:"topup_today_amount"`
	TopupTodayCount         int                  `json:"topup_today_count"`
	KoreksiTodayCount       int                  `json:"koreksi_today_count"`
	KoreksiTodayNet         int                  `json:"koreksi_today_net"`
	RecentTransactions      []domain.Transaction `json:"recent_transactions"`
}

// GetFinanceDashboardSummary aggregates statistics for finance dashboard
func (r *TransactionRepo) GetFinanceDashboardSummary(ctx context.Context) (*FinanceSummary, error) {
	var s FinanceSummary

	// 1. Total circulating balance
	_ = r.db.Pool.QueryRow(ctx, `SELECT COALESCE(SUM(balance), 0) FROM public.students`).Scan(&s.TotalCirculatingBalance)

	// 2. Top-up today
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'topup' AND created_at >= CURRENT_DATE
	`).Scan(&s.TopupTodayAmount, &s.TopupTodayCount)

	// 3. Corrections today
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COUNT(*), COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE type = 'correction' AND created_at >= CURRENT_DATE
	`).Scan(&s.KoreksiTodayCount, &s.KoreksiTodayNet)

	// 4. Recent transactions
	txs, _, err := r.ListTransactionsPaged(ctx, "", 10, 0, "", "", "")
	if err == nil {
		s.RecentTransactions = txs
	}

	return &s, nil
}

type AdminSummary struct {
	UserCount      int                  `json:"user_count"`
	GlobalBalance  int                  `json:"global_balance"`
	DailyVolume    int                  `json:"daily_volume"`
	TxCountToday   int                  `json:"tx_count_today"`
	DailyTrend     []int                `json:"daily_trend"`
	RecentActivity []domain.Transaction `json:"recent_activity"`
}

// GetAdminDashboardSummary aggregates statistics for super admin dashboard
func (r *TransactionRepo) GetAdminDashboardSummary(ctx context.Context) (*AdminSummary, error) {
	var s AdminSummary

	// 1. User count
	_ = r.db.Pool.QueryRow(ctx, `SELECT COUNT(*) FROM public.profiles`).Scan(&s.UserCount)

	// 2. Global balance
	_ = r.db.Pool.QueryRow(ctx, `SELECT COALESCE(SUM(balance), 0) FROM public.students`).Scan(&s.GlobalBalance)

	// 3. Daily volume (purchase)
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'purchase' AND created_at >= CURRENT_DATE
	`).Scan(&s.DailyVolume, &s.TxCountToday)

	// 4. Daily trend (past 30 days)
	s.DailyTrend = make([]int, 30)
	trendQuery := `
		SELECT (CURRENT_DATE - created_at::date) as day_diff, COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE type = 'purchase' AND created_at >= (CURRENT_DATE - INTERVAL '29 days')
		GROUP BY day_diff
		ORDER BY day_diff ASC`
	rows, err := r.db.Pool.Query(ctx, trendQuery)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var dayDiff, vol int
			if err := rows.Scan(&dayDiff, &vol); err == nil && dayDiff >= 0 && dayDiff < 30 {
				s.DailyTrend[29-dayDiff] = vol
			}
		}
	}

	// 5. Recent transactions
	txs, _, err := r.ListTransactionsPaged(ctx, "", 10, 0, "", "", "")
	if err == nil {
		s.RecentActivity = txs
	}

	return &s, nil
}

// ProcessCorrection executes balance correction with audit and transaction records
func (r *TransactionRepo) ProcessCorrection(ctx context.Context, studentID, officerID string, amount int, reason string) (*domain.Transaction, error) {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var currentBalance int
	var isProfileActive bool
	var rfidUID *string

	err = tx.QueryRow(ctx, `
		SELECT s.balance, p.is_active, s.rfid_uid
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, studentID).Scan(&currentBalance, &isProfileActive, &rfidUID)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}

	if !isProfileActive {
		return nil, fmt.Errorf("koreksi ditolak: Akun siswa sedang dinonaktifkan oleh pihak sekolah")
	}

	if rfidUID == nil || *rfidUID == "" {
		return nil, fmt.Errorf("koreksi ditolak: Siswa belum memiliki kartu RFID yang terdaftar. Daftarkan kartu terlebih dahulu")
	}

	newBalance := currentBalance + amount
	if newBalance < 0 {
		return nil, fmt.Errorf("koreksi ditolak: saldo tidak boleh menjadi negatif (saldo saat ini: Rp %d, koreksi: Rp %d)", currentBalance, amount)
	}

	_, err = tx.Exec(ctx, `UPDATE public.students SET balance = $1 WHERE id = $2`, newBalance, studentID)
	if err != nil {
		return nil, err
	}

	absAmount := amount
	if absAmount < 0 {
		absAmount = -absAmount
	}

	var txID string
	var createdAt time.Time
	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method, created_at)
		VALUES ($1, $2, $3, 'correction', 'success', 'manual_adjustment', NOW())
		RETURNING id, created_at`,
		studentID, officerID, absAmount,
	).Scan(&txID, &createdAt)
	if err != nil {
		return nil, err
	}

	notifMsg := fmt.Sprintf("Koreksi saldo sebesar Rp %d (%s). Saldo Anda sekarang Rp %d.", amount, reason, newBalance)
	_, _ = tx.Exec(ctx, `INSERT INTO public.notifications (student_id, title, message, type) VALUES ($1, 'Penyesuaian Saldo ℹ️', $2, 'correction')`, studentID, notifMsg)

	_, _ = tx.Exec(ctx, `
		INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, old_data, new_data, created_at)
		VALUES ($1, 'KOREKSI_SALDO', 'students', $2, $3, $4, NOW())
	`, officerID, studentID, fmt.Sprintf(`{"balance": %d}`, currentBalance), fmt.Sprintf(`{"balance": %d, "amount": %d, "reason": "%s"}`, newBalance, amount, reason))

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &domain.Transaction{
		ID:             txID,
		StudentID:      studentID,
		OperatorID:     officerID,
		TotalAmount:    absAmount,
		Type:           domain.TxTypeCorrection,
		Status:         domain.TxStatusSuccess,
		PurchaseMethod: "manual_adjustment",
		CreatedAt:      createdAt,
	}, nil
}

type FinanceReport struct {
	TotalTopup       int                      `json:"total_topup"`
	TotalPurchase    int                      `json:"total_purchase"`
	TotalCorrection  int                      `json:"total_correction"`
	TopupCount       int                      `json:"topup_count"`
	PurchaseCount    int                      `json:"purchase_count"`
	Canteens         []map[string]interface{} `json:"canteens"`
}

// GetFinanceReport aggregates report for given date range
func (r *TransactionRepo) GetFinanceReport(ctx context.Context, startDate, endDate time.Time) (*FinanceReport, error) {
	var rep FinanceReport

	// 1. Total topup
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'topup' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalTopup, &rep.TopupCount)

	// 2. Total purchase
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'purchase' AND status = 'success' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalPurchase, &rep.PurchaseCount)

	// 3. Total correction
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE type = 'correction' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalCorrection)

	// 4. Per-canteen performance
	canteenQuery := `
		SELECT c.id, c.canteen_name, COALESCE(SUM(t.total_amount), 0) as total_sales, COUNT(t.id) as tx_count
		FROM public.canteen_operators c
		LEFT JOIN public.transactions t ON t.operator_id = c.id AND t.type = 'purchase' AND t.status = 'success' AND t.created_at >= $1 AND t.created_at <= $2
		GROUP BY c.id, c.canteen_name
		ORDER BY total_sales DESC`

	rows, err := r.db.Pool.Query(ctx, canteenQuery, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var id, name string
			var sales, count int
			if err := rows.Scan(&id, &name, &sales, &count); err == nil {
				rep.Canteens = append(rep.Canteens, map[string]interface{}{
					"canteen_id":   id,
					"canteen_name": name,
					"total_sales":  sales,
					"tx_count":     count,
				})
			}
		}
	}

	return &rep, nil
}

type StudentSpendingStats struct {
	WeeklySpending   []int                    `json:"weekly_spending"`
	FavoriteProducts []map[string]interface{} `json:"favorite_products"`
}

// GetStudentSpendingStats aggregates stats for student & parent dashboard
func (r *TransactionRepo) GetStudentSpendingStats(ctx context.Context, studentID string) (*StudentSpendingStats, error) {
	var s StudentSpendingStats
	s.WeeklySpending = make([]int, 7)

	// Weekly spending (last 7 days)
	trendQuery := `
		SELECT (CURRENT_DATE - created_at::date) as day_diff, COALESCE(SUM(total_amount), 0)
		FROM public.transactions
		WHERE student_id = $1 AND type = 'purchase' AND status = 'success' AND created_at >= (CURRENT_DATE - INTERVAL '6 days')
		GROUP BY day_diff
		ORDER BY day_diff ASC`
	rows, err := r.db.Pool.Query(ctx, trendQuery, studentID)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var dayDiff, vol int
			if err := rows.Scan(&dayDiff, &vol); err == nil && dayDiff >= 0 && dayDiff < 7 {
				s.WeeklySpending[6-dayDiff] = vol
			}
		}
	}

	// Favorite products
	favQuery := `
		SELECT ti.product_id, COALESCE(p.name, 'Menu Kantin'), COALESCE(p.image_url, ''), SUM(ti.quantity) as total_qty, COALESCE(p.price, 0)
		FROM public.transaction_items ti
		JOIN public.transactions t ON t.id = ti.transaction_id
		LEFT JOIN public.products p ON p.id = ti.product_id
		WHERE t.student_id = $1 AND t.type = 'purchase' AND t.status = 'success'
		GROUP BY ti.product_id, p.name, p.image_url, p.price
		ORDER BY total_qty DESC
		LIMIT 5`
	fRows, err := r.db.Pool.Query(ctx, favQuery, studentID)
	if err == nil {
		defer fRows.Close()
		for fRows.Next() {
			var pid *string
			var name, imgURL string
			var qty, price int
			if err := fRows.Scan(&pid, &name, &imgURL, &qty, &price); err == nil {
				s.FavoriteProducts = append(s.FavoriteProducts, map[string]interface{}{
					"product_id": pid,
					"name":       name,
					"image_url":  imgURL,
					"quantity":   qty,
					"price":      price,
				})
			}
		}
	}

	return &s, nil
}
