package postgres

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DB struct {
	Pool *pgxpool.Pool
}

func tryAutoStartWindowsPostgres() {
	if runtime.GOOS != "windows" {
		return
	}

	pgCtlPaths := []struct {
		pgCtl string
		data  string
		log   string
	}{
		{
			pgCtl: `C:\laragon\bin\postgresql\pgsql\bin\pg_ctl.exe`,
			data:  `C:\laragon\bin\postgresql\data`,
			log:   `C:\laragon\bin\postgresql\logfile.log`,
		},
		{
			pgCtl: `C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe`,
			data:  `C:\Program Files\PostgreSQL\16\data`,
			log:   `C:\Program Files\PostgreSQL\16\logfile.log`,
		},
	}

	for _, p := range pgCtlPaths {
		if _, err := os.Stat(p.pgCtl); err == nil {
			if _, err := os.Stat(p.data); err == nil {
				log.Printf("[AUTO-HEAL] Mencoba menjalankan PostgreSQL engine otomatis via %s...", p.pgCtl)
				_ = os.MkdirAll(filepath.Dir(p.log), 0755)
				cmd := exec.Command(p.pgCtl, "-D", p.data, "-l", p.log, "start")
				_ = cmd.Run()
				time.Sleep(2 * time.Second)
				return
			}
		}
	}
}

func NewDB(ctx context.Context, databaseURL string) (*DB, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("gagal parse database config: %w", err)
	}

	config.MaxConns = 50
	config.MinConns = 5
	config.MaxConnLifetime = 1 * time.Hour
	config.MaxConnIdleTime = 30 * time.Minute

	var pool *pgxpool.Pool
	var lastErr error

	// Retry connection loop (up to 3 attempts with auto-start helper)
	for attempt := 1; attempt <= 3; attempt++ {
		attemptCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
		pool, err = pgxpool.NewWithConfig(attemptCtx, config)
		if err == nil {
			if pingErr := pool.Ping(attemptCtx); pingErr == nil {
				cancel()

				// Auto-ensure transactions type check constraint includes withdrawal & merchant_adjustment
				_, _ = pool.Exec(context.Background(), `
					DO $$
					BEGIN
						ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_type_check;
						ALTER TABLE public.transactions ADD CONSTRAINT transactions_type_check
							CHECK (type IN ('purchase', 'topup', 'correction', 'refund', 'withdrawal', 'merchant_adjustment'));
					EXCEPTION
						WHEN OTHERS THEN NULL;
					END $$;
				`)

				return &DB{Pool: pool}, nil
			} else {
				lastErr = pingErr
				pool.Close()
			}
		} else {
			lastErr = err
		}
		cancel()

		if attempt == 1 {
			tryAutoStartWindowsPostgres()
		}
		time.Sleep(1 * time.Second)
	}

	return nil, fmt.Errorf("gagal membuat koneksi pgx pool setelah 3 kali percobaan: %w", lastErr)
}

func (db *DB) Close() {
	if db != nil && db.Pool != nil {
		db.Pool.Close()
	}
}
