package postgres

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"kantin-backend/internal/domain"
)

var (
	ErrUserNotFound       = errors.New("user tidak ditemukan")
	ErrDatabaseNotReady   = errors.New("koneksi database PostgreSQL belum terhubung")
)

type UserRepo struct {
	db *DB
}

func NewUserRepo(db *DB) *UserRepo {
	return &UserRepo{db: db}
}

// FindByIdentifier finds user by email, username, or nisn
func (r *UserRepo) FindByIdentifier(ctx context.Context, identifier string) (*domain.UserProfile, error) {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}
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
	if r == nil || r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}
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
	if r == nil || r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, studentID)
	var s domain.Student
	var p domain.UserProfile
	p.ID = studentID

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
		&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
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
	if r == nil || r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE LOWER(s.rfid_uid) = LOWER($1) OR REPLACE(LOWER(s.rfid_uid), ':', '') = REPLACE(LOWER($1), ':', '')
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(rfidUID))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
		&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
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

// FindParentByStudentNISN finds parent profile linked to student by student's NISN
func (r *UserRepo) FindParentByStudentNISN(ctx context.Context, nisn string) (*domain.UserProfile, error) {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return nil, ErrDatabaseNotReady
	}
	query := `
		SELECT p_parent.id, p_parent.email, p_parent.full_name, p_parent.role, p_parent.password, p_parent.username,
		       p_parent.nisn, p_parent.phone_number, p_parent.is_active, p_parent.relation, p_parent.avatar_url, p_parent.created_at
		FROM public.parent_students ps
		JOIN public.profiles p_student ON p_student.id = ps.student_id
		JOIN public.profiles p_parent ON p_parent.id = ps.parent_id
		WHERE p_student.nisn = $1 OR LOWER(p_student.username) = LOWER($1)
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(nisn))
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

// GetFirstStudentByParentID finds the primary student linked to a parent
func (r *UserRepo) GetFirstStudentByParentID(ctx context.Context, parentID string) (*domain.Student, error) {
	var studentID string
	err := r.db.Pool.QueryRow(ctx, `SELECT student_id FROM public.parent_students WHERE parent_id = $1 LIMIT 1`, parentID).Scan(&studentID)
	if err != nil {
		return nil, err
	}
	return r.GetStudentDetail(ctx, studentID)
}

// SearchStudents searches students by name, NISN, or username
func (r *UserRepo) SearchStudents(ctx context.Context, search string) ([]domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE ($1 = '' OR p.full_name ILIKE '%' || $1 || '%' OR p.nisn ILIKE '%' || $1 || '%' OR p.username ILIKE '%' || $1 || '%')
		ORDER BY p.full_name ASC
		LIMIT 20`

	rows, err := r.db.Pool.Query(ctx, query, strings.TrimSpace(search))
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Student
	for rows.Next() {
		var s domain.Student
		var p domain.UserProfile
		err := rows.Scan(
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
			&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
			&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		p.ID = s.ID
		s.Profile = &p
		list = append(list, s)
	}
	return list, nil
}

// FindStudentByNISN finds student by NISN or NIS
func (r *UserRepo) FindStudentByNISN(ctx context.Context, nisn string) (*domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE p.nisn = $1 OR LOWER(p.username) = LOWER($1) OR LOWER(p.email) = LOWER($1) OR s.id::text = $1
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(nisn))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
		&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
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
		       p.email, p.full_name, p.role, p.username, p.phone_number, p.is_active, p.avatar_url, p.created_at
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
			&p.Email, &p.FullName, &p.Role, &p.Username, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
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

