# 🛡️ Panduan Pemetaan Hak Akses & Kebijakan Supabase RLS (Row Level Security)

Dokumen ini disusun untuk memudahkan pengaktifan RLS (Row Level Security) pada basis data Supabase PostgreSQL untuk Sistem Kantin Digital. Setiap tabel di bawah ini dilengkapi dengan hak akses operasi (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) per peran (role).

---

## Ringkasan Peran Database (Auth Role)
1. **`super_admin`** (di tabel `profiles.role` bernilai `'admin'` atau `'super_admin'`)
2. **`petugas_keuangan`** (di tabel `profiles.role` bernilai `'petugas_keuangan'`)
3. **`petugas_kantin`** (di tabel `profiles.role` bernilai `'petugas_kantin'`)
4. **`student`** (di tabel `profiles.role` bernilai `'student'`)
5. **`parent`** (di tabel `profiles.role` bernilai `'parent'`)
6. **`anon` / public** (pengguna tidak login / portal orang tua non-akun)

---

## Aturan RLS per Tabel

### 1. Tabel: `public.profiles`
Menyimpan data akun pengguna utama.
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat membaca semua data profile.
  * `student`, `petugas_kantin`, `parent`: Hanya dapat membaca baris profil milik sendiri (`auth.uid() = id`).
  * `anon` / public: Hanya dapat membaca kolom `full_name`, `nisn`, `role` untuk siswa melalui NISN (untuk kebutuhan cek saldo portal wali murid tanpa akun).
* **`INSERT`**:
  * `super_admin`: Dapat menambah baris apa saja.
  * `petugas_keuangan`: Hanya diperbolehkan menambah profil dengan role `'student'`, `'parent'`, atau `'petugas_kantin'`.
  * Peran lain: Dilarang (`deny`).
* **`UPDATE`**:
  * `super_admin`: Bebas meng-update kolom apa saja.
  * `petugas_keuangan`: Dapat meng-update field data siswa, orang tua, dan petugas kantin.
  * Aktor bersangkutan (`id = auth.uid()`): Hanya diperbolehkan meng-update password (`password`), nomor HP (`phone_number`), atau foto profil (`avatar_url`).
* **`DELETE`**:
  * Hanya diperbolehkan untuk `super_admin`.

---

### 2. Tabel: `public.students`
Menyimpan saldo siswa dan data kartu RFID.
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat melihat semua data siswa.
  * `petugas_kantin`: Dapat membaca data siswa (`full_name`, `balance`, `class`, `rfid_uid`) saat memproses tap kartu RFID belanja.
  * `student`: Hanya dapat membaca data miliknya sendiri (`id = auth.uid()`).
  * `parent`: Dapat membaca data siswa yang terhubung dengannya di `parent_students`.
  * `anon`: Hanya dapat mencari data saldo berdasarkan NISN/RFID (untuk portal wali murid).
* **`INSERT`**:
  * `super_admin` & `petugas_keuangan`: Dapat memasukkan data siswa baru saat registrasi manual.
  * Peran lain: Dilarang.
* **`UPDATE`**:
  * `super_admin`: Bebas meng-update data siswa.
  * `petugas_keuangan`: Hanya diperbolehkan meng-update kelas, RFID UID, limit harian, status kartu, atau koreksi saldo.
  * `petugas_kantin` & `student`: Dilarang meng-update saldo secara langsung dari client. **Perubahan saldo wajib melalui secure RPC stored procedure** (`process_purchase` / `process_refund`).
* **`DELETE`**:
  * Hanya `super_admin`.

---

### 3. Tabel: `public.products`
Menyimpan produk jajanan kantin.
* **`SELECT`**:
  * Diperbolehkan untuk **semua peran** (termasuk `anon` / public) untuk menampilkan menu kantin.
* **`INSERT`**:
  * `super_admin`: Bebas.
  * `petugas_kantin`: Hanya untuk produk stand miliknya sendiri (`operator_id = auth.uid()`).
* **`UPDATE`**:
  * `super_admin`: Bebas.
  * `petugas_kantin`: Hanya untuk produk stand miliknya sendiri (`operator_id = auth.uid()`).
