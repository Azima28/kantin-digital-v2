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
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE s.id = $1`

	row := r.db.Pool.QueryRow(ctx, query, studentID)
	var s domain.Student
	var p domain.UserProfile
	p.ID = studentID

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
	query := `
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE LOWER(s.rfid_uid) = LOWER($1) OR REPLACE(LOWER(s.rfid_uid), ':', '') = REPLACE(LOWER($1), ':', '')
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(rfidUID))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
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
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
		       p.email, p.full_name, p.role, p.username, p.nisn, p.phone_number, p.is_active, p.avatar_url, p.created_at
		FROM public.students s
		JOIN public.profiles p ON p.id = s.id
		WHERE p.nisn = $1 OR LOWER(p.username) = LOWER($1) OR LOWER(p.email) = LOWER($1) OR s.id::text = $1
		LIMIT 1`

	row := r.db.Pool.QueryRow(ctx, query, strings.TrimSpace(nisn))
	var s domain.Student
	var p domain.UserProfile

	err := row.Scan(
		&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
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
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
		SELECT s.id, s.balance, s.rfid_uid, s.is_active, COALESCE(s.daily_limit, 0), COALESCE(s.wa_notifications_enabled, true), s.parent_phone, s.class_id, s.rombel_id,
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
			&s.ID, &s.Balance, &s.RfidUID, &s.IsActive, &s.DailyLimit, &s.WANotificationsEnabled, &s.ParentPhone, &s.ClassID, &s.RombelID,
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
func (r *UserRepo) CreateUserProfile(ctx context.Context, user *domain.UserProfile, passwordHash string, canteenName string, rfidUID *string, studentNISN *string) error {
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
		_, err = tx.Exec(ctx, `
			INSERT INTO public.students (id, balance, rfid_uid, is_active, daily_limit, wa_notifications_enabled)
			VALUES ($1, 0, $2, $3, 0, TRUE)`,
			newID, rfidUID, user.IsActive,
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

// UpdateUserProfile updates basic profile attributes
func (r *UserRepo) UpdateUserProfile(ctx context.Context, user *domain.UserProfile) error {
	query := `
		UPDATE public.profiles
		SET full_name = $1, email = $2, username = $3, nisn = $4, phone_number = $5, is_active = $6
		WHERE id = $7`
	_, err := r.db.Pool.Exec(ctx, query, user.FullName, user.Email, user.Username, user.NISN, user.PhoneNumber, user.IsActive, user.ID)
	return err
}
