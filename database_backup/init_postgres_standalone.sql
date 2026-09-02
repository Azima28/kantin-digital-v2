-- =====================================================================
-- KANTIN DIGITAL v2.0 - STANDALONE POSTGRESQL DATABASE INITIALIZATION
-- Zero Supabase Proprietary Dependencies (Native PostgreSQL 14/15/16/17)
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. Table: public.profiles
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'petugas_kantin', 'petugas_keuangan', 'parent', 'super_admin', 'admin')),
    password TEXT,
    username TEXT UNIQUE,
    nisn TEXT UNIQUE,
    phone_number TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    relation TEXT,
    avatar_url TEXT,
    gender TEXT DEFAULT 'L',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 2. Table: public.students
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.students (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance INTEGER NOT NULL DEFAULT 0 CHECK (balance >= 0),
    rfid_uid TEXT UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    daily_limit INTEGER DEFAULT 0 CHECK (daily_limit >= 0),
    wa_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    parent_phone TEXT,
    class_id UUID,
    rombel_id UUID,
    class TEXT,
    rombel TEXT
);

-- ---------------------------------------------------------------------
-- 3. Table: public.canteen_operators
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.canteen_operators (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    canteen_name TEXT NOT NULL,
    balance_earned INTEGER NOT NULL DEFAULT 0 CHECK (balance_earned >= 0),
    is_delivery_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    delivery_fee INTEGER NOT NULL DEFAULT 2000 CHECK (delivery_fee >= 0),
    rating NUMERIC(3,2) DEFAULT 4.85,
    total_reviews INTEGER DEFAULT 0
);

-- ---------------------------------------------------------------------
-- 4. Table: public.finance_officers
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.finance_officers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    assigned_school TEXT NOT NULL DEFAULT 'Sekolah Digital',
    authority_level TEXT NOT NULL DEFAULT 'L1',
    features JSONB DEFAULT '["topup", "withdrawal", "correction"]'::jsonb,
    total_managed_funds BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 5. Table: public.parent_students
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.parent_students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(parent_id, student_id)
);

-- ---------------------------------------------------------------------
-- 6. Table: public.products
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    operator_id UUID NOT NULL REFERENCES public.canteen_operators(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    price INTEGER NOT NULL CHECK (price >= 0),
    category TEXT NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    image_url TEXT,
    customizable_options JSONB DEFAULT '[]'::jsonb,
    rating NUMERIC(3,2) DEFAULT 4.80,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 7. Table: public.orders
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    student_name TEXT NOT NULL,
    operator_id UUID REFERENCES public.canteen_operators(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'Baru' CHECK (status IN ('Baru', 'Sedang Dimasak', 'Sedang Disiapkan', 'Siap Diambil', 'Siap Diantar', 'Sedang Diantar', 'Selesai', 'Dibatalkan', 'Menunggu Pembatalan', 'Menunggu Persetujuan Murid')),
    delivery_location TEXT,
    total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
    cancel_request_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 8. Table: public.order_items
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price INTEGER NOT NULL CHECK (price >= 0),
    selected_options JSONB DEFAULT '[]'::jsonb,
    notes TEXT DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);

-- ---------------------------------------------------------------------
-- 9. Table: public.order_messages
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('student', 'petugas_kantin', 'canteen_operator', 'admin', 'super_admin', 'petugas_keuangan', 'system')),
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 10. Table: public.transactions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    operator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_amount INTEGER NOT NULL CHECK (total_amount >= 0),
    type TEXT NOT NULL CHECK (type IN ('purchase', 'topup', 'correction', 'refund', 'withdrawal', 'merchant_adjustment')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('success', 'pending', 'cancelled', 'refunded')),
    purchase_method TEXT DEFAULT 'cashless',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 11. Table: public.transaction_items
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.transaction_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price INTEGER NOT NULL CHECK (unit_price >= 0),
    custom_notes TEXT
);

-- ---------------------------------------------------------------------
-- 12. Table: public.notifications
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 13. Table: public.audit_logs
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_name TEXT NOT NULL,
    entity_id TEXT,
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 14. Table: public.system_settings
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.system_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 15. Table: public.user_sessions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- 16. Table: public.order_reviews
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    operator_id UUID REFERENCES public.canteen_operators(id) ON DELETE SET NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT DEFAULT '',
    tags JSONB DEFAULT '[]'::jsonb,
    is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_reviews_product ON public.order_reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_order_reviews_operator ON public.order_reviews(operator_id);

-- ---------------------------------------------------------------------
-- 17. Table: public.cashier_shifts
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cashier_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    officer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    shift_number INTEGER NOT NULL DEFAULT 1,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    starting_cash INTEGER NOT NULL DEFAULT 0,
    total_inflow INTEGER NOT NULL DEFAULT 0,
    total_outflow INTEGER NOT NULL DEFAULT 0,
    expected_cash INTEGER NOT NULL DEFAULT 0,
    actual_physical_cash INTEGER NOT NULL DEFAULT 0,
    difference INTEGER NOT NULL DEFAULT 0,
    topup_count INTEGER NOT NULL DEFAULT 0,
    payout_count INTEGER NOT NULL DEFAULT 0,
    notes TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'closed' CHECK (status IN ('active', 'closed', 'verified')),
    verified_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cashier_shifts_officer_id ON public.cashier_shifts(officer_id);
CREATE INDEX IF NOT EXISTS idx_cashier_shifts_closed_at ON public.cashier_shifts(closed_at DESC);