* **`DELETE`**:
  * `super_admin`: Bebas.
  * `petugas_kantin`: Hanya untuk produk stand miliknya sendiri (`operator_id = auth.uid()`).

---

### 4. Tabel: `public.transactions`
Menyimpan data transaksi (belanja & top-up).
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat melihat semua transaksi.
  * `petugas_kantin`: Hanya dapat melihat transaksi stand miliknya (`operator_id = auth.uid()`).
  * `student`: Hanya dapat melihat transaksi belanja miliknya sendiri (`student_id = auth.uid()`).
  * `parent`: Hanya dapat melihat transaksi siswa yang terhubung dengan akun ortu bersangkutan.
  * `anon`: Hanya dapat melihat 5 transaksi terakhir dari NISN siswa yang diinputkan.
* **`INSERT`**:
  * **Wajib melalui RPC secure function** database (`process_purchase`, `process_topup`) untuk mencegah manipulasi saldo langsung dari client side.
* **`UPDATE` / `DELETE`**:
  * Dilarang keras untuk semua aktor (transaksi bersifat *immutable* / kekal). Pembatalan transaksi (refund) wajib melalui RPC secure function `process_refund`.

---

### 5. Tabel: `public.transaction_items`
Menyimpan item detail produk yang dibeli per transaksi.
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat melihat semua baris.
  * `petugas_kantin`: Hanya dapat melihat item transaksi dari stand miliknya.
  * `student`: Hanya dapat melihat detail item transaksi miliknya sendiri.
* **`INSERT`**:
  * **Wajib melalui RPC secure function** database bersamaan dengan pembuatan record `transactions`.
* **`UPDATE` / `DELETE`**:
  * Dilarang keras.

---

### 6. Tabel: `public.audit_logs`
Menyimpan riwayat audit untuk memantau integritas keuangan.
* **`SELECT`**:
  * Hanya `super_admin` dan `petugas_keuangan`.
* **`INSERT`**:
  * Diperbolehkan untuk mencatat log aktivitas bagi semua user terautentikasi (`authenticated`).
* **`UPDATE` / `DELETE`**:
  * Dilarang keras (audit log bersifat *read-and-append only* untuk mencegah manipulasi pelacakan).

---

### 7. Tabel: `public.canteen_operators` & `public.finance_officers`
Menyimpan relasi spesifik stan kantin dan petugas keuangan.
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat membaca seluruh data.
  * Pemilik data (`id = auth.uid()`): Hanya dapat melihat data milik sendiri.
* **`INSERT` / `UPDATE` / `DELETE`**:
  * Hanya `super_admin`.

---

### 8. Tabel: `public.parent_students`
Menghubungkan orang tua dengan anak (siswa).
* **`SELECT`**:
  * `super_admin` & `petugas_keuangan`: Dapat melihat semua baris.
  * `parent`: Hanya dapat membaca baris miliknya sendiri (`parent_id = auth.uid()`).
* **`INSERT` / `UPDATE` / `DELETE`**:
  * Hanya `super_admin` & `petugas_keuangan`.

---

### 9. Tabel: `public.system_settings`
Menyimpan setelan sistem aplikasi (misal: persentase fee/biaya administrasi).
* **`SELECT`**:
  * Diperbolehkan untuk semua peran terautentikasi (`authenticated`) dan public (`anon`).
* **`INSERT` / `UPDATE` / `DELETE`**:
  * Hanya `super_admin`.

---

## Contoh Implementasi Query Kebijakan (SQL DDL)
Berikut adalah draf SQL untuk mengaktifkan RLS dan membuat policy pada tabel `products` sebagai contoh:

```sql
-- 1. Aktifkan RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- 2. Policy: Siapapun bisa melihat produk
CREATE POLICY "Semua orang bisa melihat menu"
  ON public.products FOR SELECT
  USING (true);

-- 3. Policy: Hanya pemilik kantin bersangkutan yang bisa memanipulasi produk stand-nya
CREATE POLICY "Petugas kantin mengelola menu sendiri"
  ON public.products FOR ALL
  TO authenticated
  USING (
    operator_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid() AND profiles.role IN ('admin', 'super_admin')
    )
  );
```
