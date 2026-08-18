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

	// 1. If expectedRole is "parent", prioritize finding the linked parent by Student NISN/Username first
	if expectedRole == string(domain.RoleParent) || expectedRole == "parent" {
		parentUser, parentErr := s.userRepo.FindParentByStudentNISN(ctx, cleanID)
		if parentErr == nil && parentUser != nil && parentUser.Password != nil && *parentUser.Password != "" {
			if hasher.CheckPassword(password, *parentUser.Password) || password == *parentUser.Password {
				authenticatedUser = parentUser
			}
		}
	}

	// 2. Direct Lookup by username, email, or NISN
	if authenticatedUser == nil {
		user, err := s.userRepo.FindByIdentifier(ctx, cleanID)
		if err == nil && user != nil && user.Password != nil && *user.Password != "" {
			if hasher.CheckPassword(password, *user.Password) || password == *user.Password {
				authenticatedUser = user
			}
		}
	}

	// 3. Fallback: If not authenticated yet and identifier is a Student's NISN, check if the password belongs to a linked parent
	if authenticatedUser == nil {
		parentUser, parentErr := s.userRepo.FindParentByStudentNISN(ctx, cleanID)
		if parentErr == nil && parentUser != nil && parentUser.Password != nil && *parentUser.Password != "" {
			if hasher.CheckPassword(password, *parentUser.Password) || password == *parentUser.Password {
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

func (s *AuthService) ChangePassword(ctx context.Context, userID, oldPassword, newPassword string) error {
	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return err
	}

	if user.Password != nil && *user.Password != "" {
		if !hasher.CheckPassword(oldPassword, *user.Password) && oldPassword != *user.Password {
			return errors.New("kata sandi lama tidak cocok")
		}
	}

	newHashed, err := hasher.HashPassword(newPassword)
	if err != nil {
		return err
	}

	return s.userRepo.UpdatePassword(ctx, userID, newHashed)
}
