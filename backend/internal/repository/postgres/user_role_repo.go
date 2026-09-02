package postgres

import (
	"context"
	"strings"
)

// Role-scoped profile writes.
//
// A profile row carries only what every account has. Everything specific to a role
// lives in that role's own table, and until now nothing could update those tables
// after the account was created -- CreateUserProfile wrote them once and there was
// no second path in. The admin app has edit sheets that send these fields, so the
// missing writes are why those sheets could not save.

// UpdateCanteenOperatorProfile renames a stall.
//
// Written as an upsert rather than an UPDATE so that a merchant account whose side
// table row is missing gets repaired instead of silently accepting a write that
// touches zero rows. The defaults mirror the ones in the schema.
func (r *UserRepo) UpdateCanteenOperatorProfile(ctx context.Context, operatorID, canteenName string) error {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}

	_, err := r.db.Pool.Exec(ctx, `
		INSERT INTO public.canteen_operators (id, canteen_name, balance_earned, is_delivery_enabled, delivery_fee)
		VALUES ($1, $2, 0, TRUE, 2000)
		ON CONFLICT (id) DO UPDATE
		SET canteen_name = EXCLUDED.canteen_name`,
		operatorID, strings.TrimSpace(canteenName),
	)
	return err
}

// UpdateFinanceOfficerProfile stores the school and authority level of a finance
// officer. A nil argument means the field was not part of the request and keeps
// whatever is stored.
//
// The three ADD COLUMN statements exist because this table has been created from
// two different scripts over the project's life: one gave it assigned_school and
// authority_level, the other gave it total_managed_funds. A database built from
// either one is missing what the other added, so the endpoint would fail on the
// column rather than on anything the admin did wrong. ADD COLUMN IF NOT EXISTS is
// a no-op once the column is there, and this runs only on an admin edit, which is
// rare enough that the brief lock does not matter. Same self-healing approach the
// transactions CHECK in db.go and cashier_shifts in shift_repo.go already use.
func (r *UserRepo) UpdateFinanceOfficerProfile(ctx context.Context, officerID string, assignedSchool, authorityLevel *string) error {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}

	_, _ = r.db.Pool.Exec(ctx, `
		ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS assigned_school TEXT NOT NULL DEFAULT 'Sekolah Digital';
		ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS authority_level TEXT NOT NULL DEFAULT 'L1';
		ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS total_managed_funds BIGINT NOT NULL DEFAULT 0;`)

	_, err := r.db.Pool.Exec(ctx, `
		INSERT INTO public.finance_officers (id, total_managed_funds, assigned_school, authority_level)
		VALUES ($1, 0, COALESCE($2, 'Sekolah Digital'), COALESCE($3, 'L1'))
		ON CONFLICT (id) DO UPDATE
		SET assigned_school = COALESCE($2, finance_officers.assigned_school),
		    authority_level = COALESCE($3, finance_officers.authority_level)`,
		officerID, assignedSchool, authorityLevel,
	)
	return err
}

// SetParentLinkedStudents replaces the set of children attached to a parent and
// reports how many links now exist plus the NISNs that matched no student.
//
// The delete is scoped to the links that are not in the new set, so a child that
// stays attached keeps its original created_at instead of looking freshly linked.
// An empty list therefore detaches everything, which is what an admin clearing the
// field is asking for.
//
// Unknown NISNs are collected rather than treated as failures: one mistyped digit
// should not throw away the rest of a bulk edit, and the caller shows the list back
// to the admin.
func (r *UserRepo) SetParentLinkedStudents(ctx context.Context, parentID string, nisns []string) (int, []string, error) {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return 0, nil, ErrDatabaseNotReady
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return 0, nil, err
	}
	defer func() { _ = tx.Rollback(ctx) }()

	studentIDs := make([]string, 0, len(nisns))
	missing := make([]string, 0)
	seen := make(map[string]bool, len(nisns))

	for _, raw := range nisns {
		nisn := strings.TrimSpace(raw)
		if nisn == "" || seen[nisn] {
			continue
		}
		seen[nisn] = true

		var studentID string
		qErr := tx.QueryRow(ctx, `
			SELECT id FROM public.profiles
			WHERE (nisn = $1 OR username = $1) AND role = 'student'
			LIMIT 1`, nisn).Scan(&studentID)
		if qErr != nil || studentID == "" {
			missing = append(missing, nisn)
			continue
		}
		studentIDs = append(studentIDs, studentID)
	}

	if _, err := tx.Exec(ctx, `
		DELETE FROM public.parent_students
		WHERE parent_id = $1 AND NOT (student_id = ANY($2::uuid[]))`,
		parentID, studentIDs,
	); err != nil {
		return 0, nil, err
	}

	for _, studentID := range studentIDs {
		if _, err := tx.Exec(ctx, `
			INSERT INTO public.parent_students (parent_id, student_id, created_at)
			VALUES ($1, $2, NOW())
			ON CONFLICT DO NOTHING`,
			parentID, studentID,
		); err != nil {
			return 0, nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, nil, err
	}
	return len(studentIDs), missing, nil
}
