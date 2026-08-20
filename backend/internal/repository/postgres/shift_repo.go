package postgres

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

type ShiftRepo struct {
	db *DB
}

func NewShiftRepo(db *DB) *ShiftRepo {
	repo := &ShiftRepo{db: db}
	repo.ensureSchema(context.Background())
	return repo
}

func (r *ShiftRepo) ensureSchema(ctx context.Context) {
	if r.db == nil || r.db.Pool == nil {
		return
	}
	_, _ = r.db.Pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS public.cashier_shifts (
			id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
			officer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
			shift_number INTEGER NOT NULL DEFAULT 1,
			started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
			closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
			starting_cash INTEGER NOT NULL DEFAULT 0,
			total_inflow INTEGER NOT NULL DEFAULT 0,
			total_outflow INTEGER NOT NULL DEFAULT 0,
			expected_cash INTEGER NOT NULL DEFAULT 0,
			actual_physical_cash INTEGER NOT NULL DEFAULT 0,
			difference INTEGER NOT NULL DEFAULT 0,
			topup_count INTEGER NOT NULL DEFAULT 0,
			payout_count INTEGER NOT NULL DEFAULT 0,
			notes TEXT DEFAULT '',
			status TEXT NOT NULL DEFAULT 'closed' CHECK (status IN ('active', 'closed', 'verified')),
			verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
			verified_at TIMESTAMPTZ,
			created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);

		CREATE INDEX IF NOT EXISTS idx_cashier_shifts_officer_id ON public.cashier_shifts(officer_id);
		CREATE INDEX IF NOT EXISTS idx_cashier_shifts_closed_at ON public.cashier_shifts(closed_at DESC);
	`)
}

// GetCurrentShiftSummary calculates live stats for current active shift since last closed shift
func (r *ShiftRepo) GetCurrentShiftSummary(ctx context.Context, officerID string) (*domain.CurrentShiftSummary, error) {
	if r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}

	// 1. Get Officer Name & created_at
	var officerName string
	var officerCreatedAt time.Time
	err := r.db.Pool.QueryRow(ctx, `
		SELECT full_name, created_at FROM public.profiles WHERE id = $1`, officerID).Scan(&officerName, &officerCreatedAt)
	if err != nil {
		return nil, fmt.Errorf("petugas keuangan tidak ditemukan: %w", err)
	}

	// 2. Find last closed shift for this officer
	var lastClosedAt *time.Time
	var lastShiftNumber int
	err = r.db.Pool.QueryRow(ctx, `
		SELECT closed_at, shift_number
		FROM public.cashier_shifts
		WHERE officer_id = $1
		ORDER BY closed_at DESC
		LIMIT 1`, officerID).Scan(&lastClosedAt, &lastShiftNumber)

	startedAt := officerCreatedAt
	nextShiftNumber := 1
	if err == nil && lastClosedAt != nil {
		startedAt = *lastClosedAt
		nextShiftNumber = lastShiftNumber + 1
	}

	// 3. Calculate total inflow (Top-Up Tunai) since startedAt
	var totalInflow int
	var topupCount int
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(id)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'topup' AND status = 'success' AND created_at > $2`,
		officerID, startedAt).Scan(&totalInflow, &topupCount)

	// 4. Calculate total outflow (Pencairan Kas Stan) since startedAt
	var totalOutflow int
	var payoutCount int
	_ = r.db.Pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(id)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'withdrawal' AND status = 'success' AND created_at > $2`,
		officerID, startedAt).Scan(&totalOutflow, &payoutCount)

	expectedCash := totalInflow - totalOutflow

	return &domain.CurrentShiftSummary{
		OfficerID:    officerID,
		OfficerName:  officerName,
		ShiftNumber:  nextShiftNumber,
		StartedAt:    startedAt,
		TotalInflow:  totalInflow,
		TotalOutflow: totalOutflow,
		ExpectedCash: expectedCash,
		TopupCount:   topupCount,
		PayoutCount:  payoutCount,
		LastClosedAt: lastClosedAt,
	}, nil
}

type CloseShiftParams struct {
	OfficerID          string
	ActualPhysicalCash int
	Notes              string
}

// CloseCurrentShift atomizes closing the current shift, recording physical money, notes, and resetting shift counter
func (r *ShiftRepo) CloseCurrentShift(ctx context.Context, p CloseShiftParams) (*domain.CashierShift, error) {
	if r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// 1. Lock and fetch Officer info
	var officerName string
	var officerCreatedAt time.Time
	err = tx.QueryRow(ctx, `
		SELECT full_name, created_at FROM public.profiles WHERE id = $1 FOR UPDATE`, p.OfficerID).Scan(&officerName, &officerCreatedAt)
	if err != nil {
		return nil, fmt.Errorf("petugas keuangan tidak ditemukan: %w", err)
	}

	// 2. Find last closed shift
	var lastClosedAt *time.Time
	var lastShiftNumber int
	err = tx.QueryRow(ctx, `
		SELECT closed_at, shift_number
		FROM public.cashier_shifts
		WHERE officer_id = $1
		ORDER BY closed_at DESC
		LIMIT 1`, p.OfficerID).Scan(&lastClosedAt, &lastShiftNumber)

	startedAt := officerCreatedAt
	shiftNumber := 1
	if err == nil && lastClosedAt != nil {
		startedAt = *lastClosedAt
		shiftNumber = lastShiftNumber + 1
	}

	// 3. Calculate authoritative summary
	var totalInflow int
	var topupCount int
	_ = tx.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(id)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'topup' AND status = 'success' AND created_at > $2`,
		p.OfficerID, startedAt).Scan(&totalInflow, &topupCount)

	var totalOutflow int
	var payoutCount int
	_ = tx.QueryRow(ctx, `
		SELECT COALESCE(SUM(total_amount), 0), COUNT(id)
		FROM public.transactions
		WHERE operator_id = $1 AND type = 'withdrawal' AND status = 'success' AND created_at > $2`,
		p.OfficerID, startedAt).Scan(&totalOutflow, &payoutCount)

	expectedCash := totalInflow - totalOutflow
	difference := p.ActualPhysicalCash - expectedCash
	closedAt := time.Now().UTC()

	// 4. Insert into cashier_shifts
	var shift domain.CashierShift
	shift.OfficerID = p.OfficerID
	shift.OfficerName = officerName
	shift.ShiftNumber = shiftNumber
	shift.StartedAt = startedAt
	shift.ClosedAt = &closedAt
	shift.StartingCash = 0
	shift.TotalInflow = totalInflow
	shift.TotalOutflow = totalOutflow
	shift.ExpectedCash = expectedCash
	shift.ActualPhysicalCash = p.ActualPhysicalCash
	shift.Difference = difference
	shift.TopupCount = topupCount
	shift.PayoutCount = payoutCount
	shift.Notes = strings.TrimSpace(p.Notes)
	shift.Status = domain.ShiftStatusClosed

	err = tx.QueryRow(ctx, `
		INSERT INTO public.cashier_shifts (
			officer_id, shift_number, started_at, closed_at, starting_cash,
			total_inflow, total_outflow, expected_cash, actual_physical_cash,
			difference, topup_count, payout_count, notes, status
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		RETURNING id, created_at`,
		shift.OfficerID, shift.ShiftNumber, shift.StartedAt, shift.ClosedAt, shift.StartingCash,
		shift.TotalInflow, shift.TotalOutflow, shift.ExpectedCash, shift.ActualPhysicalCash,
		shift.Difference, shift.TopupCount, shift.PayoutCount, shift.Notes, shift.Status,
	).Scan(&shift.ID, &shift.CreatedAt)
	if err != nil {
		return nil, fmt.Errorf("gagal menyimpan sesi tutup kasir: %w", err)
	}

	// 5. Log audit trail
	auditDesc := fmt.Sprintf("Tutup Kasir Shift #%d: Fisik Rp %d (Sistem Rp %d, Selisih Rp %d). Top-Up: %d txn, Cair Stan: %d txn.",
		shiftNumber, p.ActualPhysicalCash, expectedCash, difference, topupCount, payoutCount)
	if shift.Notes != "" {
		auditDesc += fmt.Sprintf(" Catatan: %s", shift.Notes)
	}

	_, _ = tx.Exec(ctx, `
		INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, old_data, new_data)
		VALUES ($1, 'TUTUP_KASIR_SHIFT', 'cashier_shifts', $2, '{}'::jsonb, json_build_object('desc', $3::text)::jsonb)`,
		p.OfficerID, shift.ID, auditDesc)

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("gagal commit shift: %w", err)
	}

	return &shift, nil
}

