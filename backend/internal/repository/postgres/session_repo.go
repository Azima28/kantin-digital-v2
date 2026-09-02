package postgres

import (
	"context"
	"time"
)

// SessionRepo is the revocation side of authentication.
//
// Access tokens are self-contained JWTs, so until now nothing could end a
// session early: a token stayed valid for its whole lifetime even after the
// owner logged out, changed their password, or had their account reset by an
// admin. Anyone holding a copy kept that access for the rest of the window.
//
// Two mechanisms cover the two shapes that revocation takes:
//
//   - revoked_tokens kills exactly one session by its jti. This is logout.
//   - user_session_epochs kills every session a user currently holds by moving a
//     not_before watermark forward; any token issued before it is refused. This is
//     what a password change or an admin-forced reset needs, and it also covers
//     tokens minted before jti existed, which have no id to blacklist.
type SessionRepo struct {
	db *DB
}

func NewSessionRepo(db *DB) *SessionRepo {
	repo := &SessionRepo{db: db}
	repo.ensureSchema(context.Background())
	return repo
}

func (r *SessionRepo) ensureSchema(ctx context.Context) {
	if r.db == nil || r.db.Pool == nil {
		return
	}
	_, _ = r.db.Pool.Exec(ctx, `
		CREATE TABLE IF NOT EXISTS public.revoked_tokens (
			jti TEXT PRIMARY KEY,
			user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
			expires_at TIMESTAMPTZ NOT NULL,
			revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);

		CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at ON public.revoked_tokens(expires_at);

		CREATE TABLE IF NOT EXISTS public.user_session_epochs (
			user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
			not_before TIMESTAMPTZ NOT NULL,
			updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
		);
	`)
}

// RevokeToken blacklists a single session id until the token would have expired
// anyway. Storing expires_at is what keeps the table from growing without bound:
// a row is only useful while the token it refers to is still otherwise valid.
func (r *SessionRepo) RevokeToken(ctx context.Context, jti, userID string, expiresAt time.Time) error {
	if r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}
	if jti == "" {
		return nil
	}
	var owner interface{}
	if userID != "" {
		owner = userID
	}
	_, err := r.db.Pool.Exec(ctx, `
		INSERT INTO public.revoked_tokens (jti, user_id, expires_at)
		VALUES ($1, $2, $3)
		ON CONFLICT (jti) DO NOTHING`,
		jti, owner, expiresAt)
	if err != nil {
		return err
	}
	// Opportunistic cleanup: bounded work, and it keeps the lookup on the hot
	// authentication path reading a small table.
	_, _ = r.db.Pool.Exec(ctx, `DELETE FROM public.revoked_tokens WHERE expires_at < NOW()`)
	return nil
}

// RevokeAllForUser refuses every token this user was issued before notBefore.
//
// The watermark is truncated to whole seconds because that is all a JWT can
// express: iat is a Unix second count. Without the truncation, revoking at
// 10:00:00.4 and immediately minting the caller's replacement token at 10:00:00.7
// would store 10:00:00.4 but stamp the new token 10:00:00 -- and the middleware
// would throw away the token it had just issued. Truncating means a session that
// began in the same second as the revocation survives, which is the caller's own
// device on a password change and is the behaviour we want.
func (r *SessionRepo) RevokeAllForUser(ctx context.Context, userID string, notBefore time.Time) error {
	if r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}
	if userID == "" {
		return nil
	}
	notBefore = notBefore.Truncate(time.Second)
	_, err := r.db.Pool.Exec(ctx, `
		INSERT INTO public.user_session_epochs (user_id, not_before, updated_at)
		VALUES ($1, $2, NOW())
		ON CONFLICT (user_id) DO UPDATE SET not_before = EXCLUDED.not_before, updated_at = NOW()`,
		userID, notBefore)
	return err
}

// CheckRevocation answers both questions in one round trip, because it runs on
// every authenticated request. A zero notBefore means the user has no watermark.
func (r *SessionRepo) CheckRevocation(ctx context.Context, jti, userID string) (bool, time.Time, error) {
	if r.db == nil || r.db.Pool == nil {
		return false, time.Time{}, ErrDatabaseNotReady
	}
	var revoked bool
	var notBefore *time.Time
	var owner interface{}
	if userID != "" {
		owner = userID
	}
	err := r.db.Pool.QueryRow(ctx, `
		SELECT
			EXISTS (SELECT 1 FROM public.revoked_tokens WHERE jti = $1),
			(SELECT not_before FROM public.user_session_epochs WHERE user_id = $2)`,
		jti, owner).Scan(&revoked, &notBefore)
	if err != nil {
		return false, time.Time{}, err
	}
	if notBefore == nil {
		return revoked, time.Time{}, nil
	}
	return revoked, *notBefore, nil
}

// PurgeExpired drops blacklist rows whose tokens have expired on their own.
func (r *SessionRepo) PurgeExpired(ctx context.Context) error {
	if r.db == nil || r.db.Pool == nil {
		return ErrDatabaseNotReady
	}
	_, err := r.db.Pool.Exec(ctx, `DELETE FROM public.revoked_tokens WHERE expires_at < NOW()`)
	return err
}
