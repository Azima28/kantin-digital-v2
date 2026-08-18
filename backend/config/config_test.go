package config

import (
	"os"
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

	if cfg.JWTExpiryHours != 1440 {
		t.Errorf("Expected default JWTExpiryHours 1440, got %d", cfg.JWTExpiryHours)
	}
}
