# Rincian Skema Database Supabase

Proyek ini menggunakan **Supabase PostgreSQL** sebagai penyimpanan data utama. Struktur relasi, logika RLS (Row Level Security), dan Stored Procedure (RPC) dirancang untuk memastikan konsistensi ACID, terutama untuk pemotongan saldo secara digital.

File migrasi database riil dapat ditemukan di [20260615000000_init.sql](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/supabase/migrations/20260615000000_init.sql).

---

## 📊 1. Kamus Tabel

### Tabel `public.profiles`
Menyimpan profil umum semua pengguna yang terintegrasi dengan tabel `auth.users` di Supabase.
*   `id` (UUID, PK, FK): Berelasi dengan `auth.users(id)`
*   `email` (TEXT, Unique)
*   `full_name` (TEXT)
*   `role` (TEXT): Berisi salah satu nilai: `'student'`, `'petugas_kantin'`, `'admin'`

### Tabel `public.students`
Menyimpan informasi spesifik siswa, termasuk sisa saldo saku digital dan nomor UID kartu fisik RFID.
*   `id` (UUID, PK, FK): Berelasi dengan `public.profiles(id)`
*   `class` (TEXT): Menyimpan data kelas siswa (contoh: "8-B")
*   `balance` (NUMERIC): Sisa uang saku digital siswa (default: `0.00`)
*   `rfid_uid` (TEXT, Unique, Nullable): UID unik dari kartu RFID/NFC fisik siswa
*   `is_active` (BOOLEAN): Status kartu aktif/diblokir (default: `true`)

### Tabel `public.canteen_operators`
Menyimpan informasi stan kantin / warung sekolah.
*   `id` (UUID, PK, FK): Berelasi dengan `public.profiles(id)`
*   `canteen_name` (TEXT): Nama stan kantin
*   `balance_earned` (NUMERIC): Saldo akumulasi hasil jualan yang berhak dicairkan (default: `0.00`)

### Tabel `public.products`
Katalog jajanan yang dijual oleh pemilik stan kantin.
*   `id` (UUID, PK)
*   `operator_id` (UUID, FK): Berelasi dengan `public.canteen_operators(id)`
*   `name` (TEXT): Nama produk makanan/minuman
*   `price` (NUMERIC): Harga satuan produk
*   `category` (TEXT): Kategori jajanan (`'makanan'` atau `'minuman'`)
*   `is_available` (BOOLEAN): Status ketersediaan stok produk (default: `true`)
*   `image_url` (TEXT, Nullable): URL foto produk di Supabase Storage

### Tabel `public.transactions`
Log seluruh transaksi pembayaran jajan dan pengisian saldo (top-up).
*   `id` (UUID, PK)
*   `student_id` (UUID, FK): Berelasi dengan `public.students(id)`
*   `operator_id` (UUID, FK): Berelasi dengan `public.canteen_operators(id)`
*   `total_amount` (NUMERIC): Total uang transaksi
*   `type` (TEXT): Tipe transaksi (`'purchase'` atau `'topup'`)
*   `status` (TEXT): Status transaksi (`'success'`, `'pending'`, `'failed'`, `'cancelled'`)
*   `created_at` (TIMESTAMP)

### Tabel `public.transaction_items`
Rincian item jajanan yang dibeli dalam satu transaksi checkout.
*   `id` (UUID, PK)
*   `transaction_id` (UUID, FK): Berelasi dengan `public.transactions(id)`
*   `product_id` (UUID, FK): Berelasi dengan `public.products(id)`
*   `quantity` (INTEGER): Jumlah produk yang dibeli
*   `unit_price` (NUMERIC): Harga satuan saat dibeli
*   `custom_notes` (TEXT, Nullable): Catatan kustom tambahan (contoh: "Ekstra Telur")

### Tabel `public.notifications`
Log notifikasi real-time yang dikirim ke aplikasi siswa.
*   `id` (UUID, PK)
*   `student_id` (UUID, FK): Berelasi dengan `public.students(id)`
*   `title` (TEXT)
*   `message` (TEXT)
*   `type` (TEXT): Kategori notifikasi (`'purchase'`, `'topup'`, `'system'`)
*   `is_read` (BOOLEAN): Status telah dibaca (default: `false`)

---

## ⚙️ 2. Stored Procedures / RPC Functions

### 1. `process_purchase(...)`
Fungsi aman server-side untuk memotong saldo siswa saat tap kartu RFID:
*   **Keamanan ACID**: Menggunakan `SELECT ... FOR UPDATE` untuk mengunci data saldo siswa saat divalidasi agar terhindar dari *race condition/double spend*.
*   **Logic**:
    1. Mencari siswa berdasarkan `rfid_uid`.
    2. Validasi status kartu (`is_active = true`) dan ketersediaan saldo.
    3. Mengurangi saldo siswa, menambah saldo pendapatan operator stan.
    4. Menyisipkan entri ke `transactions` & `transaction_items` secara masal.
    5. Membuat log notifikasi otomatis.

### 2. `process_refund(...)`
Fungsi pembatalan transaksi jajan oleh kasir:
*   **Batas Waktu**: Validasi waktu pembuatan transaksi maksimal **10 menit** sejak tap kartu dilakukan.
*   **Logic**:
    1. Mengubah status transaksi menjadi `'cancelled'`.
    2. Mengembalikan saldo belanja ke dompet siswa.
    3. Mengurangi saldo pendapatan operator stan.
    4. Mengirimkan notifikasi pembatalan (refund) ke siswa.

---

## 🛡️ 3. Kebijakan RLS (Row Level Security)
*   **`profiles`**: Dapat dibaca oleh semua aktor terautentikasi. Hanya bisa diedit oleh pemilik profil itu sendiri.
*   **`students`**: Dapat dibaca oleh siswa pemilik akun dan kasir petugas kantin (role: `petugas_kantin`) untuk verifikasi identitas kartu.
*   **`canteen_operators`**: Dapat dibaca oleh petugas kantin pemilik stan.
*   **`products`**: Dapat dibaca oleh semua user terautentikasi (siswa & kasir). Hanya dapat di-CRUD oleh petugas pemilik stan.
*   **`transactions` & `transaction_items`**: Hanya dapat dibaca oleh siswa atau kasir yang terlibat dalam transaksi tersebut.
*   **`notifications`**: Hanya dapat dibaca oleh siswa pemilik notifikasi.
