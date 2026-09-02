package config

import (
	"os"
	"strings"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	os.Setenv("PORT", "9090")
	os.Setenv("JWT_SECRET", "custom-secret-test")

	cfg := LoadConfig()

	if cfg.Port != "9090" {
		t.Errorf("Expected Port 9090, got %s", cfg.Port)
	}

	if cfg.JWTSecret != "custom-secret-test" {
		t.Errorf("Expected JWTSecret 'custom-secret-test', got %s", cfg.JWTSecret)
	}

	// 168 hours, not the 1440 this used to assert: a two-month access token cannot be
	// taken back, and sliding renewal keeps active users signed in anyway.
	if cfg.JWTExpiryHours != defaultJWTExpiryHours {
		t.Errorf("Expected default JWTExpiryHours %d, got %d", defaultJWTExpiryHours, cfg.JWTExpiryHours)
	}
}

// A production boot must not be able to fall back to a development default that
// weakens authentication or opens the API to every origin. Each of these is a
// deliberate startup panic, so the test asserts the panic rather than a value.
func TestLoadConfigProductionRejectsWildcardCORS(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("DATABASE_URL", "postgres://user:pass@localhost:5432/db")
	t.Setenv("JWT_SECRET", "a-real-secret")
	t.Setenv("CORS_ORIGINS", "*")

	assertPanics(t, "CORS_ORIGINS", LoadConfig)
}

func TestLoadConfigProductionRequiresDatabaseURL(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("DATABASE_URL", "")
	t.Setenv("JWT_SECRET", "a-real-secret")
	t.Setenv("CORS_ORIGINS", "https://kantin.example.id")

	assertPanics(t, "DATABASE_URL", LoadConfig)
}

func TestLoadConfigProductionRequiresJWTSecret(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("DATABASE_URL", "postgres://user:pass@localhost:5432/db")
	t.Setenv("JWT_SECRET", "")
	t.Setenv("CORS_ORIGINS", "https://kantin.example.id")

	assertPanics(t, "JWT_SECRET", LoadConfig)
}

func TestLoadConfigProductionAcceptsExplicitOrigins(t *testing.T) {
	t.Setenv("APP_ENV", "production")
	t.Setenv("DATABASE_URL", "postgres://user:pass@localhost:5432/db")
	t.Setenv("JWT_SECRET", "a-real-secret")
	t.Setenv("CORS_ORIGINS", "https://kantin.example.id,https://admin.example.id")

	cfg := LoadConfig()
	if cfg.CORSOrigins != "https://kantin.example.id,https://admin.example.id" {
		t.Errorf("origin list was not preserved, got %s", cfg.CORSOrigins)
	}
}

func assertPanics(t *testing.T, wantSubstring string, fn func() *Config) {
	t.Helper()
	defer func() {
		recovered := recover()
		if recovered == nil {
			t.Fatalf("expected LoadConfig to panic about %s, it returned normally", wantSubstring)
		}
		message, ok := recovered.(string)
		if !ok || !strings.Contains(message, wantSubstring) {
			t.Fatalf("expected panic mentioning %s, got %v", wantSubstring, recovered)
		}
	}()
	_ = fn()
}
