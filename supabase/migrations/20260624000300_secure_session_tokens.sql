-- =====================================================================
-- Migration: Secure Session Tokens (No-RLS Hardening)
-- Tanggal: 2026-06-24
-- Tujuan: Mengamankan fungsi transaksi tanpa mengaktifkan RLS dengan 
--         menggunakan token sesi dinamis berumur terbatas (12 jam) 
--         yang di-hash SHA-256 di sisi database.
-- =====================================================================

-- 1. Buat tabel user_sessions untuk menyimpan hash token sesi
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Index untuk mempercepat pencarian token hash
CREATE INDEX IF NOT EXISTS idx_user_sessions_token_hash ON public.user_sessions(token_hash);

-- 2. Buat RPC create_user_session untuk memvalidasi password dan menghasilkan token
CREATE OR REPLACE FUNCTION public.create_user_session(
    p_email TEXT,
    p_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_profile JSONB;
    v_token UUID;
    v_token_hash TEXT;
    v_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Verifikasi password menggunakan verify_password RPC (yang membandingkan hash bcrypt)
    v_profile := public.verify_password(p_email, p_password);

    IF v_profile IS NULL OR (v_profile->>'found')::BOOLEAN = false OR (v_profile->>'password_valid')::BOOLEAN = false THEN
        RETURN jsonb_build_object('success', false, 'error', 'Email/Username/NISN atau kata sandi salah.');
    END IF;

    -- Batalkan sesi lama milik user ini agar tidak menumpuk
    DELETE FROM public.user_sessions WHERE user_id = (v_profile->>'id')::UUID;

    -- Buat token UUID baru
    v_token := gen_random_uuid();
    -- Hash token tersebut menggunakan SHA-256
    v_token_hash := extensions.encode(extensions.digest(v_token::TEXT, 'sha256'), 'hex');
    -- Kedaluwarsa 12 jam dari sekarang
    v_expires_at := now() + INTERVAL '12 hours';

    -- Simpan hash ke database
    INSERT INTO public.user_sessions (user_id, token_hash, expires_at)
    VALUES ((v_profile->>'id')::UUID, v_token_hash, v_expires_at);

    RETURN jsonb_build_object(
        'success', true,
        'session_token', v_token::TEXT,
        'profile', v_profile
    );
END;
$$;

-- Berikan izin akses eksekusi RPC sesi ke publik/anon
GRANT EXECUTE ON FUNCTION public.create_user_session(TEXT, TEXT) TO authenticated, anon, public;


-- 3. DROP FUNGSI LAMA AGAR TIDAK CONFLICT SIGNATURE
DROP FUNCTION IF EXISTS public.process_purchase(TEXT, UUID, JSONB, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.process_refund(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.process_topup(UUID, BIGINT, UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.process_correction(UUID, BIGINT, UUID, TEXT) CASCADE;


-- 4. RECREATE process_purchase dengan validasi token sesi SHA-256
CREATE OR REPLACE FUNCTION public.process_purchase(
    p_rfid_uid TEXT,
    p_session_token TEXT,
    p_items JSONB,
    p_total_amount BIGINT
)
RETURNS JSONB AS $$
DECLARE
    v_operator_id     UUID;
    v_student_id      UUID;
    v_student_name    TEXT;
    v_student_balance BIGINT;
    v_student_active  BOOLEAN;
    v_daily_limit     NUMERIC;
    v_today_spending  NUMERIC;
    v_transaction_id  UUID;
    v_item            RECORD;
    v_canteen_name    TEXT;
    v_tz              TEXT := 'Asia/Jakarta';
    v_today_start     TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Validasi token sesi ke operator_id
    SELECT user_id INTO v_operator_id
    FROM public.user_sessions
    WHERE token_hash = extensions.encode(extensions.digest(p_session_token, 'sha256'), 'hex')
      AND expires_at > NOW();

    IF v_operator_id IS NULL THEN
        RAISE EXCEPTION 'Sesi tidak valid atau telah kedaluwarsa. Silakan keluar dan masuk kembali.';
    END IF;

    -- Role check: operator_id harus terdaftar di canteen_operators
    IF NOT EXISTS (SELECT 1 FROM public.canteen_operators WHERE id = v_operator_id) THEN
        RAISE EXCEPTION 'Akses ditolak: Hanya operator kantin yang dapat melakukan transaksi pembelian';
    END IF;

    v_today_start := date_trunc('day', NOW() AT TIME ZONE v_tz) AT TIME ZONE v_tz;

    -- Kunci baris siswa berdasarkan RFID (FOR UPDATE mencegah double spend ganda)
    SELECT s.id, p.full_name, s.balance, s.is_active, s.daily_limit
    INTO v_student_id, v_student_name, v_student_balance, v_student_active, v_daily_limit
    FROM public.students s
    JOIN public.profiles p ON s.id = p.id
    WHERE s.rfid_uid = p_rfid_uid
    FOR UPDATE;

    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Kartu siswa tidak terdaftar di sistem';
    END IF;

    IF NOT v_student_active THEN
        RAISE EXCEPTION 'Kartu siswa diblokir atau dinonaktifkan';
    END IF;

    IF v_student_balance < p_total_amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk melakukan transaksi';
    END IF;

    -- Validasi limit jajan harian
    IF v_daily_limit > 0 THEN
        SELECT COALESCE(SUM(total_amount), 0)
        INTO v_today_spending
        FROM public.transactions
        WHERE student_id = v_student_id
          AND type = 'purchase'
          AND status = 'success'
          AND created_at >= v_today_start;

        IF (v_today_spending + p_total_amount) > v_daily_limit THEN
            RAISE EXCEPTION 'Batas jajan harian terlampaui. Sisa limit: Rp %',
                to_char(GREATEST(0, v_daily_limit - v_today_spending), 'FM999,999,999');
        END IF;
    END IF;

    SELECT canteen_name INTO v_canteen_name
    FROM public.canteen_operators
    WHERE id = v_operator_id;

    -- Potong saldo siswa
    UPDATE public.students
    SET balance = balance - p_total_amount
    WHERE id = v_student_id;

    -- Tambah pendapatan operator stan kantin
    UPDATE public.canteen_operators
    SET balance_earned = balance_earned + p_total_amount
    WHERE id = v_operator_id;

    -- Catat transaksi
    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status)
    VALUES (v_student_id, v_operator_id, p_total_amount, 'purchase', 'success')
    RETURNING id INTO v_transaction_id;

    -- Catat item transaksi
    FOR v_item IN
        SELECT * FROM jsonb_to_recordset(p_items)
        AS x(product_id UUID, quantity INT, unit_price NUMERIC, custom_notes TEXT)
    LOOP
        INSERT INTO public.transaction_items (transaction_id, product_id, quantity, unit_price, custom_notes)
        VALUES (v_transaction_id, v_item.product_id, v_item.quantity, v_item.unit_price, v_item.custom_notes);
    END LOOP;

    -- Kirim Notifikasi
    INSERT INTO public.notifications (student_id, title, message, type)
    VALUES (
        v_student_id,
        'Jajan Berhasil!',
        'Kamu berhasil membeli senilai Rp ' || to_char(p_total_amount, 'FM999,999,999') || ' di ' || COALESCE(v_canteen_name, 'Kantin'),
        'purchase'
    );

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_transaction_id,
        'student_name', v_student_name,
        'remaining_balance', v_student_balance - p_total_amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';


-- 5. RECREATE process_refund dengan validasi token sesi SHA-256
CREATE OR REPLACE FUNCTION public.process_refund(
    p_transaction_id UUID,
    p_session_token TEXT,
    p_reason TEXT DEFAULT ''
)
RETURNS JSONB AS $$
DECLARE
    v_operator_id     UUID;
    v_student_id      UUID;
    v_total_amount    BIGINT;
    v_transaction_status TEXT;
    v_transaction_type TEXT;
    v_transaction_operator UUID;
    v_created_at      TIMESTAMP WITH TIME ZONE;
    v_canteen_name    TEXT;
BEGIN
    -- Validasi token sesi ke operator_id
    SELECT user_id INTO v_operator_id
    FROM public.user_sessions
    WHERE token_hash = extensions.encode(extensions.digest(p_session_token, 'sha256'), 'hex')
      AND expires_at > NOW();

    IF v_operator_id IS NULL THEN
        RAISE EXCEPTION 'Sesi tidak valid atau telah kedaluwarsa. Silakan keluar dan masuk kembali.';
    END IF;

    -- Ambil data transaksi
    SELECT student_id, operator_id, total_amount::BIGINT, status, type, created_at
    INTO v_student_id, v_transaction_operator, v_total_amount, v_transaction_status, v_transaction_type, v_created_at
    FROM public.transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'ID Transaksi tidak ditemukan';
    END IF;

    -- Validasi hak milik operator
    IF v_transaction_operator <> v_operator_id THEN
        RAISE EXCEPTION 'Akses ditolak: Transaksi ini bukan milik stan kantin Anda';
    END IF;

    IF v_transaction_status <> 'success' THEN
        RAISE EXCEPTION 'Transaksi tidak dapat di-refund karena status saat ini: %', v_transaction_status;
    END IF;

    IF v_transaction_type <> 'purchase' THEN
        RAISE EXCEPTION 'Hanya transaksi pembelian belanja yang dapat dibatalkan/di-refund';
    END IF;

    IF v_created_at < now() - INTERVAL '10 minutes' THEN
        RAISE EXCEPTION 'Batas waktu pembatalan/refund telah berakhir (maksimal 10 menit)';
    END IF;

    SELECT canteen_name INTO v_canteen_name
    FROM public.canteen_operators
    WHERE id = v_operator_id;

    -- Lock siswa
    PERFORM balance FROM public.students WHERE id = v_student_id FOR UPDATE;

    -- Batalkan transaksi
    UPDATE public.transactions SET status = 'cancelled' WHERE id = p_transaction_id;

    -- Kembalikan saldo siswa
    UPDATE public.students SET balance = balance + v_total_amount WHERE id = v_student_id;

    -- Kurangi saldo operator
    UPDATE public.canteen_operators SET balance_earned = balance_earned - v_total_amount WHERE id = v_operator_id;

    INSERT INTO public.notifications (student_id, title, message, type)
    VALUES (
        v_student_id,
        'Transaksi Dibatalkan (Refund)',
        'Belanja senilai Rp ' || to_char(v_total_amount, 'FM999,999,999') || ' di ' || COALESCE(v_canteen_name, 'Kantin') || ' telah dibatalkan. Saldo dikembalikan.',
        'system'
    );

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Transaksi berhasil dibatalkan dan saldo siswa telah dikembalikan',
        'refunded_amount', v_total_amount
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';


-- 6. RECREATE process_topup dengan validasi token sesi SHA-256
CREATE OR REPLACE FUNCTION public.process_topup(
    p_student_id UUID,
    p_amount BIGINT,
    p_session_token TEXT,
    p_method TEXT DEFAULT 'tunai',
    p_notes TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_operator_id    UUID;
    v_old_balance    BIGINT;
    v_new_balance    BIGINT;
    v_student_name   TEXT;
    v_actor_name     TEXT;
    v_student_active BOOLEAN;
BEGIN
    -- Validasi token sesi ke operator_id
    SELECT user_id INTO v_operator_id
    FROM public.user_sessions
    WHERE token_hash = extensions.encode(extensions.digest(p_session_token, 'sha256'), 'hex')
      AND expires_at > NOW();

    IF v_operator_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.');
    END IF;

    -- Role check: hanya super_admin, admin, petugas_keuangan, atau parent yang valid
    IF (SELECT role FROM public.profiles WHERE id = v_operator_id) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND NOT EXISTS (
           SELECT 1 FROM public.parent_students
           WHERE parent_id = v_operator_id AND student_id = p_student_id
       )
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    IF p_amount <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Jumlah top-up harus lebih dari 0');
    END IF;

    SELECT s.balance, COALESCE(p.full_name, 'Siswa'), s.is_active
    INTO v_old_balance, v_student_name, v_student_active
    FROM public.students s
    JOIN public.profiles p ON p.id = s.id
    WHERE s.id = p_student_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak ditemukan');
    END IF;

    IF NOT v_student_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak aktif');
    END IF;

    v_new_balance := v_old_balance + p_amount;

    UPDATE public.students SET balance = v_new_balance WHERE id = p_student_id;

    SELECT COALESCE(full_name, 'Petugas') INTO v_actor_name
    FROM public.profiles WHERE id = v_operator_id;

    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status)
    VALUES (p_student_id, v_operator_id, p_amount, 'topup', 'completed');

    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, old_value, new_value)
    VALUES (
        v_operator_id,
        v_actor_name,
        'TOPUP',
        'Top-up ' || p_method || ' untuk ' || v_student_name || ': Rp' || p_amount::TEXT,
        p_student_id,
        jsonb_build_object('balance', v_old_balance),
        jsonb_build_object('balance', v_new_balance)
    );

    RETURN jsonb_build_object(
        'success', true,
        'old_balance', v_old_balance,
        'new_balance', v_new_balance,
        'amount', p_amount
    );
END;
$$;


-- 7. RECREATE process_correction dengan validasi token sesi SHA-256
CREATE OR REPLACE FUNCTION public.process_correction(
    p_student_id UUID,
    p_new_balance BIGINT,
    p_session_token TEXT,
    p_reason TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_operator_id    UUID;
    v_old_balance    BIGINT;
    v_difference     BIGINT;
    v_student_name   TEXT;
    v_actor_name     TEXT;
BEGIN
    -- Validasi token sesi ke operator_id
    SELECT user_id INTO v_operator_id
    FROM public.user_sessions
    WHERE token_hash = extensions.encode(extensions.digest(p_session_token, 'sha256'), 'hex')
      AND expires_at > NOW();

    IF v_operator_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.');
    END IF;

    -- Role check: hanya super_admin, admin, atau petugas_keuangan
    IF (SELECT role FROM public.profiles WHERE id = v_operator_id) NOT IN ('super_admin', 'admin', 'petugas_keuangan') THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    SELECT balance, COALESCE(full_name, 'Siswa') INTO v_old_balance, v_student_name
    FROM public.students s
    JOIN public.profiles p ON p.id = s.id
    WHERE s.id = p_student_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak ditemukan');
    END IF;

    v_difference := p_new_balance - v_old_balance;

    UPDATE public.students SET balance = p_new_balance WHERE id = p_student_id;

    SELECT COALESCE(full_name, 'Petugas') INTO v_actor_name
    FROM public.profiles WHERE id = v_operator_id;

    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, old_value, new_value)
    VALUES (
        v_operator_id,
        v_actor_name,
        'KOREKSI_SALDO',
        'Koreksi saldo ' || v_student_name || ': ' || COALESCE(p_reason, ''),
        p_student_id,
        jsonb_build_object('balance', v_old_balance),
        jsonb_build_object('balance', p_new_balance)
    );

    RETURN jsonb_build_object(
        'success', true,
        'old_balance', v_old_balance,
        'new_balance', p_new_balance,
        'difference', v_difference
    );
END;
$$;


-- 8. GRANT permissions secara eksplisit ke role authenticated, anon, dan public
GRANT EXECUTE ON FUNCTION public.process_purchase(TEXT, TEXT, JSONB, BIGINT) TO authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.process_refund(UUID, TEXT, TEXT) TO authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.process_topup(UUID, BIGINT, TEXT, TEXT, TEXT) TO authenticated, anon, public;
GRANT EXECUTE ON FUNCTION public.process_correction(UUID, BIGINT, TEXT, TEXT) TO authenticated, anon, public;
