package config

import (
	"os"
	"strconv"
)

// defaultJWTExpiryHours is 7 days. It used to be 1440 (60 days), which meant a
// single stolen token stayed usable for two months. Active users are not signed
// out by the shorter window: the auth middleware slides the expiry forward on
// every request once a session is past its halfway point.
const defaultJWTExpiryHours = 168

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
	appEnv := getEnv("APP_ENV", "development")
	isProduction := appEnv == "production"

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		// The development fallback embeds postgres:postgres. Falling back to it in
		// production would silently point a live deployment at a default-credential
		// database, so require the variable there instead.
		if isProduction {
			panic("FATAL: DATABASE_URL wajib dikonfigurasi pada environment production!")
		}
		dbURL = "postgres://postgres:postgres@localhost:5432/kantin_digital?sslmode=disable"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		if isProduction {
			panic("FATAL: JWT_SECRET wajib dikonfigurasi pada environment production!")
		}
		jwtSecret = "kantin-digital-v2-super-secret-key-2026-dev-only"
	}

	corsOrigins := getEnv("CORS_ORIGINS", "*")
	if isProduction && corsOrigins == "*" {
		// The API answers with AllowCredentials: true, so a wildcard origin lets any
		// website on the internet make cookie-authenticated calls on behalf of a
		// logged-in visitor. Fiber cannot express "wildcard but without credentials",
		// so production has to name its origins.
		panic("FATAL: CORS_ORIGINS tidak boleh '*' pada environment production. Isi dengan daftar origin eksplisit, contoh: CORS_ORIGINS=https://zitech.web.id,https://kantin.zitech.web.id")
	}

	uploadDir := getEnv("UPLOAD_DIR", "./uploads")

	expiryHours, err := strconv.Atoi(getEnv("JWT_EXPIRY_HOURS", strconv.Itoa(defaultJWTExpiryHours)))
	if err != nil || expiryHours <= 0 {
		expiryHours = defaultJWTExpiryHours
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
