import os
import json

def format_sql_val(val):
    if val is None:
        return "NULL"
    elif isinstance(val, bool):
        return "TRUE" if val else "FALSE"
    elif isinstance(val, (int, float)):
        return str(val)
    elif isinstance(val, (dict, list)):
        escaped_json = json.dumps(val).replace("'", "''")
        return f"'{escaped_json}'::jsonb"
    else:
        escaped_str = str(val).replace("'", "''")
        return f"'{escaped_str}'"

def main():
    json_dir = "database_backup/json"
    output_sql = "database_backup/init_postgres_standalone.sql"

    # Define table execution order for clean Foreign Key imports
    tables_order = [
        "profiles",
        "students",
        "canteen_operators",
        "finance_officers",
        "parent_students",
        "products",
        "orders",
        "order_items",
        "order_messages",
        "transactions",
        "transaction_items",
        "notifications",
        "audit_logs",
        "system_settings",
        "user_sessions"
    ]

    schema_sql = """-- =====================================================================
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
    rombel_id UUID
);

-- ---------------------------------------------------------------------
-- 3. Table: public.canteen_operators
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.canteen_operators (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    canteen_name TEXT NOT NULL,
    balance_earned INTEGER NOT NULL DEFAULT 0 CHECK (balance_earned >= 0),
    is_delivery_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    delivery_fee INTEGER NOT NULL DEFAULT 2000 CHECK (delivery_fee >= 0)
);

-- ---------------------------------------------------------------------
-- 4. Table: public.finance_officers
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.finance_officers (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    total_managed_funds BIGINT NOT NULL DEFAULT 0 CHECK (total_managed_funds >= 0)
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
    status TEXT NOT NULL DEFAULT 'Baru' CHECK (status IN ('Baru', 'Sedang Dimasak', 'Siap Diambil', 'Siap Diantar', 'Selesai', 'Dibatalkan', 'Menunggu Pembatalan', 'Menunggu Persetujuan Murid')),
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
    product_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price INTEGER NOT NULL CHECK (price >= 0),
    selected_options JSONB DEFAULT '[]'::jsonb
);

-- ---------------------------------------------------------------------
-- 9. Table: public.order_messages
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    sender_role TEXT NOT NULL CHECK (sender_role IN ('student', 'petugas_kantin', 'system')),
    message TEXT NOT NULL,
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
    type TEXT NOT NULL CHECK (type IN ('purchase', 'topup', 'correction', 'refund')),
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
"""

    lines = [schema_sql]
    lines.append("\n-- =====================================================================")
    lines.append("-- DATA RESTORE SECTION (406 RECORDS)")
    lines.append("-- =====================================================================\n")

    for tbl in tables_order:
        json_path = os.path.join(json_dir, f"{tbl}.json")
        if not os.path.exists(json_path):
            continue

        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        if not data:
            continue

        lines.append(f"\n-- Data: {tbl} ({len(data)} rows)")
        cols = list(data[0].keys())
        cols_formatted = ", ".join([f'"{c}"' for c in cols])

        for row in data:
            vals = [format_sql_val(row.get(c)) for c in cols]
            lines.append(f"INSERT INTO public.{tbl} ({cols_formatted}) VALUES ({', '.join(vals)}) ON CONFLICT (id) DO NOTHING;" if "id" in cols else f"INSERT INTO public.{tbl} ({cols_formatted}) VALUES ({', '.join(vals)}) ON CONFLICT DO NOTHING;")

    with open(output_sql, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"[SUCCESS] Standalone PostgreSQL initial script generated: {output_sql}")

if __name__ == "__main__":
    main()
