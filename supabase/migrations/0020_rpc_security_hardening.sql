-- =====================================================================
-- Migration 0020: RPC Security Hardening
-- Tanggal: 2026-06-20
-- Tujuan:
--   1. update_auth_user_password — role verification + extensions. prefix
--   2. process_topup — FOR UPDATE locking, negative amount guard, role check, is_active
--   3. process_correction — role check (keuangan/admin only)
--   4. process_purchase — operator role check (canteen_operator)
--   5. process_refund — row locking on student balance
--   6. is_active checks on purchase + topup
--   7. GRANT EXECUTE restrictions
--   8. Fix missing extensions. prefix on crypt()/gen_salt() calls
-- =====================================================================

-- =====================================================================
-- 1. DROP ALL AFFECTED FUNCTIONS WITH CASCADE
-- =====================================================================

DROP FUNCTION IF EXISTS public.update_auth_user_password(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.process_topup(UUID, BIGINT, UUID, TEXT, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.process_correction(UUID, BIGINT, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.process_purchase(TEXT, UUID, JSONB, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS public.process_refund(UUID, UUID, TEXT) CASCADE;

-- =====================================================================
-- 2. RECREATE update_auth_user_password — role verification + extensions.
-- =====================================================================

CREATE OR REPLACE FUNCTION public.update_auth_user_password(
    p_user_id UUID,
    p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_caller_role TEXT;
BEGIN
    -- Role check: only service_role, super_admin, admin, petugas_keuangan,
    -- or the user themself can change the password
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = auth.uid()) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND auth.uid() != p_user_id
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Update password in auth schema dengan extensions. prefix
    UPDATE auth.users
    SET encrypted_password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'User tidak ditemukan di auth.users');
    END IF;

    -- Juga update password di profiles (untuk fallback verify_password)
    UPDATE public.profiles
    SET password = extensions.crypt(p_new_password, extensions.gen_salt('bf'))
    WHERE id = p_user_id;

    RETURN jsonb_build_object('success', true);
END;
$$;

-- =====================================================================
-- 3. RECREATE process_topup — FOR UPDATE, negative guard, role check, is_active
-- =====================================================================

CREATE OR REPLACE FUNCTION public.process_topup(
    p_student_id UUID,
    p_amount BIGINT,
    p_operator_id UUID,
    p_method TEXT DEFAULT 'tunai',
    p_notes TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_old_balance BIGINT;
    v_new_balance BIGINT;
    v_student_name TEXT;
    v_actor_name TEXT;
    v_student_active BOOLEAN;
BEGIN
    -- Role check: hanya super_admin, admin, petugas_keuangan, atau parent
    -- dari siswa yang bersangkutan
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = auth.uid()) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND NOT EXISTS (
           SELECT 1 FROM public.parent_students
           WHERE parent_id = auth.uid() AND student_id = p_student_id
       )
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Validasi: amount harus positif
    IF p_amount <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Jumlah top-up harus lebih dari 0');
    END IF;

    -- Ambil saldo lama dan status aktif siswa dengan FOR UPDATE (row lock)
    SELECT s.balance, COALESCE(p.full_name, 'Siswa'), s.is_active
    INTO v_old_balance, v_student_name, v_student_active
    FROM public.students s
    JOIN public.profiles p ON p.id = s.id
    WHERE s.id = p_student_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak ditemukan');
    END IF;

    -- Validasi: siswa harus aktif
    IF NOT v_student_active THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak aktif');
    END IF;

    -- Hitung saldo baru
    v_new_balance := v_old_balance + p_amount;

    -- Update balance (atomic)
    UPDATE public.students
    SET balance = v_new_balance
    WHERE id = p_student_id;

    -- Dapatkan nama operator
    SELECT COALESCE(full_name, 'Petugas') INTO v_actor_name
    FROM public.profiles WHERE id = p_operator_id;

    -- Insert ke transactions
    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status)
    VALUES (p_student_id, p_operator_id, p_amount, 'topup', 'completed');

    -- Insert audit log
    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, old_value, new_value)
    VALUES (
        p_operator_id,
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

-- =====================================================================
-- 4. RECREATE process_correction — role check (keuangan/admin only)
-- =====================================================================

CREATE OR REPLACE FUNCTION public.process_correction(
    p_student_id UUID,
    p_new_balance BIGINT,
    p_operator_id UUID,
    p_reason TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_old_balance BIGINT;
    v_difference BIGINT;
    v_student_name TEXT;
    v_actor_name TEXT;
BEGIN
    -- Role check: hanya super_admin, admin, atau petugas_keuangan
    IF auth.role() != 'service_role'
       AND (SELECT role FROM public.profiles WHERE id = auth.uid()) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- Ambil saldo lama
    SELECT balance, COALESCE(full_name, 'Siswa') INTO v_old_balance, v_student_name
    FROM public.students s
    JOIN public.profiles p ON p.id = s.id
    WHERE s.id = p_student_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak ditemukan');
    END IF;

    v_difference := p_new_balance - v_old_balance;

    -- Update balance (atomic)
    UPDATE public.students
    SET balance = p_new_balance
    WHERE id = p_student_id;

    -- Dapatkan nama operator
    SELECT COALESCE(full_name, 'Petugas') INTO v_actor_name
    FROM public.profiles WHERE id = p_operator_id;

    -- Insert audit log
    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, old_value, new_value)
    VALUES (
        p_operator_id,
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

-- =====================================================================
-- 5. RECREATE process_purchase — operator role check (canteen_operator)
-- =====================================================================

CREATE OR REPLACE FUNCTION public.process_purchase(
    p_rfid_uid TEXT,
    p_operator_id UUID,
    p_items JSONB,
    p_total_amount BIGINT
)
RETURNS JSONB AS $$
DECLARE
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
    -- Role check: caller harus terdaftar sebagai canteen_operator
    IF auth.role() != 'service_role'
       AND NOT EXISTS (SELECT 1 FROM public.canteen_operators WHERE id = auth.uid())
    THEN
        RAISE EXCEPTION 'Unauthorized: Hanya operator kantin yang dapat melakukan transaksi pembelian';
    END IF;

    -- Awal hari ini dalam WIB (UTC+7)
    v_today_start := date_trunc('day', NOW() AT TIME ZONE v_tz) AT TIME ZONE v_tz;

    -- 1. Kunci baris siswa berdasarkan RFID UID (FOR UPDATE mencegah double spend)
    SELECT s.id, p.full_name, s.balance, s.is_active, s.daily_limit
    INTO v_student_id, v_student_name, v_student_balance, v_student_active, v_daily_limit
    FROM public.students s
    JOIN public.profiles p ON s.id = p.id
    WHERE s.rfid_uid = p_rfid_uid
    FOR UPDATE;

    -- Validasi: siswa ditemukan
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Kartu siswa tidak terdaftar di sistem';
    END IF;

    -- Validasi: kartu aktif
    IF NOT v_student_active THEN
        RAISE EXCEPTION 'Kartu siswa diblokir atau dinonaktifkan';
    END IF;

    -- Validasi: saldo mencukupi
    IF v_student_balance < p_total_amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk melakukan transaksi. Saldo: Rp %, Tagihan: Rp %',
            to_char(v_student_balance, 'FM999,999,999'),
            to_char(p_total_amount, 'FM999,999,999');
    END IF;

    -- Validasi: batas jajan harian (jika daily_limit > 0)
    IF v_daily_limit > 0 THEN
        SELECT COALESCE(SUM(total_amount), 0)
        INTO v_today_spending
        FROM public.transactions
        WHERE student_id = v_student_id
          AND type = 'purchase'
          AND status = 'success'
          AND created_at >= v_today_start;

        IF (v_today_spending + p_total_amount) > v_daily_limit THEN
            RAISE EXCEPTION 'Batas jajan harian terlampaui. Limit: Rp %, Terpakai: Rp %, Sisa: Rp %',
                to_char(v_daily_limit, 'FM999,999,999'),
                to_char(v_today_spending, 'FM999,999,999'),
                to_char(GREATEST(0, v_daily_limit - v_today_spending), 'FM999,999,999');
        END IF;
    END IF;

    -- Ambil nama stan kantin
    SELECT canteen_name INTO v_canteen_name
    FROM public.canteen_operators
    WHERE id = p_operator_id;

    -- 2. Kurangi Saldo Siswa
    UPDATE public.students
    SET balance = balance - p_total_amount
    WHERE id = v_student_id;

    -- 3. Tambah Saldo Operator Kantin
    UPDATE public.canteen_operators
    SET balance_earned = balance_earned + p_total_amount
    WHERE id = p_operator_id;

    -- 4. Catat Transaksi Utama
    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status)
    VALUES (v_student_id, p_operator_id, p_total_amount, 'purchase', 'success')
    RETURNING id INTO v_transaction_id;

    -- 5. Catat Rincian Item Transaksi
    FOR v_item IN
        SELECT * FROM jsonb_to_recordset(p_items)
        AS x(product_id UUID, quantity INT, unit_price NUMERIC, custom_notes TEXT)
    LOOP
        INSERT INTO public.transaction_items (transaction_id, product_id, quantity, unit_price, custom_notes)
        VALUES (v_transaction_id, v_item.product_id, v_item.quantity, v_item.unit_price, v_item.custom_notes);
    END LOOP;

    -- 6. Notifikasi Belanja Sukses
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

-- =====================================================================
-- 6. RECREATE process_refund — row locking on student balance + operator role check
-- =====================================================================

CREATE OR REPLACE FUNCTION public.process_refund(
    p_transaction_id UUID,
    p_operator_id UUID,
    p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_student_id UUID;
    v_total_amount BIGINT;
    v_transaction_status TEXT;
    v_transaction_type TEXT;
    v_transaction_operator UUID;
    v_created_at TIMESTAMP WITH TIME ZONE;
    v_canteen_name TEXT;
    v_caller_role TEXT;
BEGIN
    -- Role check: caller harus terdaftar sebagai canteen_operator
    IF auth.role() != 'service_role'
       AND NOT EXISTS (SELECT 1 FROM public.canteen_operators WHERE id = auth.uid())
    THEN
        RAISE EXCEPTION 'Unauthorized: Hanya operator kantin yang dapat melakukan refund';
    END IF;

    -- 1. Ambil data transaksi dengan kunci baris
    SELECT student_id, operator_id, total_amount::BIGINT, status, type, created_at
    INTO v_student_id, v_transaction_operator, v_total_amount, v_transaction_status, v_transaction_type, v_created_at
    FROM public.transactions
    WHERE id = p_transaction_id
    FOR UPDATE;

    -- Validasi keberadaan transaksi
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'ID Transaksi tidak ditemukan';
    END IF;

    -- Validasi hak milik operator
    IF v_transaction_operator <> p_operator_id THEN
        RAISE EXCEPTION 'Akses ditolak: Transaksi ini bukan milik stan kantin Anda';
    END IF;

    -- Validasi status transaksi
    IF v_transaction_status <> 'success' THEN
        RAISE EXCEPTION 'Transaksi tidak dapat di-refund karena status saat ini: %', v_transaction_status;
    END IF;

    -- Validasi tipe transaksi
    IF v_transaction_type <> 'purchase' THEN
        RAISE EXCEPTION 'Hanya transaksi pembelian belanja yang dapat dibatalkan/di-refund';
    END IF;

    -- Validasi batas waktu 10 menit
    IF v_created_at < now() - INTERVAL '10 minutes' THEN
        RAISE EXCEPTION 'Batas waktu pembatalan/refund telah berakhir (maksimal 10 menit)';
    END IF;

    -- Ambil nama stan kantin
    SELECT canteen_name INTO v_canteen_name
    FROM public.canteen_operators
    WHERE id = p_operator_id;

    -- 2. Kunci baris saldo siswa (FOR UPDATE mencegah race condition)
    PERFORM balance
    FROM public.students
    WHERE id = v_student_id
    FOR UPDATE;

    -- 3. Mengubah status transaksi menjadi cancelled
    UPDATE public.transactions
    SET status = 'cancelled'
    WHERE id = p_transaction_id;

    -- 4. Kembalikan saldo ke dompet siswa (BIGINT arithmetic)
    UPDATE public.students
    SET balance = balance + v_total_amount
    WHERE id = v_student_id;

    -- 5. Potong pendapatan saldo operator kantin (BIGINT arithmetic)
    UPDATE public.canteen_operators
    SET balance_earned = balance_earned - v_total_amount
    WHERE id = p_operator_id;

    -- 6. Catat riwayat audit pembatalan di notifications
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

-- =====================================================================
-- 7. GRANT EXECUTE RESTRICTIONS
-- =====================================================================

-- Cabut akses dari anon dan public untuk RPC keuangan transaksional
REVOKE EXECUTE ON FUNCTION public.process_purchase FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.process_topup FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.process_correction FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.process_refund FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.update_auth_user_password FROM anon, public;

-- Cabut akses create_user_account dari anon (hanya admin melalui dashboard)
REVOKE EXECUTE ON FUNCTION public.create_user_account(p_email TEXT, p_password TEXT, p_full_name TEXT, p_role TEXT, p_nisn TEXT, p_class TEXT, p_canteen_name TEXT, p_phone_number TEXT, p_parent_role TEXT, p_relation TEXT) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.create_user_account(p_email TEXT, p_password TEXT, p_full_name TEXT, p_role TEXT, p_phone_number TEXT, p_username TEXT, p_nisn TEXT, p_class TEXT, p_canteen_name TEXT, p_relation TEXT, p_is_active BOOLEAN, p_rfid_uid TEXT, p_parent_phone TEXT) FROM anon, public;

-- Berikan akses ke authenticated users untuk semua RPC yang dibutuhkan
GRANT EXECUTE ON FUNCTION public.process_purchase TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_topup TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_correction TO authenticated;
GRANT EXECUTE ON FUNCTION public.process_refund TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_auth_user_password TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_account(p_email TEXT, p_password TEXT, p_full_name TEXT, p_role TEXT, p_nisn TEXT, p_class TEXT, p_canteen_name TEXT, p_phone_number TEXT, p_parent_role TEXT, p_relation TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_account(p_email TEXT, p_password TEXT, p_full_name TEXT, p_role TEXT, p_phone_number TEXT, p_username TEXT, p_nisn TEXT, p_class TEXT, p_canteen_name TEXT, p_relation TEXT, p_is_active BOOLEAN, p_rfid_uid TEXT, p_parent_phone TEXT) TO authenticated;

-- verify_password tetap bisa diakses oleh anon/public untuk fallback auth
GRANT EXECUTE ON FUNCTION public.verify_password TO anon, public;

-- get_student_by_nisn tetap bisa diakses anon untuk parent portal search
GRANT EXECUTE ON FUNCTION public.get_student_by_nisn TO anon, public;

-- =====================================================================
-- 8. VERIFIKASI HASIL
-- =====================================================================

-- Catatan: jalankan query berikut untuk verifikasi:
-- SELECT proname, proargtypes::regtype[] AS arg_types,
--        pg_get_functiondef(p.oid) AS func_def
-- FROM pg_proc p
-- JOIN pg_namespace n ON n.oid = p.pronamespace
-- WHERE n.nspname = 'public'
--   AND proname IN ('process_purchase','process_topup','process_correction',
--                   'process_refund','update_auth_user_password')
-- ORDER BY proname;