// GetCanteenOperatorDetail retrieves canteen operator and profile by ID
func (r *UserRepo) GetCanteenOperatorDetail(ctx context.Context, id string) (*domain.CanteenOperator, error) {
	query := `
		SELECT COALESCE(c.id, p.id), COALESCE(c.canteen_name, p.full_name), COALESCE(c.balance_earned, 0),
		       COALESCE(c.is_delivery_enabled, true), COALESCE(c.delivery_fee, 2000),
		       COALESCE(c.rating, 0.0), COALESCE(c.total_reviews, 0),
		       p.email, p.full_name, p.role, p.username, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.profiles p
		LEFT JOIN public.canteen_operators c ON c.id = p.id
		WHERE p.id = $1 OR c.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, id)
	var c domain.CanteenOperator
	var p domain.UserProfile
	err := row.Scan(
		&c.ID, &c.CanteenName, &c.BalanceEarned, &c.IsDeliveryEnabled, &c.DeliveryFee,
		&c.Rating, &c.TotalReviews,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	p.ID = c.ID
	c.Profile = &p
	return &c, nil
}

// GetFinanceOfficerDetail retrieves finance officer and profile by ID
func (r *UserRepo) GetFinanceOfficerDetail(ctx context.Context, id string) (*domain.FinanceOfficer, error) {
	query := `
		SELECT p.id, COALESCE(f.total_managed_funds, 0),
		       p.email, p.full_name, p.role, p.username, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.profiles p
		LEFT JOIN public.finance_officers f ON f.id = p.id
		WHERE p.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, id)
	var f domain.FinanceOfficer
	var p domain.UserProfile
	err := row.Scan(
		&f.ID, &f.TotalManagedFunds,
		&p.Email, &p.FullName, &p.Role, &p.Username, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}
	p.ID = f.ID
	f.Profile = &p
	return &f, nil
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

