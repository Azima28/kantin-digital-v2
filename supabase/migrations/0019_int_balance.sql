-- Migration 0019: Convert balance columns from NUMERIC(12,2) to BIGINT
-- All existing balance values are whole numbers (Rupiah without decimals)
-- RPC functions that use NUMERIC for balance params/vars are updated to BIGINT

-- =====================================================================
-- 1. ALTER TABLE columns
-- =====================================================================

ALTER TABLE public.students
  ALTER COLUMN balance TYPE BIGINT;

ALTER TABLE public.canteen_operators
  ALTER COLUMN balance_earned TYPE BIGINT;

-- =====================================================================
-- 2. DROP affected RPC functions
--    Signatures change (NUMERIC → BIGINT), so we must DROP before CREATE
-- =====================================================================

DROP FUNCTION IF EXISTS public.process_topup(UUID, NUMERIC, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.process_correction(UUID, NUMERIC, UUID, TEXT);
DROP FUNCTION IF EXISTS public.process_purchase(TEXT, UUID, JSONB, NUMERIC);
DROP FUNCTION IF EXISTS public.process_refund(UUID, UUID, TEXT);

-- =====================================================================
-- 3. process_topup — all NUMERIC balance params/vars → BIGINT
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
BEGIN
    -- Ambil saldo lama
    SELECT balance, COALESCE(full_name, 'Siswa') INTO v_old_balance, v_student_name
    FROM public.students s
    JOIN public.profiles p ON p.id = s.id
    WHERE s.id = p_student_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Siswa tidak ditemukan');
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
-- 4. process_correction — all NUMERIC balance params/vars → BIGINT
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
-- 5. process_purchase — BIGINT for balance-related types
--    (latest version from 20260619000100_add_daily_limit_validation.sql)
--    - p_total_amount: NUMERIC → BIGINT (so BIGINT arithmetic works with balance)
--    - v_student_balance: NUMERIC → BIGINT
--    - v_daily_limit, v_today_spending: remain NUMERIC (spending limits, not balances)
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================================
-- 6. process_refund — BIGINT for balance arithmetic
--    v_total_amount changes from NUMERIC to BIGINT (cast from
--    transactions.total_amount which remains NUMERIC)
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
BEGIN
    -- 1. Mengambil data transaksi dengan kunci baris
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

    -- 2. Mengubah status transaksi menjadi cancelled
    UPDATE public.transactions
    SET status = 'cancelled'
    WHERE id = p_transaction_id;

    -- 3. Kembalikan saldo ke dompet siswa (BIGINT arithmetic)
    UPDATE public.students
    SET balance = balance + v_total_amount
    WHERE id = v_student_id;

    -- 4. Potong pendapatan saldo operator kantin (BIGINT arithmetic)
    UPDATE public.canteen_operators
    SET balance_earned = balance_earned - v_total_amount
    WHERE id = p_operator_id;

    -- 5. Catat riwayat audit pembatalan di notifications
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