-- ---------------------------------------------------------------------
-- 18. Table: public.revoked_tokens
--     Per-token blacklist. A logout inserts the token's jti here and the
--     auth middleware refuses that exact session until it would have
--     expired anyway; expires_at is what keeps the table bounded.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.revoked_tokens (
    jti TEXT PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_revoked_tokens_expires_at ON public.revoked_tokens(expires_at);

-- ---------------------------------------------------------------------
-- 19. Table: public.user_session_epochs
--     Bulk revocation watermark. A password change or an admin-forced
--     deactivation moves not_before forward, so every token issued before
--     that instant is refused -- including legacy tokens minted before jti
--     existed, which have no id to blacklist individually.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_session_epochs (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    not_before TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- PERFORMANCE INDEXES
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_students_rfid ON public.students(rfid_uid);
CREATE INDEX IF NOT EXISTS idx_orders_student ON public.orders(student_id);
CREATE INDEX IF NOT EXISTS idx_orders_operator ON public.orders(operator_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_messages_order ON public.order_messages(order_id);
CREATE INDEX IF NOT EXISTS idx_transactions_student ON public.transactions(student_id);
CREATE INDEX IF NOT EXISTS idx_transactions_operator ON public.transactions(operator_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created ON public.transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_student ON public.notifications(student_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_operator ON public.products(operator_id);

-- =====================================================================
-- IDEMPOTENT SCHEMA RECONCILIATION
--
-- Postgres only runs /docker-entrypoint-initdb.d on a *fresh* data
-- directory, so everything above is skipped on a volume that already has
-- a database in it. That is how this file drifted behind the Go code in
-- the first place. Every statement below is a no-op on a schema that is
-- already correct, which makes the whole file safe to replay by hand:
--
--   docker compose exec -T postgres psql -U postgres -d kantin_digital -f /docker-entrypoint-initdb.d/01_init.sql
--
-- Run that after pulling a change that touches the schema, instead of
-- destroying the volume.
-- =====================================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'L';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS relation TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_number TEXT;

ALTER TABLE public.students ADD COLUMN IF NOT EXISTS class TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS rombel TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS class_id UUID;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS rombel_id UUID;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS daily_limit INTEGER DEFAULT 0;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS parent_phone TEXT;
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS wa_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;

ALTER TABLE public.canteen_operators ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 4.85;
ALTER TABLE public.canteen_operators ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
ALTER TABLE public.canteen_operators ADD COLUMN IF NOT EXISTS is_delivery_enabled BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.canteen_operators ADD COLUMN IF NOT EXISTS delivery_fee INTEGER NOT NULL DEFAULT 2000;

ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS assigned_school TEXT NOT NULL DEFAULT 'Sekolah Digital';
ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS authority_level TEXT NOT NULL DEFAULT 'L1';
ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '["topup", "withdrawal", "correction"]'::jsonb;
ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS total_managed_funds BIGINT NOT NULL DEFAULT 0;
ALTER TABLE public.finance_officers ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 4.80;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS total_reviews INTEGER DEFAULT 0;
ALTER TABLE public.products ADD COLUMN IF NOT EXISTS customizable_options JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_location TEXT;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS cancel_request_reason TEXT;

ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS selected_options JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.order_items ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';

ALTER TABLE public.order_messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS purchase_method TEXT DEFAULT 'cashless';

ALTER TABLE public.order_reviews ADD COLUMN IF NOT EXISTS product_id UUID REFERENCES public.products(id) ON DELETE SET NULL;
ALTER TABLE public.order_reviews ADD COLUMN IF NOT EXISTS product_name TEXT;
ALTER TABLE public.order_reviews ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.order_reviews ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN NOT NULL DEFAULT FALSE;

-- CHECK constraints are replaced rather than added, because a stale one
-- rejects writes the backend now makes. db.go already does exactly this
-- for transactions_type_check at every boot; the other three only ever
-- got the widened list here, so a volume created before this change still
-- refuses 'Sedang Disiapkan', 'Sedang Diantar' and the newer sender roles.
DO $$
BEGIN
    ALTER TABLE public.transactions DROP CONSTRAINT IF EXISTS transactions_type_check;
    ALTER TABLE public.transactions ADD CONSTRAINT transactions_type_check
        CHECK (type IN ('purchase', 'topup', 'correction', 'refund', 'withdrawal', 'merchant_adjustment'));
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'constraint % dilewati: %', 'transactions_type_check', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE public.orders DROP CONSTRAINT IF EXISTS orders_status_check;
    ALTER TABLE public.orders ADD CONSTRAINT orders_status_check
        CHECK (status IN ('Baru', 'Sedang Dimasak', 'Sedang Disiapkan', 'Siap Diambil', 'Siap Diantar', 'Sedang Diantar', 'Selesai', 'Dibatalkan', 'Menunggu Pembatalan', 'Menunggu Persetujuan Murid'));
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'constraint % dilewati: %', 'orders_status_check', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE public.order_messages DROP CONSTRAINT IF EXISTS order_messages_sender_role_check;
    ALTER TABLE public.order_messages ADD CONSTRAINT order_messages_sender_role_check
        CHECK (sender_role IN ('student', 'petugas_kantin', 'canteen_operator', 'admin', 'super_admin', 'petugas_keuangan', 'system'));
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'constraint % dilewati: %', 'order_messages_sender_role_check', SQLERRM;
END $$;

DO $$
BEGIN
    ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
    ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
        CHECK (role IN ('student', 'petugas_kantin', 'petugas_keuangan', 'parent', 'super_admin', 'admin'));
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'constraint % dilewati: %', 'profiles_role_check', SQLERRM;
END $$;
