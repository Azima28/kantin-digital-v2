-- Migration: Add cancel_order RPC function
-- Tujuan: Mengizinkan pembatalan pesanan secara transaksional (atomic) yang memotong/refund saldo, mengubah status pesanan & transaksi, menulis audit log, serta mengirim notifikasi.

CREATE OR REPLACE FUNCTION public.cancel_order(
    p_order_id UUID,
    p_reason TEXT DEFAULT 'Dibatalkan'
)
RETURNS VOID AS $$
DECLARE
    v_student_id UUID;
    v_total_amount INTEGER;
    v_operator_id UUID;
    v_student_name TEXT;
    v_item_summary TEXT;
    v_current_status TEXT;
BEGIN
    -- 1. Dapatkan detail pesanan & kunci baris pesanan (FOR UPDATE)
    SELECT student_id, total_amount, operator_id, student_name, status
    INTO v_student_id, v_total_amount, v_operator_id, v_student_name, v_current_status
    FROM public.orders
    WHERE id = p_order_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Pesanan dengan ID % tidak ditemukan.', p_order_id;
    END IF;

    -- Proteksi: Pesanan yang sudah selesai atau sudah dibatalkan tidak bisa dibatalkan lagi
    IF v_current_status = 'Selesai' THEN
        RAISE EXCEPTION 'Pesanan sudah selesai diambil/diantar dan tidak dapat dibatalkan.';
    ELSIF v_current_status = 'Dibatalkan' THEN
        RAISE EXCEPTION 'Pesanan ini sudah dibatalkan sebelumnya.';
    END IF;

    -- 2. Ubah status pesanan menjadi Dibatalkan
    UPDATE public.orders
    SET status = 'Dibatalkan'
    WHERE id = p_order_id;

    -- 3. Kembalikan saldo (refund) ke siswa
    UPDATE public.students
    SET balance = balance + v_total_amount
    WHERE id = v_student_id;

    -- 4. Kurangi pendapatan kotor yang diperoleh operator kantin
    UPDATE public.canteen_operators
    SET balance_earned = GREATEST(0, balance_earned - v_total_amount)
    WHERE id = v_operator_id;

    -- 5. Kumpulkan nama barang untuk deskripsi notifikasi
    SELECT string_agg(quantity || 'x ' || product_name, ', ')
    INTO v_item_summary
    FROM public.order_items
    WHERE order_id = p_order_id;

    -- 6. Insert notifikasi untuk siswa
    INSERT INTO public.notifications (student_id, title, message, type, is_read)
    VALUES (
        v_student_id,
        'Pesanan Dibatalkan ❌',
        'Pesanan Anda (' || COALESCE(v_item_summary, '') || ') senilai Rp ' || 
        to_char(v_total_amount, 'FM999,999,999') || ' telah dibatalkan. Alasan: ' || p_reason || '. Saldo dikembalikan.',
        'system',
        FALSE
    );

    -- 7. Catat ke audit log
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
$$ LANGUAGE plpgsql SECURITY DEFINER;