// ListShifts retrieves closed shifts with pagination and optional officer filter
func (r *ShiftRepo) ListShifts(ctx context.Context, officerID string, limit, offset int) ([]domain.CashierShift, int, error) {
	if r.db == nil || r.db.Pool == nil {
		return nil, 0, ErrDatabaseNotReady
	}

	var countQuery string
	var query string
	var args []interface{}

	if officerID != "" {
		countQuery = `SELECT COUNT(id) FROM public.cashier_shifts WHERE officer_id = $1`
		query = `
			SELECT cs.id, cs.officer_id, p.full_name, cs.shift_number, cs.started_at, cs.closed_at,
			       cs.starting_cash, cs.total_inflow, cs.total_outflow, cs.expected_cash, cs.actual_physical_cash,
			       cs.difference, cs.topup_count, cs.payout_count, cs.notes, cs.status,
			       cs.verified_by, p_ver.full_name, cs.verified_at, cs.created_at
			FROM public.cashier_shifts cs
			JOIN public.profiles p ON p.id = cs.officer_id
			LEFT JOIN public.profiles p_ver ON p_ver.id = cs.verified_by
			WHERE cs.officer_id = $1
			ORDER BY cs.closed_at DESC
			LIMIT $2 OFFSET $3`
		args = []interface{}{officerID, limit, offset}
	} else {
		countQuery = `SELECT COUNT(id) FROM public.cashier_shifts`
		query = `
			SELECT cs.id, cs.officer_id, p.full_name, cs.shift_number, cs.started_at, cs.closed_at,
			       cs.starting_cash, cs.total_inflow, cs.total_outflow, cs.expected_cash, cs.actual_physical_cash,
			       cs.difference, cs.topup_count, cs.payout_count, cs.notes, cs.status,
			       cs.verified_by, p_ver.full_name, cs.verified_at, cs.created_at
			FROM public.cashier_shifts cs
			JOIN public.profiles p ON p.id = cs.officer_id
			LEFT JOIN public.profiles p_ver ON p_ver.id = cs.verified_by
			ORDER BY cs.closed_at DESC
			LIMIT $1 OFFSET $2`
		args = []interface{}{limit, offset}
	}

	var total int
	if officerID != "" {
		err := r.db.Pool.QueryRow(ctx, countQuery, officerID).Scan(&total)
		if err != nil {
			return nil, 0, err
		}
	} else {
		err := r.db.Pool.QueryRow(ctx, countQuery).Scan(&total)
		if err != nil {
			return nil, 0, err
		}
	}

	rows, err := r.db.Pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var list []domain.CashierShift
	for rows.Next() {
		var s domain.CashierShift
		err := rows.Scan(
			&s.ID, &s.OfficerID, &s.OfficerName, &s.ShiftNumber, &s.StartedAt, &s.ClosedAt,
			&s.StartingCash, &s.TotalInflow, &s.TotalOutflow, &s.ExpectedCash, &s.ActualPhysicalCash,
			&s.Difference, &s.TopupCount, &s.PayoutCount, &s.Notes, &s.Status,
			&s.VerifiedBy, &s.VerifierName, &s.VerifiedAt, &s.CreatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		list = append(list, s)
	}

	return list, total, nil
}

// VerifyShift allows Super Admin to verify and mark shift as confirmed
func (r *ShiftRepo) VerifyShift(ctx context.Context, shiftID, adminID string) (*domain.CashierShift, error) {
	if r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}

	now := time.Now().UTC()
	var shift domain.CashierShift

	err := r.db.Pool.QueryRow(ctx, `
		UPDATE public.cashier_shifts
		SET status = 'verified', verified_by = $1, verified_at = $2
		WHERE id = $3
		RETURNING id, officer_id, shift_number, started_at, closed_at, starting_cash,
		          total_inflow, total_outflow, expected_cash, actual_physical_cash,
		          difference, topup_count, payout_count, notes, status, verified_by, verified_at, created_at`,
		adminID, now, shiftID,
	).Scan(
		&shift.ID, &shift.OfficerID, &shift.ShiftNumber, &shift.StartedAt, &shift.ClosedAt, &shift.StartingCash,
		&shift.TotalInflow, &shift.TotalOutflow, &shift.ExpectedCash, &shift.ActualPhysicalCash,
		&shift.Difference, &shift.TopupCount, &shift.PayoutCount, &shift.Notes, &shift.Status,
		&shift.VerifiedBy, &shift.VerifiedAt, &shift.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("sesi shift tidak ditemukan")
		}
		return nil, err
	}

	// Log audit trail
	_, _ = r.db.Pool.Exec(ctx, `
		INSERT INTO public.audit_logs (user_id, action, entity_name, entity_id, old_data, new_data)
		VALUES ($1, 'VERIFIKASI_SERAH_TERIMA_SHIFT', 'cashier_shifts', $2, '{}'::jsonb, json_build_object('desc', $3::text)::jsonb)`,
		adminID, shiftID, fmt.Sprintf("Super Admin memverifikasi dan menerima setoran fisik Shift #%d senilai Rp %d", shift.ShiftNumber, shift.ActualPhysicalCash))

	return &shift, nil
}
