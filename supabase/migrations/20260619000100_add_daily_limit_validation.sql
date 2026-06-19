-- =====================================================================
-- Migration: Validasi Daily Limit di Stored Procedure process_purchase
-- Tanggal: 2026-06-19
-- Tujuan: Memindahkan validasi daily_limit dari Flutter ke database
--         agar tidak bisa di-bypass melalui request langsung ke Supabase.
-- =====================================================================

-- Pastikan kolom daily_limit ada di tabel students
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS daily_limit NUMERIC(12, 2) DEFAULT 0.00 NOT NULL;

-- Recreate process_purchase dengan validasi daily_limit di DB
CREATE OR REPLACE FUNCTION public.process_purchase(
    p_rfid_uid TEXT,
    p_operator_id UUID,
    p_items JSONB,
    p_total_amount NUMERIC
)
RETURNS JSONB AS $$
DECLARE
    v_student_id      UUID;
    v_student_name    TEXT;
    v_student_balance NUMERIC;
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

-- Tambah komentar pada kolom daily_limit
COMMENT ON COLUMN public.students.daily_limit IS
    'Batas maksimal pengeluaran per hari dalam Rupiah. 0 berarti tidak ada batas.';
