-- Migrasi: RPC untuk topup dan koreksi saldo (menggantikan direct .update())
-- Alasan: Atomic operation + audit log + cegah race condition

-- =================================================================
-- RPC: process_topup
-- =================================================================
CREATE OR REPLACE FUNCTION public.process_topup(
    p_student_id UUID,
    p_amount NUMERIC(12,2),
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
    v_old_balance NUMERIC(12,2);
    v_new_balance NUMERIC(12,2);
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

-- =================================================================
-- RPC: process_correction
-- =================================================================
CREATE OR REPLACE FUNCTION public.process_correction(
    p_student_id UUID,
    p_new_balance NUMERIC(12,2),
    p_operator_id UUID,
    p_reason TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public'
AS $$
DECLARE
    v_old_balance NUMERIC(12,2);
    v_difference NUMERIC(12,2);
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
