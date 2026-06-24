-- Migration: Fix process_topup foreign key constraint and add student self-topup permission
-- Tanggal: 2026-06-24

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

    -- 7. Catat transaksi pembayaran & audit log (actor_id merekam pengguna yang sesungguhnya)
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
