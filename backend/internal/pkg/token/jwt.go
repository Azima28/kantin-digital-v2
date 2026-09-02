package token

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"kantin-backend/internal/domain"
)

var (
	ErrInvalidToken = errors.New("token tidak valid atau telah kadaluarsa")
)

type JWTClaims struct {
	UserID   string      `json:"user_id"`
	Email    string      `json:"email"`
	FullName string      `json:"full_name"`
	Role     domain.Role `json:"role"`
	jwt.RegisteredClaims
}

type TokenMaker struct {
	secretKey     string
	durationHours int
}

func NewTokenMaker(secretKey string, durationHours int) *TokenMaker {
	return &TokenMaker{
		secretKey:     secretKey,
		durationHours: durationHours,
	}
}

func (m *TokenMaker) CreateToken(user *domain.UserProfile) (string, time.Time, error) {
	email := ""
	if user.Email != nil {
		email = *user.Email
	}

	issuedAt := time.Now()
	expiresAt := issuedAt.Add(time.Duration(m.durationHours) * time.Hour)
	claims := &JWTClaims{
		UserID:   user.ID,
		Email:    email,
		FullName: user.FullName,
		Role:     user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.NewString(),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(issuedAt),
			Subject:   user.ID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(m.secretKey))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, expiresAt, nil
}

func (m *TokenMaker) DurationHours() int {
	return m.durationHours
}

// RenewToken issues a fresh token for an already-authenticated session.
//
// The jti is carried over deliberately. Renewal happens automatically inside the
// auth middleware, so if every renewal minted a new id, a revoked session would
// simply rename itself on the next request and outlive the logout that killed
// it. Keeping the id means one logout revokes the whole renewal chain. IssuedAt
// is likewise preserved: bulk revocation compares it against the user's
// not_before watermark, and refreshing it would let a renewal slip past a
// password change that was meant to end the session.
func (m *TokenMaker) RenewToken(claims *JWTClaims) (string, time.Time, error) {
	newExpiresAt := time.Now().Add(time.Duration(m.durationHours) * time.Hour)
	issuedAt := jwt.NewNumericDate(time.Now())
	if claims.IssuedAt != nil {
		issuedAt = claims.IssuedAt
	}
	sessionID := claims.ID
	if sessionID == "" {
		sessionID = uuid.NewString()
	}
	newClaims := &JWTClaims{
		UserID:   claims.UserID,
		Email:    claims.Email,
		FullName: claims.FullName,
		Role:     claims.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        sessionID,
			ExpiresAt: jwt.NewNumericDate(newExpiresAt),
			IssuedAt:  issuedAt,
			Subject:   claims.UserID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, newClaims)
	tokenString, err := token.SignedString([]byte(m.secretKey))
	if err != nil {
		return "", time.Time{}, err
	}

	return tokenString, newExpiresAt, nil
}

func (m *TokenMaker) VerifyToken(tokenString string) (*JWTClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return []byte(m.secretKey), nil
	})

	if err != nil {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*JWTClaims)
	if !ok || !token.Valid {
		return nil, ErrInvalidToken
	}

	return claims, nil
}
