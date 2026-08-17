package config

import (
	"os"
	"strconv"
)

type Config struct {
	Port           string
	DatabaseURL    string
	JWTSecret      string
	JWTExpiryHours int
	CORSOrigins    string
	UploadDir      string
	AppEnv         string
}

func LoadConfig() *Config {
	port := getEnv("PORT", "8000")
	dbURL := getEnv("DATABASE_URL", "postgres://postgres:postgres@localhost:5432/kantin_digital?sslmode=disable")
	appEnv := getEnv("APP_ENV", "development")
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		if appEnv == "production" {
			panic("FATAL: JWT_SECRET wajib dikonfigurasi pada environment production!")
		}
		jwtSecret = "kantin-digital-v2-super-secret-key-2026-dev-only"
	}
	expiryStr := getEnv("JWT_EXPIRY_HOURS", "72")
	corsOrigins := getEnv("CORS_ORIGINS", "*")
	uploadDir := getEnv("UPLOAD_DIR", "./uploads")

	expiryHours, err := strconv.Atoi(expiryStr)
	if err != nil {
		expiryHours = 72
	}

	return &Config{
		Port:           port,
		DatabaseURL:    dbURL,
		JWTSecret:      jwtSecret,
		JWTExpiryHours: expiryHours,
		CORSOrigins:    corsOrigins,
		UploadDir:      uploadDir,
		AppEnv:         appEnv,
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}
