-- =====================================================================
-- SECURITY HARDENING MIGRATION — 20260818000100
-- 1. Remove p_caller_id spoofing from update_auth_user_password & process_topup
-- 2. Restrict Escrow RPCs to authenticated owner/operator/service_role
-- 3. Revoke public/anon privileges on critical financial functions
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. HARDEN update_auth_user_password
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_auth_user_password(
    p_user_id UUID,
    p_new_password TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_caller_uid UUID;
    v_caller_role TEXT;
    v_target_email TEXT;
    v_encrypted_pw TEXT;
BEGIN
    v_caller_uid := auth.uid();

    -- If caller is authenticated user, check their role
    IF v_caller_uid IS NOT NULL THEN
        SELECT role INTO v_caller_role FROM public.profiles WHERE id = v_caller_uid;
    END IF;

    -- Strict authorization: only service_role, admins, or the user themselves (if authenticated)
    IF auth.role() != 'service_role'
       AND COALESCE(v_caller_role, '') NOT IN ('super_admin', 'admin')
       AND v_caller_uid != p_user_id
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Akses ditolak');
    END IF;

    IF length(p_new_password) < 6 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Kata sandi minimal 6 karakter');
    END IF;

    v_encrypted_pw := extensions.crypt(p_new_password, extensions.gen_salt('bf', 6));

    -- Update public.profiles
    UPDATE public.profiles
    SET password = v_encrypted_pw
    WHERE id = p_user_id;

    -- Update auth.users if exists
    SELECT email INTO v_target_email FROM auth.users WHERE id = p_user_id;
    IF v_target_email IS NOT NULL THEN
        UPDATE auth.users
        SET encrypted_password = v_encrypted_pw,
            updated_at = NOW()
        WHERE id = p_user_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'message', 'Kata sandi berhasil diperbarui');
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE EXECUTE ON FUNCTION public.update_auth_user_password(UUID, TEXT) FROM anon, public;
        GRANT EXECUTE ON FUNCTION public.update_auth_user_password(UUID, TEXT) TO authenticated, service_role;
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 2. HARDEN process_topup
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_topup(
    p_student_id UUID,
    p_amount BIGINT,
    p_payment_method TEXT DEFAULT 'cash'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_operator_id UUID;
    v_operator_role TEXT;
    v_new_balance BIGINT;
BEGIN
    v_operator_id := auth.uid();

    IF v_operator_id IS NOT NULL THEN
        SELECT role INTO v_operator_role FROM public.profiles WHERE id = v_operator_id;
    END IF;

    -- Require service_role, verified finance officer/admin, or verified parent
    IF auth.role() != 'service_role'
       AND COALESCE(v_operator_role, '') NOT IN ('super_admin', 'admin', 'petugas_keuangan')
       AND NOT EXISTS (
           SELECT 1 FROM public.parent_students
           WHERE parent_id = v_operator_id AND student_id = p_student_id
       )
    THEN
        RETURN jsonb_build_object('success', false, 'error', 'Unauthorized: Top-up hanya dapat dilakukan oleh Petugas Keuangan atau Orang Tua');
    END IF;

    IF p_amount <= 0 THEN
        RETURN jsonb_build_object('success', false, 'error', 'Nominal top-up harus lebih dari 0');
    END IF;

    -- Update balance
    UPDATE public.students
    SET balance = balance + p_amount
    WHERE id = p_student_id
    RETURNING balance INTO v_new_balance;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Data siswa tidak ditemukan');
    END IF;

    -- Record transaction
    INSERT INTO public.transactions (student_id, operator_id, total_amount, type, status, purchase_method)
    VALUES (p_student_id, COALESCE(v_operator_id, p_student_id), p_amount, 'topup', 'success', p_payment_method);

    -- Record notification
    INSERT INTO public.notifications (student_id, title, message, type)
    VALUES (p_student_id, 'Top-Up Saldo Berhasil! 💳', 'Top-up saldo sebesar Rp ' || p_amount || ' berhasil ditambahkan.', 'topup');

    RETURN jsonb_build_object('success', true, 'new_balance', v_new_balance);
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE EXECUTE ON FUNCTION public.process_topup(UUID, BIGINT, TEXT) FROM anon, public;
        GRANT EXECUTE ON FUNCTION public.process_topup(UUID, BIGINT, TEXT) TO authenticated, service_role;
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 3. HARDEN complete_order_release_escrow
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_order_release_escrow(
    p_order_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_caller_id     UUID;
    v_caller_role   TEXT;
    v_student_id    UUID;
    v_operator_id   UUID;
    v_total_amount  BIGINT;
    v_status        TEXT;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NOT NULL THEN
        SELECT role INTO v_caller_role FROM public.profiles WHERE id = v_caller_id;
    END IF;

    -- Lock order row
    SELECT student_id, operator_id, total_amount, status
    INTO v_student_id, v_operator_id, v_total_amount, v_status
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan tidak ditemukan.';
    END IF;

    -- Verify caller is service_role, the assigned operator, or an admin
    IF auth.role() != 'service_role'
       AND COALESCE(v_caller_role, '') NOT IN ('super_admin', 'admin')
       AND v_caller_id != v_operator_id
    THEN
        RAISE EXCEPTION 'Unauthorized: Hanya kasir kantin atau admin yang dapat menyelesaikan pesanan.';
    END IF;

    IF v_status = 'Selesai' THEN
        RETURN; -- Already completed
    END IF;

    IF v_status = 'Dibatalkan' THEN
        RAISE EXCEPTION 'Pesanan yang sudah dibatalkan tidak dapat diselesaikan.';
    END IF;

    -- Update order status to Selesai
    UPDATE public.orders
    SET status = 'Selesai'
    WHERE id = p_order_id;

    -- Release escrow funds to canteen operator
    UPDATE public.canteen_operators
    SET balance_earned = balance_earned + v_total_amount
    WHERE id = v_operator_id;

    -- Update transaction status to 'success'
    UPDATE public.transactions
    SET status = 'success'
    WHERE student_id = v_student_id
      AND operator_id = v_operator_id
      AND total_amount = v_total_amount
      AND type = 'purchase'
      AND status IN ('pending_escrow', 'pending');

    -- Notification for student
    INSERT INTO public.notifications (student_id, title, message, type, is_read)
    VALUES (
        v_student_id,
        'Pesanan Selesai! 🎉',
        'Pesanan Anda telah selesai. Dana sebesar Rp ' || to_char(v_total_amount, 'FM999,999,999') || ' yang ditahan sistem telah diserahkan ke kantin.',
        'system',
        FALSE
    );
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE EXECUTE ON FUNCTION public.complete_order_release_escrow(UUID) FROM anon, public;
        GRANT EXECUTE ON FUNCTION public.complete_order_release_escrow(UUID) TO authenticated, service_role;
    END IF;
END $$;

-- ---------------------------------------------------------------------
-- 4. HARDEN cancel_order
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cancel_order(
    p_order_id UUID,
    p_reason TEXT DEFAULT 'Dibatalkan'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
    v_caller_id      UUID;
    v_caller_role    TEXT;
    v_student_id     UUID;
    v_total_amount   BIGINT;
    v_operator_id    UUID;
    v_student_name   TEXT;
    v_item_summary   TEXT;
    v_current_status TEXT;
BEGIN
    v_caller_id := auth.uid();
    IF v_caller_id IS NOT NULL THEN
        SELECT role INTO v_caller_role FROM public.profiles WHERE id = v_caller_id;
    END IF;

    SELECT student_id, total_amount, operator_id, student_name, status
    INTO v_student_id, v_total_amount, v_operator_id, v_student_name, v_current_status
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan tidak ditemukan.';
    END IF;

    -- Verify caller is service_role, the student owner, the canteen operator, or an admin
    IF auth.role() != 'service_role'
       AND COALESCE(v_caller_role, '') NOT IN ('super_admin', 'admin')
       AND v_caller_id != v_student_id
       AND v_caller_id != v_operator_id
    THEN
        RAISE EXCEPTION 'Unauthorized: Anda tidak memiliki hak untuk membatalkan pesanan ini.';
    END IF;

    IF v_current_status = 'Selesai' THEN
        RAISE EXCEPTION 'Pesanan sudah selesai dan tidak dapat dibatalkan.';
    ELSIF v_current_status = 'Dibatalkan' THEN
        RETURN;
    END IF;

    -- 1. Update status to Dibatalkan
    UPDATE public.orders
    SET status = 'Dibatalkan'
    WHERE id = p_order_id;

    -- 2. Refund 100% student balance
    UPDATE public.students
    SET balance = balance + v_total_amount
    WHERE id = v_student_id;

    -- 3. Mark transaction as cancelled
    UPDATE public.transactions
    SET status = 'cancelled'
    WHERE student_id = v_student_id
      AND operator_id = v_operator_id
      AND total_amount = v_total_amount
      AND type = 'purchase'
      AND status IN ('pending', 'pending_escrow');

    -- 4. Build summary and notification
    SELECT string_agg(quantity || 'x ' || product_name, ', ')
    INTO v_item_summary
    FROM public.order_items
    WHERE order_id = p_order_id;

    INSERT INTO public.notifications (student_id, title, message, type, is_read)
    VALUES (
        v_student_id,
        'Pesanan Dibatalkan ❌',
        'Pesanan Anda (' || COALESCE(v_item_summary, '') || ') senilai Rp ' ||
        to_char(v_total_amount, 'FM999,999,999') || ' telah dibatalkan. Alasan: ' || p_reason || '. Saldo telah dikembalikan ke akun Anda.',
        'system',
        FALSE
    );

    -- 5. Audit Log
    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, new_value)
    VALUES (
        COALESCE(v_caller_id, v_student_id),
        COALESCE(v_student_name, 'System'),
        'BATAL_PESANAN',
        'Pesanan ' || p_order_id || ' dibatalkan. Saldo Rp ' || v_total_amount || ' dikembalikan ke siswa.',
        p_order_id,
        jsonb_build_object('status', 'Dibatalkan', 'refund_amount', v_total_amount, 'reason', p_reason)
    );
END;
$$;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE EXECUTE ON FUNCTION public.cancel_order(UUID, TEXT) FROM anon, public;
        GRANT EXECUTE ON FUNCTION public.cancel_order(UUID, TEXT) TO authenticated, service_role;
    END IF;
END $$;
