package postgres

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
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

	// 1. Authoritative price and product validation strictly from database
	authoritativeTotal := 0
	for i := range p.Items {
		productRef := ""
		if p.Items[i].ProductID != nil && strings.TrimSpace(*p.Items[i].ProductID) != "" {
			productRef = strings.TrimSpace(*p.Items[i].ProductID)
		} else if p.Items[i].ProductName != nil && strings.TrimSpace(*p.Items[i].ProductName) != "" {
			productRef = strings.TrimSpace(*p.Items[i].ProductName)
		}

		if productRef == "" {
			return nil, errors.New("setiap item transaksi wajib menyertakan ID produk (product_id)")
		}

		var dbID string
		var dbOperatorID string
		var dbName string
		var dbPrice int
		var isAvailable bool
		var optBytes []byte

		queryProduct := `
			SELECT id, operator_id, name, price, is_available, customizable_options
			FROM public.products
			WHERE id::text = $1 OR LOWER(name) = LOWER($1)
			LIMIT 1`
		err := tx.QueryRow(ctx, queryProduct, productRef).Scan(
			&dbID, &dbOperatorID, &dbName, &dbPrice, &isAvailable, &optBytes,
		)
		if err != nil {
			return nil, fmt.Errorf("produk '%s' tidak ditemukan di menu stan", productRef)
		}

		if !isAvailable {
			return nil, fmt.Errorf("produk '%s' sedang tidak tersedia (stok habis)", dbName)
		}

		if p.OperatorID != "" && !strings.EqualFold(dbOperatorID, p.OperatorID) {
			return nil, fmt.Errorf("produk '%s' bukan milik stan Anda", dbName)
		}

		if p.Items[i].Quantity <= 0 {
			p.Items[i].Quantity = 1
		}

		// Calculate extra option addons from authoritative DB options
		var dbOptions []string
		if len(optBytes) > 0 {
			_ = json.Unmarshal(optBytes, &dbOptions)
		}

		addonPrice := 0
		if p.Items[i].CustomNotes != nil && *p.Items[i].CustomNotes != "" {
			noteParts := strings.Split(*p.Items[i].CustomNotes, ",")
			for _, part := range noteParts {
				trimmed := strings.TrimSpace(part)
				if idx := strings.Index(trimmed, "|"); idx != -1 {
					trimmed = strings.TrimSpace(trimmed[:idx])
				}
				for _, validOpt := range dbOptions {
					if strings.EqualFold(validOpt, trimmed) ||
						strings.HasPrefix(strings.ToLower(validOpt), strings.ToLower(trimmed)) ||
						strings.HasPrefix(strings.ToLower(trimmed), strings.ToLower(validOpt)) {
						addonPrice += parseOptionAddonPrice(validOpt)
						break
					}
				}
			}
		}

		unitPrice := dbPrice + addonPrice
		p.Items[i].ProductID = &dbID
		p.Items[i].ProductName = &dbName
		p.Items[i].UnitPrice = unitPrice

		authoritativeTotal += unitPrice * p.Items[i].Quantity
	}

	if authoritativeTotal <= 0 {
		return nil, errors.New("total tagihan harus lebih dari 0")
	}
	p.TotalAmount = authoritativeTotal

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

	if !isProfileActive {
		return nil, fmt.Errorf("transaksi ditolak: Akun siswa sedang dinonaktifkan / diblokir oleh admin")
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
			WHERE student_id = $1 AND type = 'purchase' AND status IN ('success', 'pending') AND created_at >= $2`,
			p.StudentID, startOfDay).Scan(&todaySpent)

		if todaySpent+p.TotalAmount > dailyLimit {
			remainingLimit := dailyLimit - todaySpent
			if remainingLimit < 0 {
				remainingLimit = 0
			}
			return nil, fmt.Errorf("%w (Limit harian: Rp %d, Terpakai hari ini: Rp %d, Sisa limit: Rp %d)", ErrDailyLimitExceeded, dailyLimit, todaySpent, remainingLimit)
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
	return r.ProcessTopupWithMethod(ctx, studentID, officerID, amount, "cash")
}

// ProcessTopupWithMethod adds balance to student with specified payment method (e.g. "qris" or "cash")
func (r *TransactionRepo) ProcessTopupWithMethod(ctx context.Context, studentID, actorID string, amount int, method string) (*domain.Transaction, error) {
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

	if !isProfileActive {
		return nil, fmt.Errorf("top-up ditolak: Akun siswa sedang dinonaktifkan / diblokir oleh admin")
	}

	// 1. Add balance to student
	_, err = tx.Exec(ctx, `
		UPDATE public.students
		SET balance = balance + $1
		WHERE id = $2`, amount, studentID)
	if err != nil {
		return nil, err
	}

	// 2. Add managed funds to finance officer if actor is finance officer
	_, _ = tx.Exec(ctx, `
		UPDATE public.finance_officers
		SET total_managed_funds = total_managed_funds + $1
		WHERE id = $2`, amount, actorID)

	cleanMethod := strings.TrimSpace(strings.ToLower(method))
	if cleanMethod == "" {
		cleanMethod = "cash"
	}

	// 3. Record transaction. A student-raised request for this same amount is
	// settled in place rather than duplicated: leaving it pending would keep the
	// officer's worklist growing, eventually trip the per-student request cap in
	// CreateTopupRequest, and make reports count one top-up as two rows.
	var txRecord domain.Transaction
	txRecord.StudentID = studentID
	txRecord.OperatorID = actorID
	txRecord.TotalAmount = amount
	txRecord.Type = domain.TxTypeTopup
	txRecord.Status = domain.TxStatusSuccess
	txRecord.PurchaseMethod = cleanMethod

	balBefore := currentBalance
	balAfter := currentBalance + amount
	txRecord.BalanceBefore = &balBefore
	txRecord.BalanceAfter = &balAfter

	var stName, stNisn string
	_ = tx.QueryRow(ctx, `SELECT COALESCE(full_name, ''), COALESCE(nisn, '') FROM public.profiles WHERE id = $1`, studentID).Scan(&stName, &stNisn)
	if stName != "" {
		txRecord.StudentName = &stName
	}
	if stNisn != "" {
		txRecord.StudentNISN = &stNisn
	}

	err = tx.QueryRow(ctx, `
		UPDATE public.transactions
		SET status = $1, operator_id = $2, purchase_method = $3
		WHERE id = (
			SELECT id
			FROM public.transactions
			WHERE student_id = $4 AND type = 'topup' AND status = 'pending' AND total_amount = $5
			ORDER BY created_at
			LIMIT 1
			FOR UPDATE
		)
		RETURNING id, created_at`,
		txRecord.Status, txRecord.OperatorID, txRecord.PurchaseMethod, studentID, amount,
	).Scan(&txRecord.ID, &txRecord.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		// Walk-in top-up: the student never raised a request, so open a settled row.
		err = tx.QueryRow(ctx, `
			INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
			VALUES ($1, $2, $3, $4, $5, $6)
			RETURNING id, created_at`,
			txRecord.StudentID, txRecord.OperatorID, txRecord.TotalAmount, txRecord.Type, txRecord.Status, txRecord.PurchaseMethod,
		).Scan(&txRecord.ID, &txRecord.CreatedAt)
	}
	if err != nil {
		return nil, err
	}

	// 4. Notification
	methodLabel := strings.ToUpper(cleanMethod)
	notifMsg := fmt.Sprintf("Top-up saldo sebesar Rp %d via %s berhasil ditambahkan ke akun Anda.", amount, methodLabel)
	if cleanMethod == "cash" {
		notifMsg = fmt.Sprintf("Top-up saldo sebesar Rp %d berhasil ditambahkan ke akun Anda.", amount)
	}
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

// CreateTopupRequest records a top-up a student asked for but that nobody has
// paid for yet. It deliberately does NOT touch students.balance.
//
// ProcessTopup above is the settlement path and belongs to a finance officer who
// has physically received the cash. When a student calls the same endpoint for
// themselves there is no counterparty and no payment gateway callback, so
// crediting the balance there would let anyone mint their own money. This writes
// a 'pending' row instead: the request is queued for a finance officer, who
// settles it through the existing top-up flow once the money actually arrives.
func (r *TransactionRepo) CreateTopupRequest(ctx context.Context, studentID string, amount int) (*domain.Transaction, error) {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var isProfileActive bool
	err = tx.QueryRow(ctx, `
		SELECT p.is_active
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, studentID).Scan(&isProfileActive)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}
	if !isProfileActive {
		return nil, errors.New("permintaan top-up ditolak: Akun siswa sedang dinonaktifkan / diblokir oleh admin")
	}

	// Bound the queue so one student cannot flood the finance officer's worklist.
	var pendingCount int
	err = tx.QueryRow(ctx, `
		SELECT COUNT(*)
		FROM public.transactions
		WHERE student_id = $1 AND type = 'topup' AND status = 'pending'`, studentID).Scan(&pendingCount)
	if err != nil {
		return nil, err
	}
	if pendingCount >= 3 {
		return nil, errors.New("Anda masih memiliki permintaan top-up yang belum diproses. Tunggu konfirmasi petugas terlebih dahulu")
	}

	// operator_id is NOT NULL and there is no counterparty yet, so the request is
	// attributed to the student who raised it until a finance officer settles it.
	var txRecord domain.Transaction
	txRecord.StudentID = studentID
	txRecord.OperatorID = studentID
	txRecord.TotalAmount = amount
	txRecord.Type = domain.TxTypeTopup
	txRecord.Status = domain.TxStatusPending
	txRecord.PurchaseMethod = "pending_confirmation"

	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`,
		txRecord.StudentID, txRecord.OperatorID, txRecord.TotalAmount, txRecord.Type, txRecord.Status, txRecord.PurchaseMethod,
	).Scan(&txRecord.ID, &txRecord.CreatedAt)
	if err != nil {
		return nil, err
	}

	notifMsg := fmt.Sprintf("Permintaan top-up sebesar Rp %d telah kami terima. Saldo akan bertambah setelah petugas keuangan mengonfirmasi pembayaran Anda.", amount)
	_, _ = tx.Exec(ctx, `
		INSERT INTO public.notifications (student_id, title, message, type)
		VALUES ($1, $2, $3, 'topup')`,
		studentID, "Permintaan Top-Up Menunggu Konfirmasi", notifMsg,
	)

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return &txRecord, nil
}

// ProcessCorrection atomically adjusts a student's balance (either addition or deduction)
// with row-level locking, strict negative balance prevention, and records a 'correction' transaction.
func (r *TransactionRepo) ProcessCorrection(ctx context.Context, studentID, actorID string, amount int, reason string) (*domain.Transaction, error) {
	reason = strings.TrimSpace(reason)
	if reason == "" {
		return nil, errors.New("alasan koreksi saldo wajib diisi")
	}
	if amount == 0 {
		return nil, errors.New("nominal koreksi saldo tidak boleh nol")
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("gagal memulai database transaksi: %w", err)
	}
	defer tx.Rollback(ctx)

	// 1. Validate student and acquire row-level lock
	var currentBalance int
	var isProfileActive bool
	var fullName, nisn string

	err = tx.QueryRow(ctx, `
		SELECT s.balance, p.is_active, COALESCE(p.full_name, ''), COALESCE(p.nisn, '')
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1
		FOR UPDATE`, studentID).Scan(&currentBalance, &isProfileActive, &fullName, &nisn)
	if err != nil {
		return nil, fmt.Errorf("siswa tidak ditemukan: %w", err)
	}

	if !isProfileActive {
		return nil, errors.New("koreksi saldo ditolak: Akun siswa sedang dinonaktifkan / diblokir oleh admin")
	}

	newBalance := currentBalance + amount
	if newBalance < 0 {
		return nil, fmt.Errorf("koreksi ditolak: Saldo siswa saat ini (Rp %d) tidak mencukupi untuk pengurangan sebesar Rp %d (saldo akhir tidak boleh negatif)", currentBalance, -amount)
	}

	// 2. Update student balance
	_, err = tx.Exec(ctx, `
		UPDATE public.students
		SET balance = $1
		WHERE id = $2`, newBalance, studentID)
	if err != nil {
		return nil, fmt.Errorf("gagal memperbarui saldo siswa: %w", err)
	}

	// 3. Determine method and absolute total_amount
	absAmount := amount
	method := "credit"
	if amount < 0 {
		absAmount = -amount
		method = "debit"
	}

	// 4. Insert transaction record
	var txRecord domain.Transaction
	txRecord.StudentID = studentID
	txRecord.OperatorID = actorID
	txRecord.TotalAmount = absAmount
	txRecord.Type = domain.TxTypeCorrection
	txRecord.Status = domain.TxStatusSuccess
	txRecord.PurchaseMethod = method
	balBefore := currentBalance
	balAfter := newBalance
	txRecord.BalanceBefore = &balBefore
	txRecord.BalanceAfter = &balAfter
	if fullName != "" {
		txRecord.StudentName = &fullName
	}
	if nisn != "" {
		txRecord.StudentNISN = &nisn
	}

	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at`,
		txRecord.StudentID, txRecord.OperatorID, txRecord.TotalAmount, txRecord.Type, txRecord.Status, txRecord.PurchaseMethod,
	).Scan(&txRecord.ID, &txRecord.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("gagal mencatat transaksi koreksi: %w", err)
	}

	// 5. Insert transaction item for the explanation / reason
	itemCustomNotes := reason
	var itemID string
	err = tx.QueryRow(ctx, `
		INSERT INTO public.transaction_items (transaction_id, product_id, quantity, unit_price, custom_notes)
		VALUES ($1, NULL, 1, $2, $3)
		RETURNING id`,
		txRecord.ID, absAmount, itemCustomNotes,
	).Scan(&itemID)
	if err == nil {
		txRecord.Items = []domain.TransactionItem{
			{
				ID:            itemID,
				TransactionID: txRecord.ID,
				Quantity:      1,
				UnitPrice:     absAmount,
				CustomNotes:   &itemCustomNotes,
			},
		}
	}

	// 6. Notification to student
	var notifTitle, notifMsg string
	if amount > 0 {
		notifTitle = "Koreksi Saldo: Penambahan 💰"
		notifMsg = fmt.Sprintf("Saldo Anda telah ditambahkan sebesar Rp %d oleh Petugas Keuangan. Catatan: %s", absAmount, reason)
	} else {
		notifTitle = "Koreksi Saldo: Pengurangan ⚠️"
		notifMsg = fmt.Sprintf("Saldo Anda telah dikurangi sebesar Rp %d oleh Petugas Keuangan. Catatan: %s", absAmount, reason)
	}

	_, _ = tx.Exec(ctx, `
		INSERT INTO public.notifications (student_id, title, message, type)
		VALUES ($1, $2, $3, 'correction')`,
		studentID, notifTitle, notifMsg,
	)

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("gagal menyimpan perubahan koreksi: %w", err)
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
		SELECT t.id, t.student_id, 
		       COALESCE(t.operator_id, (
		           SELECT p2.operator_id 
		           FROM public.transaction_items ti2 
		           JOIN public.products p2 ON p2.id = ti2.product_id 
		           WHERE ti2.transaction_id = t.id 
		           LIMIT 1
		       )) AS operator_id,
		       t.total_amount, t.type, t.status, t.purchase_method, t.created_at,
		       COALESCE(c.canteen_name, (
		           SELECT co2.canteen_name 
		           FROM public.transaction_items ti2 
		           JOIN public.products p2 ON p2.id = ti2.product_id 
		           JOIN public.canteen_operators co2 ON co2.id = p2.operator_id 
		           WHERE ti2.transaction_id = t.id 
		           LIMIT 1
		       ), p.full_name, 'Kantin Sekolah') AS canteen_name,
		       COALESCE(p_st.full_name, 'Siswa') AS student_name,
		       p_st.nisn AS student_nisn,
		       COALESCE(p.full_name, '') AS operator_name,
		       COALESCE(p.role, '') AS operator_role
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
		var opName, opRole string
		err := rows.Scan(
			&t.ID, &t.StudentID, &t.OperatorID, &t.TotalAmount, &t.Type, &t.Status, &t.PurchaseMethod, &t.CreatedAt,
			&t.CanteenName, &t.StudentName, &t.StudentNISN,
			&opName, &opRole,
		)
		if err != nil {
			return nil, 0, err
		}
		if opName != "" {
			t.OperatorName = &opName
		}
		if opRole != "" {
			t.OperatorRole = &opRole
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
	PayoutTodayAmount       int                  `json:"payout_today_amount"`
	PayoutTodayCount        int                  `json:"payout_today_count"`
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
		WHERE type = 'topup' AND status = 'success' AND created_at >= CURRENT_DATE
	`).Scan(&s.TopupTodayAmount, &s.TopupTodayCount)

	// 3. Payout today
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'withdrawal' AND status = 'success' AND created_at >= CURRENT_DATE
	`).Scan(&s.PayoutTodayAmount, &s.PayoutTodayCount)

	// 4. Recent transactions
	txs, _, err := r.ListTransactionsPaged(ctx, "", "", 10, 0, "", "", "")
	if err == nil {
		s.RecentTransactions = txs
	}

	return &s, nil
}

