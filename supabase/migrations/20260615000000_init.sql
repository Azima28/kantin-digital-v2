-- Inisialisasi Extension UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================================
-- 1. PEMBUATAN TABEL-TABEL UTAMA
-- =====================================================================

-- Tabel profil pengguna secara umum
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'petugas_kantin', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabel data siswa (berelasi dengan profiles)
CREATE TABLE public.students (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    class TEXT NOT NULL,
    balance NUMERIC(12, 2) DEFAULT 0.00 NOT NULL CHECK (balance >= 0),
    rfid_uid TEXT UNIQUE,
    is_active BOOLEAN DEFAULT true NOT NULL
);

-- Tabel data operator kantin / pemilik stan (berelasi dengan profiles)
CREATE TABLE public.canteen_operators (
    id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    canteen_name TEXT NOT NULL,
    balance_earned NUMERIC(12, 2) DEFAULT 0.00 NOT NULL CHECK (balance_earned >= 0)
);

-- Tabel katalog jajanan / produk
CREATE TABLE public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    operator_id UUID REFERENCES public.canteen_operators(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price > 0),
    category TEXT NOT NULL CHECK (category IN ('makanan', 'minuman')),
    is_available BOOLEAN DEFAULT true NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabel transaksi pembayaran & top-up
CREATE TABLE public.transactions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.students(id) ON DELETE RESTRICT NOT NULL,
    operator_id UUID REFERENCES public.canteen_operators(id) ON DELETE RESTRICT NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount > 0),
    type TEXT NOT NULL CHECK (type IN ('purchase', 'topup')),
    status TEXT NOT NULL CHECK (status IN ('success', 'pending', 'failed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tabel detail item per transaksi belanja
CREATE TABLE public.transaction_items (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    transaction_id UUID REFERENCES public.transactions(id) ON DELETE CASCADE NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE RESTRICT,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price > 0),
    custom_notes TEXT
);

-- Tabel log notifikasi sistem/transaksi
CREATE TABLE public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    student_id UUID REFERENCES public.students(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('purchase', 'topup', 'system')),
    is_read BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =====================================================================
-- 2. TRIGGER OTOMATIS LOGIN / REGISTRASI PROFIL
-- =====================================================================

-- Fungsi trigger saat user melakukan registrasi di Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT;
    v_name TEXT;
BEGIN
    -- Menentukan role default (diambil dari metadata auth atau default ke 'student')
    v_role := COALESCE(new.raw_user_meta_data->>'role', 'student');
    v_name := COALESCE(new.raw_user_meta_data->>'full_name', 'User Baru');

    -- Memasukkan data ke tabel public.profiles
    INSERT INTO public.profiles (id, email, full_name, role)
    VALUES (new.id, new.email, v_name, v_role);

    -- Memasukkan data ke tabel turunan berdasarkan role
    IF v_role = 'student' THEN
        INSERT INTO public.students (id, class, balance, is_active)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'class', 'Belum Diisi'), 0.00, true);
    ELSIF v_role = 'petugas_kantin' THEN
        INSERT INTO public.canteen_operators (id, canteen_name, balance_earned)
        VALUES (new.id, COALESCE(new.raw_user_meta_data->>'canteen_name', 'Stan Kantin'), 0.00);
    END IF;

    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Menghubungkan fungsi trigger ke tabel auth.users
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================================
-- 3. STORED PROCEDURE TRANSAKSIONAL (RPC)
-- =====================================================================

-- Prosedur Pembelian Jajanan di Kasir (Tap RFID/NFC)
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
    v_transaction_id UUID;
    v_item RECORD;
    v_canteen_name TEXT;
BEGIN
    -- 1. Mengunci baris siswa berdasarkan RFID UID untuk menghindari Double Spend
    SELECT s.id, p.full_name, s.balance, s.is_active
    INTO v_student_id, v_student_name, v_student_balance, v_student_active
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

    -- Validasi sisa saldo
    IF v_student_balance < p_total_amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk melakukan transaksi';
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


-- Prosedur Pembatalan Transaksi Kasir / Refund (Maksimal 10 Menit)
CREATE OR REPLACE FUNCTION public.process_refund(
    p_transaction_id UUID,
    p_operator_id UUID,
    p_reason TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_student_id UUID;
    v_total_amount NUMERIC;
    v_transaction_status TEXT;
    v_transaction_type TEXT;
    v_transaction_operator UUID;
    v_created_at TIMESTAMP WITH TIME ZONE;
    v_canteen_name TEXT;
BEGIN
    -- 1. Mengambil data transaksi dengan kunci baris
    SELECT student_id, operator_id, total_amount, status, type, created_at
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

    -- 3. Kembalikan saldo ke dompet siswa
    UPDATE public.students
    SET balance = balance + v_total_amount
    WHERE id = v_student_id;

    -- 4. Potong pendapatan saldo operator kantin
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

-- =====================================================================
-- 4. KELOLA ROW LEVEL SECURITY (RLS) & POLICIES
-- =====================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_operators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Policies untuk PROFILES
CREATE POLICY "Semua user terautentikasi dapat membaca data profil"
    ON public.profiles FOR SELECT TO authenticated USING (true);

CREATE POLICY "User hanya dapat memperbarui data profil miliknya sendiri"
    ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);

-- Policies untuk STUDENTS
CREATE POLICY "Siswa dapat membaca data murid miliknya sendiri"
    ON public.students FOR SELECT TO authenticated USING (auth.uid() = id);

CREATE POLICY "Kasir petugas kantin dapat membaca data murid untuk verifikasi kartu"
    ON public.students FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'petugas_kantin'
        )
    );

-- Policies untuk CANTEEN_OPERATORS
CREATE POLICY "Operator kantin dapat melihat data tokonya sendiri"
    ON public.canteen_operators FOR SELECT TO authenticated USING (auth.uid() = id);

-- Policies untuk PRODUCTS
CREATE POLICY "Semua user terautentikasi dapat melihat daftar jajanan aktif"
    ON public.products FOR SELECT TO authenticated USING (true);

CREATE POLICY "Hanya operator kantin yang dapat mengelola jajanan stannya sendiri"
    ON public.products FOR ALL TO authenticated USING (
        operator_id = auth.uid() AND EXISTS (
            SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'petugas_kantin'
        )
    );

-- Policies untuk TRANSACTIONS & ITEMS
CREATE POLICY "Pengguna terkait dapat melihat transaksi"
    ON public.transactions FOR SELECT TO authenticated USING (
        student_id = auth.uid() OR operator_id = auth.uid()
    );

CREATE POLICY "Pengguna terkait dapat melihat detail item transaksi"
    ON public.transaction_items FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.transactions t
            WHERE t.id = transaction_id AND (t.student_id = auth.uid() OR t.operator_id = auth.uid())
        )
    );

-- Policies untuk NOTIFICATIONS
CREATE POLICY "Siswa hanya dapat melihat notifikasi miliknya sendiri"
    ON public.notifications FOR SELECT TO authenticated USING (student_id = auth.uid());
