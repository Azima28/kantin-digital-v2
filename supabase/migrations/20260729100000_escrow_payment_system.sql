-- Migration: Add Escrow Payment & Balance Holding System
-- Purpose: Deduct student balance upon ordering, hold funds in escrow, release to canteen on 'Selesai', and refund on 'Dibatalkan'.

-- 1. RPC: process_online_order_escrow
CREATE OR REPLACE FUNCTION public.process_online_order_escrow(
    p_student_id UUID,
    p_operator_id UUID,
    p_total_amount BIGINT,
    p_delivery_location TEXT DEFAULT '',
    p_items JSONB DEFAULT '[]'::JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_student_name    TEXT;
    v_student_balance BIGINT;
    v_student_active  BOOLEAN;
    v_daily_limit     NUMERIC;
    v_today_spending  NUMERIC;
    v_order_id        UUID;
    v_transaction_id  UUID;
    v_item            RECORD;
    v_tz              TEXT := 'Asia/Jakarta';
    v_today_start     TIMESTAMP WITH TIME ZONE;
BEGIN
    v_today_start := date_trunc('day', NOW() AT TIME ZONE v_tz) AT TIME ZONE v_tz;

    -- 1. Lock student row FOR UPDATE to prevent race conditions
    SELECT s.balance, s.is_active, s.daily_limit, p.full_name
    INTO v_student_balance, v_student_active, v_daily_limit, v_student_name
    FROM public.students s
    JOIN public.profiles p ON s.id = p.id
    WHERE s.id = p_student_id
    FOR UPDATE;

    IF v_student_balance IS NULL THEN
        RAISE EXCEPTION 'Data akun siswa tidak ditemukan di sistem.';
    END IF;

    IF NOT COALESCE(v_student_active, TRUE) THEN
        RAISE EXCEPTION 'Akun/Kartu siswa dalam status dibekukan.';
    END IF;

    IF v_student_balance < p_total_amount THEN
        RAISE EXCEPTION 'Saldo Anda tidak mencukupi untuk melakukan pemesanan ini.';
    END IF;

    -- 2. Validate daily limit if configured
    IF COALESCE(v_daily_limit, 0) > 0 THEN
        SELECT COALESCE(SUM(total_amount), 0)
        INTO v_today_spending
        FROM public.transactions
        WHERE student_id = p_student_id
          AND type = 'purchase'
          AND status IN ('success', 'pending_escrow')
          AND created_at >= v_today_start;

        IF (v_today_spending + p_total_amount) > v_daily_limit THEN
            RAISE EXCEPTION 'Transaksi melebihi batasan pengeluaran harian siswa.';
        END IF;
    END IF;

    -- 3. Deduct student balance (Hold in Escrow — DO NOT credit canteen operator yet!)
    UPDATE public.students
    SET balance = balance - p_total_amount
    WHERE id = p_student_id;

    -- 4. Create order record
    INSERT INTO public.orders (
        student_id,
        operator_id,
        student_name,
        total_amount,
        status,
        delivery_location
    ) VALUES (
        p_student_id,
        p_operator_id,
        COALESCE(v_student_name, 'Siswa'),
        p_total_amount,
        'Baru',
        p_delivery_location
    ) RETURNING id INTO v_order_id;

    -- 5. Insert order items
    IF jsonb_array_length(p_items) > 0 THEN
        FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(
            product_name TEXT,
            quantity INT,
            price NUMERIC,
            selected_options TEXT
        ) LOOP
            INSERT INTO public.order_items (
                order_id,
                product_name,
                quantity,
                price,
                selected_options
            ) VALUES (
                v_order_id,
                v_item.product_name,
                v_item.quantity,
                v_item.price,
                v_item.selected_options
            );
        END LOOP;
    END IF;

    -- 6. Insert transaction with status 'pending_escrow'
    INSERT INTO public.transactions (
        student_id,
        operator_id,
        total_amount,
        type,
        status
    ) VALUES (
        p_student_id,
        p_operator_id,
        p_total_amount,
        'purchase',
        'pending_escrow'
    ) RETURNING id INTO v_transaction_id;

    -- 7. Notification for student
    INSERT INTO public.notifications (student_id, title, message, type, is_read)
    VALUES (
        p_student_id,
        'Pesanan Berhasil! 🛒',
        'Pesanan Anda senilai Rp ' || to_char(p_total_amount, 'FM999,999,999') || ' telah dikirim ke kantin. Saldo ditahan sementara oleh sistem sampai pesanan selesai.',
        'purchase',
        FALSE
    );

    RETURN jsonb_build_object(
        'order_id', v_order_id,
        'transaction_id', v_transaction_id,
        'remaining_balance', v_student_balance - p_total_amount,
        'status', 'success'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

GRANT EXECUTE ON FUNCTION public.process_online_order_escrow TO authenticated, anon, public;


-- 2. RPC: complete_order_release_escrow
CREATE OR REPLACE FUNCTION public.complete_order_release_escrow(
    p_order_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_student_id    UUID;
    v_operator_id   UUID;
    v_total_amount  BIGINT;
    v_status        TEXT;
BEGIN
    -- Lock order row
    SELECT student_id, operator_id, total_amount, status
    INTO v_student_id, v_operator_id, v_total_amount, v_status
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan tidak ditemukan.';
    END IF;

    IF v_status = 'Selesai' THEN
        RETURN; -- Already completed
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
    WHERE id = (
        SELECT id FROM public.transactions
        WHERE student_id = v_student_id
          AND operator_id = v_operator_id
          AND total_amount = v_total_amount
          AND type = 'purchase'
          AND status IN ('pending_escrow', 'pending')
        ORDER BY created_at DESC
        LIMIT 1
    );

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

GRANT EXECUTE ON FUNCTION public.complete_order_release_escrow TO authenticated, anon, public;


-- 3. Update cancel_order RPC (Refund student balance 100%, deduct operator only if previously 'Selesai')
CREATE OR REPLACE FUNCTION public.cancel_order(
    p_order_id UUID,
    p_reason TEXT DEFAULT 'Dibatalkan'
)
RETURNS VOID AS $$
DECLARE
    v_student_id     UUID;
    v_total_amount   BIGINT;
    v_operator_id    UUID;
    v_student_name   TEXT;
    v_item_summary   TEXT;
    v_current_status TEXT;
BEGIN
    SELECT student_id, total_amount, operator_id, student_name, status
    INTO v_student_id, v_total_amount, v_operator_id, v_student_name, v_current_status
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan tidak ditemukan.';
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

    -- 3. Only deduct operator balance_earned IF the order was previously 'Selesai'
    IF v_current_status = 'Selesai' THEN
        UPDATE public.canteen_operators
        SET balance_earned = GREATEST(0, balance_earned - v_total_amount)
        WHERE id = v_operator_id;
    END IF;

    -- 4. Mark transaction as cancelled
    UPDATE public.transactions
    SET status = 'cancelled'
    WHERE id = (
        SELECT id FROM public.transactions
        WHERE student_id = v_student_id
          AND operator_id = v_operator_id
          AND total_amount = v_total_amount
          AND type = 'purchase'
        ORDER BY created_at DESC
        LIMIT 1
    );

    -- 5. Build summary and notification
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

    -- 6. Audit Log
    INSERT INTO public.audit_logs (actor_id, actor_name, action_type, description, target_id, new_value)
    VALUES (
        v_student_id,
        v_student_name,
        'BATAL_PESANAN',
        'Pesanan ' || p_order_id || ' dibatalkan. Saldo Rp ' || v_total_amount || ' dikembalikan ke siswa.',
        p_order_id,
        jsonb_build_object('status', 'Dibatalkan', 'refund_amount', v_total_amount)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = 'public';

GRANT EXECUTE ON FUNCTION public.cancel_order TO authenticated, anon, public;
