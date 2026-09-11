package service

import (
	"context"
	"errors"
	"strings"
	"time"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/hasher"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
)

var (
	ErrInvalidCredentials = errors.New("identitas atau kata sandi tidak valid")
	ErrAccountInactive    = errors.New("Akun Anda sedang dinonaktifkan / diblokir oleh pihak sekolah")
)

type AuthService struct {
	userRepo   *postgres.UserRepo
	tokenMaker *token.TokenMaker
}

func NewAuthService(userRepo *postgres.UserRepo, tokenMaker *token.TokenMaker) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		tokenMaker: tokenMaker,
	}
}

type LoginResponse struct {
	Token     string              `json:"token"`
	ExpiresAt time.Time           `json:"expires_at"`
	User      *domain.UserProfile `json:"user"`
	Student   *domain.Student     `json:"student,omitempty"`
}

func (s *AuthService) Login(ctx context.Context, identifier, password, expectedRole string) (*LoginResponse, error) {
	cleanID := strings.TrimSpace(identifier)
	var authenticatedUser *domain.UserProfile

	// 1. If expectedRole is "parent", prioritize finding the linked parent by Student NISN/Username
	if expectedRole == string(domain.RoleParent) || expectedRole == "parent" {
		parentUser, parentErr := s.userRepo.FindParentByStudentNISN(ctx, cleanID)
		if parentErr == nil && parentUser != nil {
			// Check parent's own password
			if parentUser.Password != nil && *parentUser.Password != "" &&
				hasher.CheckPassword(password, *parentUser.Password) {
				authenticatedUser = parentUser
			} else {
				// Fallback: check if password matches student's password (family login)
				studentUser, studentErr := s.userRepo.FindByIdentifier(ctx, cleanID)
				if studentErr == nil && studentUser != nil && studentUser.Password != nil && *studentUser.Password != "" {
					if hasher.CheckPassword(password, *studentUser.Password) {
						authenticatedUser = parentUser
					}
				}
			}
		}
	}

	// 2. Direct Lookup by username, email, or NISN
	if authenticatedUser == nil {
		user, err := s.userRepo.FindByIdentifier(ctx, cleanID)
		if err != nil {
			if errors.Is(err, postgres.ErrDatabaseNotReady) {
				return nil, err
			}
		} else if user != nil && user.Password != nil && *user.Password != "" {
			if hasher.CheckPassword(password, *user.Password) {
				if expectedRole == string(domain.RoleParent) || expectedRole == "parent" {
					if user.Role == domain.RoleParent {
						authenticatedUser = user
					} else {
						parentUser, parentErr := s.userRepo.FindParentByStudentNISN(ctx, cleanID)
						if parentErr == nil && parentUser != nil {
							authenticatedUser = parentUser
						}
					}
				} else {
					authenticatedUser = user
				}
			}
		}
	}

	// 3. Fallback: If not authenticated yet and identifier is a Student's NISN, check if the password belongs to a linked parent
	if authenticatedUser == nil {
		parentUser, parentErr := s.userRepo.FindParentByStudentNISN(ctx, cleanID)
		if parentErr == nil && parentUser != nil && parentUser.Password != nil && *parentUser.Password != "" {
			if hasher.CheckPassword(password, *parentUser.Password) {
				authenticatedUser = parentUser
			}
		}
	}

	if authenticatedUser == nil {
		return nil, ErrInvalidCredentials
	}

	if !authenticatedUser.IsActive {
		return nil, ErrAccountInactive
	}

	// Maintenance mode guard: block all non-admin logins
	if s.userRepo != nil && s.userRepo.IsMaintenanceMode(ctx) {
		if authenticatedUser.Role != domain.RoleSuperAdmin && authenticatedUser.Role != domain.RoleAdmin {
			return nil, errors.New("mode pemeliharaan aktif: semua akses login non-admin sedang diblokir sementara")
		}
	}

	tokenStr, expiresAt, err := s.tokenMaker.CreateToken(authenticatedUser)
	if err != nil {
		return nil, err
	}

	resp := &LoginResponse{
		Token:     tokenStr,
		ExpiresAt: expiresAt,
		User:      authenticatedUser,
	}

	if authenticatedUser.Role == domain.RoleStudent {
		student, err := s.userRepo.GetStudentDetail(ctx, authenticatedUser.ID)
		if err == nil {
			resp.Student = student
		}
	} else if authenticatedUser.Role == domain.RoleParent {
		// Attach linked student data for parent convenience
		student, err := s.userRepo.GetFirstStudentByParentID(ctx, authenticatedUser.ID)
		if err == nil {
			resp.Student = student
		}
	}

	return resp, nil
}

// IssueFreshToken mints a brand new session token for an already-authenticated
// user.
//
// This is deliberately not TokenMaker.RenewToken: renewal carries the original
// iat forward so that revocation cannot be escaped by renewing, which means a
// renewed token is exactly what a just-moved not_before watermark throws away.
// After a password change the caller needs a token that is genuinely new.
func (s *AuthService) IssueFreshToken(ctx context.Context, userID string) (string, time.Time, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	return s.tokenMaker.CreateToken(user)
}

func (s *AuthService) ChangePassword(ctx context.Context, userID, oldPassword, newPassword string) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return err
	}

	if user.Password != nil && *user.Password != "" {
		if !hasher.CheckPassword(oldPassword, *user.Password) {
			return errors.New("kata sandi lama tidak cocok")
		}
	}

	newHashed, err := hasher.HashPassword(newPassword)
	if err != nil {
		return err
	}

	return s.userRepo.UpdatePassword(ctx, userID, newHashed)
}

// Profile reads the stored profile for a user id. The JWT only carries what was
// signed at login, so anything editable afterwards -- avatar_url above all -- can
// only be answered from the row itself.
func (s *AuthService) Profile(ctx context.Context, userID string) (*domain.UserProfile, error) {
	return s.userRepo.FindByID(ctx, userID)
}

func (s *AuthService) UpdateProfile(ctx context.Context, userID, fullName string, email, username, phoneNumber, avatarURL, gender *string) (*domain.UserProfile, error) {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, err
	}

	if strings.TrimSpace(fullName) != "" {
		user.FullName = strings.TrimSpace(fullName)
	}
	if email != nil && strings.TrimSpace(*email) != "" {
		trimmedEmail := strings.TrimSpace(*email)
		user.Email = &trimmedEmail
	}
	if username != nil && strings.TrimSpace(*username) != "" {
		trimmedUsername := strings.TrimSpace(*username)
		user.Username = &trimmedUsername
	}
	if phoneNumber != nil {
		user.PhoneNumber = phoneNumber
	}
	if avatarURL != nil && strings.TrimSpace(*avatarURL) != "" {
		user.AvatarURL = avatarURL
	}
	if gender != nil && strings.TrimSpace(*gender) != "" {
		g := strings.TrimSpace(*gender)
		user.Gender = &g
	}

	if err := s.userRepo.UpdateUserProfile(ctx, user); err != nil {
		return nil, err
	}
	return user, nil
}
