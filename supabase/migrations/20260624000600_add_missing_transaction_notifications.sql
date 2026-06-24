-- Database Migration: Add Missing Notifications for Top-Up and Balance Corrections
-- Tanggal: 2026-06-24

-- 1. RECREATE process_topup untuk memancarkan notifikasi top-up
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
    v_operator_id      UUID;
    v_old_balance      BIGINT;
    v_new_balance      BIGINT;
    v_student_name     TEXT;
    v_actor_name       TEXT;
    v_student_active   BOOLEAN;
    v_real_operator_id UUID;
BEGIN
    -- 1. Validasi token sesi ke operator_id (actor)
    SELECT user_id INTO v_operator_id
    FROM public.user_sessions
    WHERE token_hash = extensions.encode(extensions.digest(p_session_token, 'sha256'), 'hex')
      AND expires_at > NOW();

    IF v_operator_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.');
    END IF;

    -- 2. Role check: super_admin, admin, petugas_keuangan, parent yang terhubung ke siswa, atau siswa itu sendiri (untuk simulasi)
    IF (SELECT role FROM public.profiles WHERE id = v_operator_id) NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND NOT EXISTS (
           SELECT 1 FROM public.parent_students
           WHERE parent_id = v_operator_id AND student_id = p_student_id
       )
       AND v_operator_id <> p_student_id
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized');
    END IF;

    -- 3. Validasi nominal positif
    IF p_amount <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Jumlah top-up harus lebih dari 0');
    END IF;

    -- 4. Kunci baris saldo siswa dengan FOR UPDATE
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

    -- 5. Lakukan penambahan saldo
    v_new_balance := v_old_balance + p_amount;
    UPDATE public.students SET balance = v_new_balance WHERE id = p_student_id;

    -- 6. Cari ID operator kantin valid untuk kepatuhan Foreign Key pada tabel transactions
    SELECT id INTO v_real_operator_id
    FROM public.canteen_operators
    LIMIT 1;

    IF v_real_operator_id IS NULL THEN
        RETURN jsonb_build_object('success', false, 'error', 'Tidak ada stan kantin terdaftar untuk mencatat transaksi');
    END IF;

    SELECT COALESCE(full_name, 'Petugas') INTO v_actor_name
    FROM public.profiles WHERE id = v_operator_id;

    -- 7. Catat transaksi pembayaran & audit log
    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status)
    VALUES (p_student_id, v_real_operator_id, p_amount, 'topup', 'completed');

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

    -- 8. Kirim Notifikasi Top-Up Sukses ke Siswa
    INSERT INTO public.notifications (user_id, student_id, title, message, type)
    VALUES (
        p_student_id,
        p_student_id,
        'Top-Up Berhasil!',
        'Top-up saldo sebesar Rp ' || to_char(p_amount, 'FM999,999,999') || ' (' || p_method || ') telah berhasil.',
        'topup'
    );

    RETURN jsonb_build_object(
        'success', true,
        'old_balance', v_old_balance,
        'new_balance', v_new_balance,
        'amount', p_amount
    );
END;
$$;

-- Berikan izin akses eksekusi RPC ke public/anon/authenticated
GRANT EXECUTE ON FUNCTION public.process_topup(UUID, BIGINT, TEXT, TEXT, TEXT) TO authenticated, anon, public;


-- 2. RECREATE process_correction untuk memancarkan notifikasi koreksi saldo
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

    -- Kirim Notifikasi Koreksi Saldo ke Siswa
    INSERT INTO public.notifications (user_id, student_id, title, message, type)
    VALUES (
        p_student_id,
        p_student_id,
        'Penyesuaian Saldo',
        'Saldo Anda telah disesuaikan menjadi Rp ' || to_char(p_new_balance, 'FM999,999,999') || '. Alasan: ' || COALESCE(p_reason, 'Koreksi sistem oleh admin.'),
        'system'
    );

    RETURN jsonb_build_object(
        'success', true,
        'old_balance', v_old_balance,
        'new_balance', p_new_balance,
        'difference', v_difference
    );
END;
$$;

-- Berikan izin akses eksekusi RPC ke public/anon/authenticated
GRANT EXECUTE ON FUNCTION public.process_correction(UUID, BIGINT, TEXT, TEXT) TO authenticated, anon, public;
