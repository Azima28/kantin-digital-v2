-- Migrasi Fitur Orang Tua Mobile & Integrasi Pengecekan Limit Jajan POS

-- 1. Menambahkan kolom-kolom baru ke tabel public.students
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS daily_limit NUMERIC(12, 2) DEFAULT NULL CHECK (daily_limit IS NULL OR daily_limit >= 0),
ADD COLUMN IF NOT EXISTS wa_notifications_enabled BOOLEAN DEFAULT true NOT NULL,
ADD COLUMN IF NOT EXISTS parent_phone TEXT DEFAULT NULL;

-- 2. Memperbarui constraint check kategori produk pada tabel public.products
-- Hapus constraint lama jika ada
ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_category_check;
-- Tambah constraint baru yang mengizinkan 'camilan'
ALTER TABLE public.products ADD CONSTRAINT products_category_check CHECK (category IN ('makanan', 'minuman', 'camilan'));

-- 3. Memperbarui fungsi PL/pgSQL process_purchase untuk menyertakan validasi limit jajan harian
CREATE OR REPLACE FUNCTION public.process_purchase(
    p_rfid_uid TEXT,
    p_operator_id UUID,
    p_items JSONB, -- Array berisi object: product_id, quantity, unit_price, custom_notes
    p_total_amount NUMERIC
)
RETURNS JSONB AS $$
DECLARE
    v_student_id UUID;
    v_student_name TEXT;
    v_student_balance NUMERIC;
    v_student_active BOOLEAN;
    v_daily_limit NUMERIC;
    v_today_spending NUMERIC;
    v_transaction_id UUID;
    v_item RECORD;
    v_canteen_name TEXT;
BEGIN
    -- 1. Mengunci baris siswa berdasarkan RFID UID untuk menghindari Double Spend & race conditions
    SELECT s.id, p.full_name, s.balance, s.is_active, s.daily_limit
    INTO v_student_id, v_student_name, v_student_balance, v_student_active, v_daily_limit
    FROM public.students s
    JOIN public.profiles p ON s.id = p.id
    WHERE s.rfid_uid = p_rfid_uid
    FOR UPDATE;

    -- Validasi keberadaan siswa
    IF v_student_id IS NULL THEN
        RAISE EXCEPTION 'Kartu siswa tidak terdaftar di sistem';
    END IF;

    -- Validasi status kartu
    IF NOT v_student_active THEN
        RAISE EXCEPTION 'Kartu siswa diblokir atau dinonaktifkan';
    END IF;

    -- Validasi sisa saldo dompet
    IF v_student_balance < p_total_amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk melakukan transaksi';
    END IF;

    -- Validasi batas jajan harian (daily limit)
    IF v_daily_limit IS NOT NULL AND v_daily_limit > 0 THEN
        -- Hitung total belanja sukses bertipe 'purchase' milik siswa hari ini
        SELECT COALESCE(SUM(total_amount), 0) INTO v_today_spending
        FROM public.transactions
        WHERE student_id = v_student_id
          AND type = 'purchase'
          AND status = 'success'
          AND created_at::date = CURRENT_DATE;

        -- Periksa jika transaksi baru ini melampaui sisa limit harian
        IF (v_today_spending + p_total_amount) > v_daily_limit THEN
            RAISE EXCEPTION 'Transaksi ditolak: Melampaui batas jajan harian anak (Maks Rp %)', to_char(v_daily_limit, 'FM999,999,999');
        END IF;
    END IF;

    -- Ambil nama stan kantin untuk keperluan notifikasi
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
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id UUID, quantity INT, unit_price NUMERIC, custom_notes TEXT)
    LOOP
        INSERT INTO public.transaction_items (transaction_id, product_id, quantity, unit_price, custom_notes)
        VALUES (v_transaction_id, v_item.product_id, v_item.quantity, v_item.unit_price, v_item.custom_notes);
    END LOOP;

    -- 6. Terbitkan Notifikasi Belanja Sukses ke Siswa
    INSERT INTO public.notifications (student_id, title, message, type)
    VALUES (
        v_student_id,
        'Jajan Berhasil!',
        'Kamu berhasil membeli makanan senilai Rp ' || to_char(p_total_amount, 'FM999,999,999') || ' di ' || COALESCE(v_canteen_name, 'Kantin'),
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
