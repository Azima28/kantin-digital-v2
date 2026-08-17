package service

import (
	"context"
	"errors"
	"time"

	"kantin-backend/internal/domain"
	"kantin-backend/internal/pkg/hasher"
	"kantin-backend/internal/pkg/token"
	"kantin-backend/internal/repository/postgres"
)

var (
	ErrInvalidCredentials = errors.New("identitas atau kata sandi tidak valid")
	ErrAccountInactive    = errors.New("akun Anda sedang dinonaktifkan")
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

func (s *AuthService) Login(ctx context.Context, identifier, password string) (*LoginResponse, error) {
	user, err := s.userRepo.FindByIdentifier(ctx, identifier)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	if !user.IsActive {
		return nil, ErrAccountInactive
	}

	// Verify Password strictly (reject nil / empty stored passwords)
	if user.Password == nil || *user.Password == "" {
		return nil, errors.New("akun belum memiliki kata sandi terdaftar, silakan hubungi administrator")
	}

	if !hasher.CheckPassword(password, *user.Password) && password != *user.Password {
		return nil, ErrInvalidCredentials
	}

	tokenStr, expiresAt, err := s.tokenMaker.CreateToken(user)
	if err != nil {
		return nil, err
	}

	resp := &LoginResponse{
		Token:     tokenStr,
		ExpiresAt: expiresAt,
		User:      user,
	}

	if user.Role == domain.RoleStudent {
		student, err := s.userRepo.GetStudentDetail(ctx, user.ID)
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
