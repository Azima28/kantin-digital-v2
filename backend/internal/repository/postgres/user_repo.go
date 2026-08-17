package postgres

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

var (
	ErrUserNotFound = errors.New("user tidak ditemukan")
)

type UserRepo struct {
	db *DB
}

func NewUserRepo(db *DB) *UserRepo {
	return &UserRepo{db: db}
}

// FindByIdentifier finds user by email, username, or nisn
func (r *UserRepo) FindByIdentifier(ctx context.Context, identifier string) (*domain.UserProfile, error) {
	query := `
		SELECT id, email, full_name, role, password, username, nisn, phone_number, is_active, relation, avatar_url, created_at
		FROM public.profiles
		WHERE LOWER(email) = LOWER($1) OR LOWER(username) = LOWER($1) OR nisn = $1
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(identifier))
	var u domain.UserProfile
	err := row.Scan(
		&u.ID, &u.Email, &u.FullName, &u.Role, &u.Password, &u.Username,
		&u.NISN, &u.PhoneNumber, &u.IsActive, &u.Relation, &u.AvatarURL, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &u, nil
}

// FindByID finds user profile by UUID
func (r *UserRepo) FindByID(ctx context.Context, id string) (*domain.UserProfile, error) {
	query := `
		SELECT id, email, full_name, role, password, username, nisn, phone_number, is_active, relation, avatar_url, created_at
		FROM public.profiles
		WHERE id = $1`

	row := r.db.Pool.QueryRow(ctx, query, id)
	var u domain.UserProfile
	err := row.Scan(
		&u.ID, &u.Email, &u.FullName, &u.Role, &u.Password, &u.Username,
		&u.NISN, &u.PhoneNumber, &u.IsActive, &u.Relation, &u.AvatarURL, &u.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	return &u, nil
}

// GetStudentDetail retrieves student entity with profile
func (r *UserRepo) GetStudentDetail(ctx context.Context, studentID string) (*domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, studentID)
	var s domain.Student
	var p domain.UserProfile
	p.ID = studentID

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.AvatarURL, &p.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	s.Profile = &p
	return &s, nil
}

// FindStudentByRFID finds student by card UID
func (r *UserRepo) FindStudentByRFID(ctx context.Context, rfidUID string) (*domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE LOWER(s.rfid_uid) = LOWER($1) OR REPLACE(LOWER(s.rfid_uid), ':', '') = REPLACE(LOWER($1), ':', '')
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(rfidUID))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.AvatarURL, &p.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	p.ID = s.ID
	s.Profile = &p
	return &s, nil
}

// FindStudentByNISN finds student by NISN or NIS
func (r *UserRepo) FindStudentByNISN(ctx context.Context, nisn string) (*domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE p.nisn = $1 OR LOWER(p.username) = LOWER($1) OR LOWER(p.email) = LOWER($1) OR s.id::text = $1
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(nisn))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.AvatarURL, &p.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	p.ID = s.ID
	s.Profile = &p
	return &s, nil
}

// ListCanteenOperators retrieves all canteen stalls
func (r *UserRepo) ListCanteenOperators(ctx context.Context) ([]domain.CanteenOperator, error) {
	query := `
		SELECT c.id, c.canteen_name, c.balance_earned, c.is_delivery_enabled, c.delivery_fee,
		       COALESCE(c.rating, 0.0), COALESCE(c.total_reviews, 0),
		       p.email, p.full_name, p.role, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.canteen_operators c
		JOIN public.profiles p ON p.id = c.id
		ORDER BY c.canteen_name ASC`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.CanteenOperator
	for rows.Next() {
		var c domain.CanteenOperator
		var p domain.UserProfile
		err := rows.Scan(
			&c.ID, &c.CanteenName, &c.BalanceEarned, &c.IsDeliveryEnabled, &c.DeliveryFee,
			&c.Rating, &c.TotalReviews,
			&p.Email, &p.FullName, &p.Role, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		p.ID = c.ID
		c.Profile = &p
		list = append(list, c)
	}
	return list, nil
}

// UpdateDeliverySettings updates stall delivery configurations
func (r *UserRepo) UpdateDeliverySettings(ctx context.Context, operatorID string, isEnabled bool, fee int) error {
	query := `
		UPDATE public.canteen_operators
		SET is_delivery_enabled = $1, delivery_fee = $2
		WHERE id = $3`
	_, err := r.db.Pool.Exec(ctx, query, isEnabled, fee, operatorID)
	return err
}

// UpdatePassword updates user password hash
func (r *UserRepo) UpdatePassword(ctx context.Context, userID, newHashedPassword string) error {
	query := `UPDATE public.profiles SET password = $1 WHERE id = $2`
	_, err := r.db.Pool.Exec(ctx, query, newHashedPassword, userID)
	return err
}

// UpdateAvatarURL updates user avatar URL
func (r *UserRepo) UpdateAvatarURL(ctx context.Context, userID, avatarURL string) error {
	query := `UPDATE public.profiles SET avatar_url = $1 WHERE id = $2`
	_, err := r.db.Pool.Exec(ctx, query, avatarURL, userID)
	return err
}