// ListAllStudents retrieves all registered students with profile details
func (r *UserRepo) ListAllStudents(ctx context.Context) ([]domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		ORDER BY p.full_name ASC`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Student
	for rows.Next() {
		var s domain.Student
		var p domain.UserProfile
		err := rows.Scan(
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
			&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
			&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		p.ID = s.ID
		s.Profile = &p
		list = append(list, s)
	}
	return list, nil
}

// EnrichedUserProfile includes profile and related sub-entity metadata
type EnrichedUserProfile struct {
	domain.UserProfile
	CanteenOperators map[string]interface{} `json:"canteen_operators,omitempty"`
}

// ListAllUsers retrieves all user profiles with optional role filtering
func (r *UserRepo) ListAllUsers(ctx context.Context, roleFilter string) ([]EnrichedUserProfile, error) {
	query := `
		SELECT p.id, p.email, p.full_name, p.role, p.password, p.username, p.nisn, p.phone_number, p.is_active, p.relation, p.avatar_url, p.created_at,
		       c.canteen_name, c.balance_earned
		FROM public.profiles p
		LEFT JOIN public.canteen_operators c ON c.id = p.id
		WHERE ($1 = '' OR p.role = $1)
		ORDER BY p.created_at DESC`

	rows, err := r.db.Pool.Query(ctx, query, roleFilter)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []EnrichedUserProfile
	for rows.Next() {
		var u EnrichedUserProfile
		var cName *string
		var bEarned *int
		err := rows.Scan(
			&u.ID, &u.Email, &u.FullName, &u.Role, &u.Password, &u.Username,
			&u.NISN, &u.PhoneNumber, &u.IsActive, &u.Relation, &u.AvatarURL, &u.CreatedAt,
			&cName, &bEarned,
		)
		if err != nil {
			return nil, err
		}
		if cName != nil && *cName != "" {
			earned := 0
			if bEarned != nil {
				earned = *bEarned
			}
			u.CanteenOperators = map[string]interface{}{
				"canteen_name":   *cName,
				"balance_earned": earned,
			}
		}
		list = append(list, u)
	}
	return list, nil
}

// UpdateStudentSettings updates student limit, freeze state, parent phone, and notification preferences
func (r *UserRepo) UpdateStudentSettings(ctx context.Context, studentID string, dailyLimit *int, isActive *bool, waEnabled *bool, parentPhone *string) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if dailyLimit != nil {
		_, err = tx.Exec(ctx, `UPDATE public.students SET daily_limit = $1 WHERE id = $2`, *dailyLimit, studentID)
		if err != nil {
			return err
		}
	}

	if isActive != nil {
		_, err = tx.Exec(ctx, `UPDATE public.students SET is_active = $1 WHERE id = $2`, *isActive, studentID)
		if err != nil {
			return err
		}
	}

	if waEnabled != nil {
		_, err = tx.Exec(ctx, `UPDATE public.students SET wa_notifications_enabled = $1 WHERE id = $2`, *waEnabled, studentID)
		if err != nil {
			return err
		}
	}

	if parentPhone != nil {
		_, err = tx.Exec(ctx, `UPDATE public.students SET parent_phone = $1 WHERE id = $2`, *parentPhone, studentID)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

// GetParentChildren retrieves all students linked to a parent
func (r *UserRepo) GetParentChildren(ctx context.Context, parentID string) ([]domain.Student, error) {
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone,
		       COALESCE(s.class, 'X RPL 1'), COALESCE(s.rombel, 'X RPL 1'), s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.parent_students ps
		JOIN public.students s ON s.id = ps.student_id
		JOIN public.profiles p ON p.id = s.id
		WHERE ps.parent_id = $1`

	rows, err := r.db.Pool.Query(ctx, query, parentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.Student
	for rows.Next() {
		var s domain.Student
		var p domain.UserProfile
		err := rows.Scan(
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone,
			&s.Class, &s.Rombel, &s.ClassID, &s.RombelID,
			&p.Email, &p.FullName, &p.Role, &p.Username, &p.NISN, &p.PhoneNumber, &p.IsActive, &p.AvatarURL, &p.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		p.ID = s.ID
		s.Profile = &p
		list = append(list, s)
	}
	return list, nil
}

// CreateUserProfile creates a new user profile with associated role sub-record
func (r *UserRepo) CreateUserProfile(ctx context.Context, user *domain.UserProfile, passwordHash string, canteenName string, rfidUID *string, studentNISN *string, studentClass *string) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	var newID string
	err = tx.QueryRow(ctx, `
		INSERT INTO public.profiles (email, full_name, role, password, username, nisn, phone_number, is_active, relation, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
		RETURNING id`,
		user.Email, user.FullName, user.Role, passwordHash, user.Username, user.NISN, user.PhoneNumber, user.IsActive, user.Relation,
	).Scan(&newID)
	if err != nil {
		return err
	}
	user.ID = newID

	switch user.Role {
	case domain.RoleStudent:
		className := "X RPL 1"
		if studentClass != nil && strings.TrimSpace(*studentClass) != "" {
			className = strings.TrimSpace(*studentClass)
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO public.students (id, balance, rfid_uid, is_active, daily_limit, wa_notifications_enabled, class, rombel)
			VALUES ($1, 0, $2, $3, 0, TRUE, $4, $4)`,
			newID, rfidUID, user.IsActive, className,
		)
	case domain.RolePetugasKantin:
		name := canteenName
		if name == "" {
			name = user.FullName
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO public.canteen_operators (id, canteen_name, balance_earned, is_delivery_enabled, delivery_fee)
			VALUES ($1, $2, 0, TRUE, 2000)`,
			newID, name,
		)
	case domain.RolePetugasKeuangan:
		_, err = tx.Exec(ctx, `
			INSERT INTO public.finance_officers (id, total_managed_funds)
			VALUES ($1, 0)`,
			newID,
		)
	case domain.RoleParent:
		if studentNISN != nil && strings.TrimSpace(*studentNISN) != "" {
			var studentID string
			sErr := tx.QueryRow(ctx, `SELECT id FROM public.profiles WHERE nisn = $1 OR username = $1 LIMIT 1`, strings.TrimSpace(*studentNISN)).Scan(&studentID)
			if sErr == nil && studentID != "" {
				_, _ = tx.Exec(ctx, `
					INSERT INTO public.parent_students (parent_id, student_id, created_at)
					VALUES ($1, $2, NOW())
					ON CONFLICT DO NOTHING`,
					newID, studentID,
				)
			}
		}
	}
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// UpdateUserStatus updates is_active flag strictly on user profile (digital login account)
func (r *UserRepo) UpdateUserStatus(ctx context.Context, id string, isActive bool) error {
	_, err := r.db.Pool.Exec(ctx, `UPDATE public.profiles SET is_active = $1 WHERE id = $2`, isActive, id)
	return err
}

// UpdateStudentCardStatus links or unlinks RFID UID from student, or toggles card freeze state
func (r *UserRepo) UpdateStudentCardStatus(ctx context.Context, studentID string, rfidUID *string, isActive *bool) error {
	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	if rfidUID != nil {
		cleanUID := strings.TrimSpace(*rfidUID)
		if cleanUID != "" {
			_, err = tx.Exec(ctx, `UPDATE public.students SET rfid_uid = $1 WHERE id = $2`, cleanUID, studentID)
			if err != nil {
				return err
			}
		} else {
			_, err = tx.Exec(ctx, `UPDATE public.students SET rfid_uid = NULL WHERE id = $1`, studentID)
			if err != nil {
				return err
			}
		}
	}

	if isActive != nil {
		_, err = tx.Exec(ctx, `UPDATE public.students SET is_active = $1 WHERE id = $2`, *isActive, studentID)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

// DeleteUser deletes a user from profiles (cascades to all sub-tables)
func (r *UserRepo) DeleteUser(ctx context.Context, id string) error {
	query := `DELETE FROM public.profiles WHERE id = $1`
	_, err := r.db.Pool.Exec(ctx, query, id)
	return err
}

// ListFinanceOfficersLedger retrieves all finance officers with comprehensive cash flow & transaction aggregates
func (r *UserRepo) ListFinanceOfficersLedger(ctx context.Context) ([]domain.FinanceOfficerLedgerItem, error) {
	query := `
		SELECT p.id, p.full_name, p.email, p.username, p.phone_number, p.is_active, p.avatar_url, p.created_at,
		       COALESCE((SELECT value->>'school_name' FROM public.system_settings WHERE key = 'academic_structure'), 'Sekolah Digital') AS assigned_school,
		       'L1' AS authority_level,
		       -- Total Cash Inflow (Topup by this officer)
		       COALESCE((
		           SELECT SUM(t.total_amount)
		           FROM public.transactions t
		           WHERE t.type = 'topup' AND (t.operator_id = p.id OR t.student_id = p.id)
		       ), 0) AS total_cash_inflow,
		       -- Total Cash Outflow (Withdrawal payout to merchant by this officer)
		       COALESCE((
		           SELECT SUM(t.total_amount)
		           FROM public.transactions t
		           WHERE t.type = 'withdrawal' AND t.student_id = p.id
		       ), 0) AS total_cash_outflow,
		       -- Total Transactions count
		       COALESCE((
		           SELECT COUNT(*)
		           FROM public.transactions t
		           WHERE t.operator_id = p.id OR (t.type = 'withdrawal' AND t.student_id = p.id)
		       ), 0) AS total_tx_count,
		       -- Today Cash Inflow
		       COALESCE((
		           SELECT SUM(t.total_amount)
		           FROM public.transactions t
		           WHERE t.type = 'topup' AND (t.operator_id = p.id OR t.student_id = p.id) AND t.created_at >= CURRENT_DATE
		       ), 0) AS today_cash_inflow,
		       -- Today Cash Outflow
		       COALESCE((
		           SELECT SUM(t.total_amount)
		           FROM public.transactions t
		           WHERE t.type = 'withdrawal' AND t.student_id = p.id AND t.created_at >= CURRENT_DATE
		       ), 0) AS today_cash_outflow,
		       -- Today Transaction Count
		       COALESCE((
		           SELECT COUNT(*)
		           FROM public.transactions t
		           WHERE (t.operator_id = p.id OR (t.type = 'withdrawal' AND t.student_id = p.id)) AND t.created_at >= CURRENT_DATE
		       ), 0) AS today_tx_count
		FROM public.profiles p
		WHERE p.role = 'petugas_keuangan'
		ORDER BY p.full_name ASC`

	rows, err := r.db.Pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []domain.FinanceOfficerLedgerItem
	for rows.Next() {
		var item domain.FinanceOfficerLedgerItem
		err := rows.Scan(
			&item.ID, &item.FullName, &item.Email, &item.Username, &item.PhoneNumber, &item.IsActive, &item.AvatarURL, &item.CreatedAt,
			&item.AssignedSchool, &item.AuthorityLevel,
			&item.TotalCashInflow, &item.TotalCashOutflow, &item.TotalTransactions,
			&item.TodayCashInflow, &item.TodayCashOutflow, &item.TodayTxCount,
		)
		if err != nil {
			return nil, err
		}
		item.NetCashHandled = item.TotalCashInflow - item.TotalCashOutflow
		item.TodayNetCash = item.TodayCashInflow - item.TodayCashOutflow
		list = append(list, item)
	}
	return list, nil
}

// GetFinanceOfficerLedgerDetail retrieves complete ledger details, 7-day trend, and journals for an officer
func (r *UserRepo) GetFinanceOfficerLedgerDetail(ctx context.Context, officerID string) (*domain.FinanceOfficerLedgerDetail, error) {
	list, err := r.ListFinanceOfficersLedger(ctx)
	if err != nil {
		return nil, err
	}
	var officerItem *domain.FinanceOfficerLedgerItem
	for _, it := range list {
		if it.ID == officerID {
			officerItem = &it
			break
		}
	}
	if officerItem == nil {
		prof, err := r.FindByID(ctx, officerID)
		if err != nil {
			return nil, err
		}
		acad, _ := r.GetAcademicStructure(ctx)
		schoolName := "Sekolah Digital"
		if acad != nil && acad.SchoolName != "" {
			schoolName = acad.SchoolName
		}
		officerItem = &domain.FinanceOfficerLedgerItem{
			ID:             prof.ID,
			FullName:       prof.FullName,
			Email:          prof.Email,
			Username:       prof.Username,
			PhoneNumber:    prof.PhoneNumber,
			IsActive:       prof.IsActive,
			AvatarURL:      prof.AvatarURL,
			AssignedSchool: schoolName,
			AuthorityLevel: "L1",
			CreatedAt:      prof.CreatedAt,
		}
	}

	weeklyInflow := make([]int, 7)
	weeklyOutflow := make([]int, 7)

	trendQuery := `
		SELECT (CURRENT_DATE - created_at::date) as day_diff,
		       COALESCE(SUM(CASE WHEN type = 'topup' AND (operator_id = $1 OR student_id = $1) THEN total_amount ELSE 0 END), 0) as inflow,
		       COALESCE(SUM(CASE WHEN type = 'withdrawal' AND student_id = $1 THEN total_amount ELSE 0 END), 0) as outflow
		FROM public.transactions
		WHERE created_at >= (CURRENT_DATE - INTERVAL '6 days')
		  AND (operator_id = $1 OR student_id = $1)
		GROUP BY day_diff
		ORDER BY day_diff ASC`

	tRows, err := r.db.Pool.Query(ctx, trendQuery, officerID)
	if err == nil {
		defer tRows.Close()
		for tRows.Next() {
			var dayDiff, inf, outf int
			if err := tRows.Scan(&dayDiff, &inf, &outf); err == nil && dayDiff >= 0 && dayDiff < 7 {
				weeklyInflow[6-dayDiff] = inf
				weeklyOutflow[6-dayDiff] = outf
			}
		}
	}

	journalQuery := `
		(
			SELECT t.id::text, t.id::text AS transaction_id, 'TOPUP' as tx_type, 'INFLOW' as category,
			       t.total_amount as amount, COALESCE(p.full_name, 'Siswa') as target_name, 'student' as target_role,
			       COALESCE(t.student_id::text, '') as target_id, COALESCE(t.purchase_method, 'Tunai') as notes, COALESCE(t.purchase_method, 'Tunai') as method,
			       t.created_at
			FROM public.transactions t
			LEFT JOIN public.profiles p ON p.id = t.student_id
			WHERE t.type = 'topup' AND (t.operator_id = $1 OR t.student_id = $1)
		)
		UNION ALL
		(
			SELECT t.id::text, t.id::text AS transaction_id, 'WITHDRAWAL' as tx_type, 'OUTFLOW' as category,
			       t.total_amount as amount, COALESCE(c.canteen_name, p.full_name, 'Stan Kantin') as target_name, 'canteen' as target_role,
			       COALESCE(t.operator_id::text, '') as target_id, 'Pencairan Kas Stan (Payout)' as notes, COALESCE(t.purchase_method, 'Tunai') as method,
			       t.created_at
			FROM public.transactions t
			LEFT JOIN public.canteen_operators c ON c.id = t.operator_id
			LEFT JOIN public.profiles p ON p.id = t.operator_id
			WHERE t.type = 'withdrawal' AND t.student_id = $1
		)
		ORDER BY created_at DESC
		LIMIT 100`

	jRows, err := r.db.Pool.Query(ctx, journalQuery, officerID)
	journals := make([]domain.OfficerJournalEntry, 0)
	if err == nil {
		defer jRows.Close()
		for jRows.Next() {
			var j domain.OfficerJournalEntry
			err := jRows.Scan(
				&j.ID, &j.TransactionID, &j.Type, &j.Category,
				&j.Amount, &j.TargetName, &j.TargetRole,
				&j.TargetID, &j.Notes, &j.Method,
				&j.CreatedAt,
			)
			if err == nil {
				journals = append(journals, j)
			}
		}
	}

	return &domain.FinanceOfficerLedgerDetail{
		Officer:        *officerItem,
		RecentJournals: journals,
		WeeklyInflow:   weeklyInflow,
		WeeklyOutflow:  weeklyOutflow,
	}, nil
}


// UpdateUserProfile updates basic profile attributes
func (r *UserRepo) UpdateUserProfile(ctx context.Context, user *domain.UserProfile) error {
	query := `
		UPDATE public.profiles
		SET full_name = $1, email = $2, username = $3, nisn = $4, phone_number = $5, avatar_url = $6, is_active = $7
		WHERE id = $8`
	_, err := r.db.Pool.Exec(ctx, query, user.FullName, user.Email, user.Username, user.NISN, user.PhoneNumber, user.AvatarURL, user.IsActive, user.ID)
	return err
}

type UpdateStudentFullParams struct {
	ID          string
	FullName    string
	Email       *string
	Username    *string
	NISN        *string
	PhoneNumber *string
	DailyLimit  *int
	RfidUID     *string
	Class       *string
	IsActive    *bool
}

// UpdateStudentFull updates both profile and student specific data (class, rombel, balance limit, etc.)
func (r *UserRepo) UpdateStudentFull(ctx context.Context, p UpdateStudentFullParams) error {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}

	tx, err := r.db.Pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 1. Update public.profiles
	_, err = tx.Exec(ctx, `
		UPDATE public.profiles
		SET full_name = COALESCE(NULLIF($1, ''), full_name),
		    email = COALESCE($2, email),
		    username = COALESCE($3, username),
		    nisn = COALESCE($4, nisn),
		    phone_number = COALESCE($5, phone_number),
		    is_active = COALESCE($6, is_active)
		WHERE id = $7`,
		p.FullName, p.Email, p.Username, p.NISN, p.PhoneNumber, p.IsActive, p.ID,
	)
	if err != nil {
		return err
	}

	// 2. Update public.students
	var cleanUID *string
	if p.RfidUID != nil {
		trimmed := strings.TrimSpace(*p.RfidUID)
		if trimmed != "" {
			cleanUID = &trimmed
		}
	}

	className := "X RPL 1"
	if p.Class != nil && strings.TrimSpace(*p.Class) != "" {
		className = strings.TrimSpace(*p.Class)
	}

	_, err = tx.Exec(ctx, `
		UPDATE public.students
		SET class = $1,
		    rombel = $1,
		    daily_limit = COALESCE($2, daily_limit),
		    rfid_uid = COALESCE($3, rfid_uid),
		    is_active = COALESCE($4, is_active)
		WHERE id = $5`,
		className, p.DailyLimit, cleanUID, p.IsActive, p.ID,
	)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

func defaultAcademicStructure() domain.AcademicStructure {
	return domain.AcademicStructure{
		SchoolType: "smk",
		SchoolName: "SMK Negeri 1",
		HasMajors:  true,
		Majors: []domain.AcademicMajor{
			{ID: "rpl", Name: "Rekayasa Perangkat Lunak", Code: "RPL"},
			{ID: "tkj", Name: "Teknik Komputer & Jaringan", Code: "TKJ"},
			{ID: "dkv", Name: "Desain Komunikasi Visual", Code: "DKV"},
			{ID: "akl", Name: "Akuntansi & Keuangan Lembaga", Code: "AKL"},
			{ID: "otkp", Name: "Otomatisasi & Tata Kelola Perkantoran", Code: "OTKP"},
		},
		GradeLevels: []string{"X", "XI", "XII"},
		Rombels: []string{
			"X RPL 1", "X RPL 2", "X TKJ 1", "X TKJ 2", "X DKV 1", "X AKL 1",
			"XI RPL 1", "XI RPL 2", "XI TKJ 1", "XI TKJ 2", "XI DKV 1", "XI AKL 1",
			"XII RPL 1", "XII RPL 2", "XII TKJ 1", "XII TKJ 2", "XII DKV 1", "XII AKL 1",
		},
		UpdatedAt: time.Now(),
	}
}

// GetAcademicStructure retrieves configured school structure, majors, grade levels, and rombels
func (r *UserRepo) GetAcademicStructure(ctx context.Context) (*domain.AcademicStructure, error) {
	def := defaultAcademicStructure()
	if r == nil || r.db == nil || r.db.Pool == nil {
		return &def, nil
	}

	var valBytes []byte
	var updatedAt time.Time
	err := r.db.Pool.QueryRow(ctx, `SELECT value, updated_at FROM public.system_settings WHERE key = 'academic_structure'`).Scan(&valBytes, &updatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			_ = r.SaveAcademicStructure(ctx, &def)
			return &def, nil
		}
		return &def, nil
	}

	var res domain.AcademicStructure
	if err := json.Unmarshal(valBytes, &res); err != nil {
		return &def, nil
	}
	res.UpdatedAt = updatedAt
	return &res, nil
}

// SaveAcademicStructure persists school academic structure to PostgreSQL system_settings
func (r *UserRepo) SaveAcademicStructure(ctx context.Context, structData *domain.AcademicStructure) error {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}
	if structData.SchoolName == "" {
		structData.SchoolName = "Sekolah Digital"
	}
	structData.UpdatedAt = time.Now()
	valBytes, err := json.Marshal(structData)
	if err != nil {
		return err
	}

	query := `
		INSERT INTO public.system_settings (key, value, description, updated_at)
		VALUES ('academic_structure', $1, 'Pengaturan master struktur jenjang, jurusan, kelas, dan rombel sekolah', NOW())
		ON CONFLICT (key) DO UPDATE
		SET value = EXCLUDED.value, updated_at = NOW()`

	_, err = r.db.Pool.Exec(ctx, query, valBytes)
	return err
}

// GetGlobalSettings retrieves system settings (midtrans, maintenance, etc.)
func (r *UserRepo) GetGlobalSettings(ctx context.Context) (map[string]interface{}, error) {
	result := map[string]interface{}{
		"maintenance_mode": false,
		"midtrans_config": map[string]interface{}{
			"mode":        "sandbox",
			"client_key":  "SB-Mid-client-1234567890",
			"server_key":  "SB-Mid-server-1234567890",
			"merchant_id": "G123456",
			"is_active":   true,
		},
		"school_name":   "SMK Negeri 1",
		"academic_year": "2026/2027",
		"app_version":   "2.0.0",
		"db_status":     "Connected (PostgreSQL 16)",
	}

	if r == nil || r.db == nil || r.db.Pool == nil {
		return result, nil
	}

	rows, err := r.db.Pool.Query(ctx, `SELECT key, value FROM public.system_settings WHERE key IN ('global_settings', 'midtrans_config', 'maintenance_mode')`)
	if err != nil {
		return result, nil
	}
	defer rows.Close()

	for rows.Next() {
		var key string
		var valBytes []byte
		if err := rows.Scan(&key, &valBytes); err == nil {
			var parsed interface{}
			if err := json.Unmarshal(valBytes, &parsed); err == nil {
				result[key] = parsed
			}
		}
	}
	return result, nil
}

// SaveGlobalSettings updates system settings
func (r *UserRepo) SaveGlobalSettings(ctx context.Context, settings map[string]interface{}) error {
	if r == nil || r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}

	for k, v := range settings {
		valBytes, err := json.Marshal(v)
		if err != nil {
			continue
		}
		_, _ = r.db.Pool.Exec(ctx, `
			INSERT INTO public.system_settings (key, value, updated_at)
			VALUES ($1, $2, NOW())
			ON CONFLICT (key) DO UPDATE
			SET value = EXCLUDED.value, updated_at = NOW()`,
			k, valBytes,
		)
	}
	return nil
}