type AdminSummary struct {
	UserCount      int                    `json:"user_count"`
	GlobalBalance  int                    `json:"global_balance"`
	DailyVolume    int                    `json:"daily_volume"`
	TxCountToday   int                    `json:"tx_count_today"`
	DailyTrend     []int                  `json:"daily_trend"`
	RecentActivity []domain.Transaction   `json:"recent_activity"`
	RoleCounts     map[string]int         `json:"role_counts"`
	SystemHealth   map[string]interface{} `json:"system_health"`
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
	txs, _, err := r.ListTransactionsPaged(ctx, "", "", 10, 0, "", "", "")
	if err == nil {
		s.RecentActivity = txs
	}

	// 6. Role breakdown counts
	s.RoleCounts = make(map[string]int)
	roleRows, err := r.db.Pool.Query(ctx, `SELECT role, COUNT(*) FROM public.profiles GROUP BY role`)
	if err == nil {
		for roleRows.Next() {
			var role string
			var count int
			if err := roleRows.Scan(&role, &count); err == nil {
				s.RoleCounts[role] = count
			}
		}
		roleRows.Close()
	}

	// 7. System health status
	s.SystemHealth = map[string]interface{}{
		"status":       "Optimal",
		"api_latency":  "12 ms",
		"db_status":    "PostgreSQL 16 (Online)",
		"db_capacity":  "8%",
		"success_rate": "100%",
	}

	return &s, nil
}

// ProcessCorrection executes balance correction with audit and transaction records

// ProcessMerchantWithdrawal processes a cashier withdrawal / payout of earned balance
func (r *TransactionRepo) ProcessMerchantWithdrawal(ctx context.Context, operatorID, actorID string, amount int, notes, method string) (*domain.Transaction, error) {
	if amount <= 0 {
		return nil, fmt.Errorf("nominal penarikan harus lebih dari 0")
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var currentEarned int
	var canteenName string
	err = tx.QueryRow(ctx, `
		SELECT balance_earned, canteen_name
		FROM public.canteen_operators
		WHERE id = $1
		FOR UPDATE`, operatorID).Scan(&currentEarned, &canteenName)
	if err != nil {
		return nil, fmt.Errorf("operator kantin tidak ditemukan: %w", err)
	}

	if currentEarned < amount {
		return nil, fmt.Errorf("penarikan ditolak: saldo pendapatan stan tidak mencukupi (saldo saat ini: Rp %d, penarikan: Rp %d)", currentEarned, amount)
	}

	newBalance := currentEarned - amount
	_, err = tx.Exec(ctx, `UPDATE public.canteen_operators SET balance_earned = $1 WHERE id = $2`, newBalance, operatorID)
	if err != nil {
		return nil, err
	}

	if method == "" {
		method = "cash_payout"
	}

	var txID string
	var createdAt time.Time
	err = tx.QueryRow(ctx, `
		INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method, created_at)
		VALUES ($1, $2, $3, 'withdrawal', 'success', $4, NOW())
		RETURNING id, created_at`,
		actorID, operatorID, amount, method,
	).Scan(&txID, &createdAt)
	if err != nil {
		return nil, err
	}

	notifMsg := fmt.Sprintf("Pencairan dana stan %s sebesar Rp %d berhasil diproses. Sisa saldo pendapatan: Rp %d.", canteenName, amount, newBalance)
	_, _ = tx.Exec(ctx, `INSERT INTO public.notifications (student_id, title, message, type) VALUES ($1, 'Pencairan Dana Stan 💵', $2, 'general')`, operatorID, notifMsg)

	// The audit row is built with json_build_object and its error is propagated on
	// purpose. It used to be assembled with fmt.Sprintf, so a quote or a backslash
	// in `notes` produced malformed JSON; the resulting cast error was assigned to
	// `_`, which meant the payout still committed with no trace of who authorised
	// it. For a money-moving operation the audit entry is part of the transaction,
	// not a best-effort side note: if it cannot be written, the payout rolls back.
	_, err = tx.Exec(ctx, `
		INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, old_data, new_data, created_at)
		VALUES (
			$1, 'MERCHANT_PAYOUT', 'canteen_operators', $2,
			json_build_object('balance_earned', $3::bigint)::jsonb,
			json_build_object(
				'balance_earned', $4::bigint,
				'amount', $5::bigint,
				'notes', $6::text,
				'method', $7::text
			)::jsonb,
			NOW()
		)
	`, actorID, operatorID, currentEarned, newBalance, amount, notes, method)
	if err != nil {
		return nil, fmt.Errorf("gagal mencatat log audit pencairan dana: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &domain.Transaction{
		ID:             txID,
		StudentID:      actorID,
		OperatorID:     operatorID,
		TotalAmount:    amount,
		Type:           domain.TxTypeWithdrawal,
		Status:         domain.TxStatusSuccess,
		PurchaseMethod: method,
		CanteenName:    &canteenName,
		CreatedAt:      createdAt,
	}, nil
}

// ProcessMerchantAdjustment processes balance adjustment (addition or deduction) on a canteen operator

type FinanceReport struct {
	TotalTopup              int                      `json:"total_topup"`
	TotalPurchase           int                      `json:"total_purchase"`
		TotalWithdrawal         int                      `json:"total_withdrawal"`
	TopupCount              int                      `json:"topup_count"`
	PurchaseCount           int                      `json:"purchase_count"`
	WithdrawalCount         int                      `json:"withdrawal_count"`
	TotalUnpaidMerchantEarn int                      `json:"total_unpaid_merchant_earn"`
	TotalCirculatingFloat   int                      `json:"total_circulating_float"`
	Canteens                []map[string]interface{} `json:"canteens"`
}

// GetFinanceReport aggregates report for given date range
func (r *TransactionRepo) GetFinanceReport(ctx context.Context, startDate, endDate time.Time) (*FinanceReport, error) {
	var rep FinanceReport

	// 1. Total topup
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'topup' AND status = 'success' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalTopup, &rep.TopupCount)

	// 2. Total purchase
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'purchase' AND status = 'success' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalPurchase, &rep.PurchaseCount)

	// 4. Total merchant withdrawal / payout
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(*)
		FROM public.transactions
		WHERE type = 'withdrawal' AND status = 'success' AND created_at >= $1 AND created_at <= $2
	`, startDate, endDate).Scan(&rep.TotalWithdrawal, &rep.WithdrawalCount)

	// 5. Total unpaid merchant balance & total student float
	_ = r.db.Pool.QueryRow(ctx, `SELECT COALESCE(SUM(balance_earned), 0) FROM public.canteen_operators`).Scan(&rep.TotalUnpaidMerchantEarn)
	_ = r.db.Pool.QueryRow(ctx, `SELECT COALESCE(SUM(balance), 0) FROM public.students`).Scan(&rep.TotalCirculatingFloat)

	// 6. Per-canteen performance
	canteenQuery := `
		SELECT c.id, c.canteen_name,
		       COALESCE(SUM(t.total_amount), 0) as total_sales,
		       COUNT(t.id) as tx_count,
		       COALESCE(c.balance_earned, 0) as balance_earned
		FROM public.canteen_operators c
		LEFT JOIN public.transactions t ON t.operator_id = c.id AND t.type = 'purchase' AND t.status = 'success' AND t.created_at >= $1 AND t.created_at <= $2
		GROUP BY c.id, c.canteen_name, c.balance_earned
		ORDER BY total_sales DESC`

	rows, err := r.db.Pool.Query(ctx, canteenQuery, startDate, endDate)
	if err == nil {
		defer rows.Close()
		for rows.Next() {
			var id, name string
			var sales, count, balanceEarned int
			if err := rows.Scan(&id, &name, &sales, &count, &balanceEarned); err == nil {
				rep.Canteens = append(rep.Canteens, map[string]interface{}{
					"canteen_id":      id,
					"canteen_name":    name,
					"total_sales":     sales,
					"balance_earned":  sales, // Penjualan pada periode filter
					"current_balance": balanceEarned,
					"tx_count":        count,
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
