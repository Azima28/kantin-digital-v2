# Catatan Perbaikan & Penyelesaian Masalah (Troubleshooting Logs)

Dokumen ini mencatat riwayat kendala teknis yang ditemukan selama pengembangan aplikasi beserta solusi perbaikannya, agar agen AI berikutnya dapat menghindari masalah yang sama.

**Terakhir diperbarui**: 3 Juli 2026

---

## 🛠️ Kendala & Solusi

### 1. Error Kompilasi: `CardTheme` tidak bisa diassign ke `CardThemeData?`
*   **Masalah**: Saat menjalankan `flutter run` pertama kali, kompilator gagal pada file `lib/core/theme/app_theme.dart` dengan pesan:
    ```text
    Error: The argument type 'CardTheme' can't be assigned to the parameter type 'CardThemeData?'.
    ```
*   **Penyebab**: Di Flutter SDK versi terbaru (Material 3), properti `cardTheme` di kelas `ThemeData` mengharapkan tipe data `CardThemeData?` bukan `CardTheme` (yang sekarang digunakan sebagai nama widget kartu UI).
*   **Solusi**: Mengubah instansiasi di file `lib/core/theme/app_theme.dart` dari `CardTheme` menjadi **`CardThemeData`**:
    ```dart
    // Sebelum
    cardTheme: CardTheme(...)

    // Sesudah (Solusi)
    cardTheme: CardThemeData(...)
    ```

---

### 2. Peringatan Depresiasi (*Deprecated Lint Warnings*)
*   **Masalah**: `flutter analyze` mendeteksi dua peringatan depresiasi:
    1.  *background* terdepresiasi pada `ColorScheme.fromSeed` di `app_theme.dart`.
    2.  *anonKey* terdepresiasi pada inisialisasi `Supabase.initialize` di `main.dart`.
*   **Solusi**:
    *   Menghapus properti `background` pada `ColorScheme.fromSeed` di [app_theme.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/theme/app_theme.dart) karena Material 3 secara otomatis mewarisi nilainya dari properti `surface` yang sudah dikonfigurasikan.
    *   Mengganti properti `anonKey` menjadi **`publishableKey`** pada pemanggilan `Supabase.initialize` di [main.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/main.dart) sesuai standar terbaru dari Supabase Flutter SDK.

---

### 3. Masalah Visual: Teks "Splash Screen" Berwarna Merah dan Bergaris Bawah Kuning
*   **Masalah**: Saat aplikasi dijalankan pertama kali, teks di layar placeholder utama tampil berwarna merah tebal dengan dua garis bawah kuning.
*   **Penyebab**: Kelas `_PlaceholderScreen` menggunakan widget iOS `CupertinoPageScaffold` di bawah konfigurasi `MaterialApp.router`. Karena tidak dibungkus oleh parent widget bertipe `Material` (seperti `Scaffold` atau `Material` canvas), Flutter tidak dapat menemukan konteks tipe data dan gaya teks bawaan (*default typography*).
*   **Solusi**: Mengubah modul visual placeholder di [app_router.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/router/app_router.dart) untuk menggunakan widget **`Scaffold`** dan **`AppBar`** standar Material. Perubahan ini secara otomatis mewarisi konfigurasi tema font dari `AppTheme.lightTheme`.

---

### 4. Error RLS: `new row violates row-level security policy for table 'audit_logs'` (Code 42501)
*   **Masalah**: Saat Admin Keuangan menekan tombol "KUNCI & PROSES KOREKSI" di layar Koreksi Saldo, muncul error:
    ```text
    PostgreSQLException(message: new row violates row-level security policy for table 'audit_logs', code: 42501)
    ```
*   **Penyebab (2 lapis)**:
    1.  **Tabel `audit_logs` tidak memiliki policy INSERT** di migrasi awal. Policy RLS hanya mengizinkan `SELECT` untuk role `admin` dan `super_admin`, tanpa policy `INSERT` sama sekali untuk role `petugas_keuangan`.
    2.  **AuthService tidak menggunakan Supabase Auth** — file `lib/features/auth/services/auth_service.dart` hanya melakukan query langsung ke tabel `profiles` dengan kolom `password`, tanpa pernah memanggil `Supabase.auth.signInWithPassword()`. Akibatnya, session JWT tidak terbentuk dan `auth.uid()` di RLS selalu bernilai `NULL`, sehingga semua policy yang bergantung pada `auth.uid()` gagal.
*   **Solusi**:
    1.  Membuat file migrasi baru [20260617000400_fix_rls_policies_keuangan.sql](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/supabase/migrations/20260617000400_fix_rls_policies_keuangan.sql) yang menambahkan policy `INSERT` dan `UPDATE` untuk role `petugas_keuangan` dan `admin` pada tabel: `audit_logs`, `students`, `notifications`, `transactions`, `profiles`, `canteen_operators`, dan `finance_officers`.
    2.  Menulis ulang [auth_service.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/features/auth/services/auth_service.dart) agar memanggil `Supabase.auth.signInWithPassword()` terlebih dahulu sebelum mengambil profil dari database. Hal ini menjamin session JWT terbentuk sehingga `auth.uid()` berfungsi dengan benar di semua policy RLS.
    
    **File migrasi SQL ini WAJIB dijalankan di Supabase SQL Editor** agar perubahan RLS berlaku di database online.

---

### 5. RLS Dinonaktifkan untuk Development (Perlu Diwaspadai)
*   **Konteks**: File migrasi `20260617000500_disable_rls_for_dev.sql` menonaktifkan RLS secara global pada semua tabel untuk memudahkan development.
*   **Dampak**: Semua query berhasil tanpa perlu JWT session yang valid. Ini berarti bug autentikasi/otorisasi tidak akan terdeteksi selama development.
*   **Tindakan yang Diperlukan Sebelum Production**:
    ```sql
    -- Jalankan di Supabase SQL Editor untuk mengaktifkan kembali RLS
    ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
    ALTER TABLE students ENABLE ROW LEVEL SECURITY;
    ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE transaction_types ENABLE ROW LEVEL SECURITY;
    ALTER TABLE balance_adjustments ENABLE ROW LEVEL SECURITY;
    ALTER TABLE rfid_cards ENABLE ROW LEVEL SECURITY;
    ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
    ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
    ALTER TABLE canteen_staff ENABLE ROW LEVEL SECURITY;
    ALTER TABLE finance_officers ENABLE ROW LEVEL SECURITY;
    ```

---

### 6. Password Disimpan Plaintext (Kritikal)
*   **Konteks**: Kolom `profiles.password` menyimpan password dalam bentuk plaintext (tanpa hashing).
*   **Dampak**: Jika database bocor, semua password user langsung terlihat.
*   **Tindakan yang Diperlukan**:
    1.  Buat migrasi untuk hashing semua password existing menggunakan `pgcrypto`:
        ```sql
        UPDATE profiles SET password = crypt(password, gen_salt('bf'))
        WHERE password IS NOT NULL AND length(password) < 60;
        ```
    2.  Update `auth_service.dart` untuk memverifikasi password hashed:
        ```sql
        SELECT id FROM profiles
        WHERE email = $1 AND password = crypt($2, password);
        ```
    3.  Hapus fallback plaintext di `auth_service.dart` setelah migrasi selesai.

---

### 7. Core Providers Ditulis Ulang (Phase 9)
*   **Masalah**: Implementasi `app_providers.dart` sebelumnya menggunakan pattern immutable-heavy yang tidak efisien dan tidak memiliki network monitoring.
*   **Solusi**: Ditulis ulang menggunakan `StateNotifier` untuk `AppState` dengan fitur:
    *   Network monitoring via `connectivity_plus`
    *   Maintenance mode flag
    *   Sync status tracking
    *   Cache duration configuration
    *   Global error provider
*   **File**: `lib/core/providers/app_providers.dart` (overwritten)

---

### 8. Provider Inline di Screen Files (Technical Debt)
*   **Konteks**: Banyak screen mendefinisikan provider langsung di file screen (inline), misalnya `keuanganStudentsProvider` di `keuangan_students_screen.dart`.
*   **Dampak**: Provider sulit di-reuse, testing sulit, dan code organization berantakan.
*   **Solusi yang Sudah Dimulai**: Phase 9 mengekstrak provider ke file terpisah:
    *   `lib/core/providers/shared_providers.dart` — provider lintas fitur
    *   `lib/features/keuangan/providers/keuangan_providers.dart` — provider khusus keuangan
*   **Langkah Selanjutnya**: Update screen files untuk import dari provider files baru, lalu hapus definisi inline.

---

### 9. Error Otorisasi RPC: `PostgrestException: permission denied for function process_purchase` (Code 42501)
*   **Masalah**: Ketika aplikasi dijalankan pada platform web (atau mode offline/fallback di mana session JWT tidak aktif sehingga menggunakan role `anon`), mengeksekusi RPC `process_purchase` mengembalikan error:
    ```text
    PostgrestException(message: permission denied for function process_purchase, code: 42501)
    ```
*   **Penyebab**: Fungsi database (`process_purchase`, `process_refund`, `process_topup`, `process_correction`) membutuhkan otorisasi eksekusi secara eksplisit bagi role `anon`/`public` ketika dipanggil tanpa JWT yang valid (auth.uid() is NULL). Sebelumnya hak eksekusi dibatasi sehingga mengembalikan error 42501.
*   **Solusi**: 
    1. Membuat migrasi baru [20260624000000_fix_fallback_auth_rpc.sql](file:///c:/Users/agust/projects/kantin-digital/supabase/migrations/20260624000000_fix_fallback_auth_rpc.sql) yang:
       * Merekonstruksi fungsi-fungsi tersebut untuk mendukung otorisasi menggunakan parameter `p_operator_id` / `v_caller_uid` secara aman sebagai pengganti `auth.uid()` jika `auth.uid()` bernilai NULL.
       * Memberikan hak akses eksekusi eksplisit secara aman menggunakan `GRANT EXECUTE ON FUNCTION ... TO authenticated, anon, public;`.
    2. Menjalankan perintah `supabase db push` untuk mengaplikasikan migrasi tersebut ke database remote Supabase.

---

### 10. Error Otorisasi RPC Ubah Kata Sandi: `PostgrestException: permission denied for function update_auth_user_password` (Gagal Mengubah Kata Sandi)
*   **Masalah**: Ketika user mencoba mengubah kata sandi pada mode fallback auth (menggunakan role `anon` / `public`), muncul pesan "Gagal mengubah kata sandi" di snackbar UI.
*   **Penyebab**: Fungsi database `update_auth_user_password(UUID, TEXT)` hanya memberikan hak eksekusi kepada role `authenticated`. Di samping itu, fungsi tersebut mengandalkan `auth.uid()` untuk memvalidasi hak akses pengubah (caller), di mana pada mode fallback auth `auth.uid()` bernilai `NULL`.
*   **Solusi**:
    1. Membuat migrasi baru [20260624000200_fix_password_rpc_fallback.sql](file:///c:/Users/agust/projects/kantin-digital/supabase/migrations/20260624000200_fix_password_rpc_fallback.sql) yang merekonstruksi fungsi RPC menjadi `update_auth_user_password(p_user_id UUID, p_new_password TEXT, p_caller_id UUID DEFAULT NULL)`.
    2. Memvalidasi hak akses menggunakan `v_caller_uid := COALESCE(auth.uid(), p_caller_id)` agar parameter `p_caller_id` dapat digunakan secara aman ketika `auth.uid()` bernilai `NULL`.
    3. Memberikan hak akses eksekusi secara eksplisit kepada role `anon` dan `public` dengan perintah `GRANT EXECUTE ON FUNCTION public.update_auth_user_password(UUID, TEXT, UUID) TO authenticated, anon, public;`.
    4. Menambahkan parameter `'p_caller_id'` pada seluruh pemanggilan RPC `update_auth_user_password` di 7 screen/widget di modul Admin & Keuangan:
       - [admin_merchant_detail_screen.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/admin/screens/admin_merchant_detail_screen.dart)
       - [admin_parent_detail_screen.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/admin/screens/admin_parent_detail_screen.dart)
       - [admin_finance_detail_screen.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/admin/screens/admin_finance_detail_screen.dart)
       - [keuangan_settings_screen.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/keuangan/screens/keuangan_settings_screen.dart)
       - [keuangan_profile_screen.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/keuangan/screens/keuangan_profile_screen.dart)
       - [student_detail_password_change.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/keuangan/widgets/student_detail_password_change.dart)
       - [admin_student_password_change.dart](file:///c:/Users/agust/projects/kantin-digital/lib/features/admin/widgets/admin_student_password_change.dart)
    5. Menghapus nested try-catch block kosong pada `student_detail_password_change.dart` dan `admin_student_password_change.dart` yang menelan error secara diam-diam sehingga status error RPC dapat ditangkap dan ditampilkan ke user secara akurat.

---

### 11. Error Visual: RenderFlex Overflow pada Beranda Siswa (Teks Saldo Saku)
*   **Masalah**: Pada halaman beranda siswa (dashboard), jika saldo siswa bernilai sangat besar (misalnya Rp 10.000.000.000) atau layar device kecil, teks saldo `Rp <nominal>` mengalami overflow ke sebelah kanan (`RenderFlex overflowed by X pixels on the right`).
*   **Penyebab**: Baris teks mata uang (`Rp`) dan angka saldo dibungkus dalam `Row` horizontal tanpa pembatasan ukuran (constraint) atau penskalaan otomatis, sehingga melebihi lebar card parent di layar.
*   **Solusi**:
    1. Membungkus `Row` tersebut dengan widget `FittedBox` menggunakan properti `fit: BoxFit.scaleDown` dan `alignment: Alignment.centerLeft`. Hal ini memastikan bahwa teks saldo saku otomatis mengecil secara visual ketika nominalnya melebihi lebar card yang tersedia.
    2. Mengganti string inline `'SALDO SAKU'` pada label kartu dengan konstanta `AppStrings.labelBalance` untuk kepatuhan terhadap aturan arsitektur.
*   **File**: [siswa_dashboard_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart)

---

### 12. Peningkatan Fitur: Cancel Order Modal Premium dengan Validasi & Deteksi Role
*   **Masalah / Kebutuhan**: Aplikasi membutuhkan modal konfirmasi pembatalan pesanan yang lebih modern, interaktif, dan sesuai dengan Design System aplikasi. Modal ini harus memiliki form pemilihan alasan pembatalan yang berbeda untuk siswa dan staf kantin, input untuk alasan custom, dan validasi tombol konfirmasi.
*   **Solusi**:
    1. Membuat widget kustom `CancelOrderModal` di [cancel_order_modal.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/core/widgets/cancel_order_modal.dart) dengan spesifikasi:
       - Animasi masuk & keluar (Scale + Fade).
       - Desain panel modern konsisten dengan warna tema (Primary Teal, Error Red, dan Neutral Grays).
       - Deteksi peran (role detection) dinamis menggunakan state authentication.
       - Formulir interaktif dengan animasi seleksi radio custom, auto-expanding textarea saat memilih alasan "Lainnya", dan validasi tombol (tombol nonaktif jika belum memilih alasan / alasan custom kosong).
       - Dukungan responsive layout (tampilan desktop/tablet & layout mobile vertikal bertumpuk).
       - Interaksi keyboard (menekan tombol ESC untuk menutup dialog).
    2. Mengintegrasikan modal ini ke [siswa_dashboard_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart) dan [order_list_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/screens/order_list_screen.dart) untuk menggantikan pemanggilan RPC langsung / alert dialog standar.
*   **File**:
    - [cancel_order_modal.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/core/widgets/cancel_order_modal.dart) (Widget Baru)
    - [siswa_dashboard_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart) (Integrasi Siswa)
    - [order_list_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/screens/order_list_screen.dart) (Integrasi Kasir/Petugas)

---

### 13. Error Sinkronisasi Migrasi: `column orders.cancel_request_reason does not exist` (Code 42703)
*   **Masalah**: Saat role siswa memuat dashboard, aplikasi mengalami crash atau menampilkan pesan error:
    ```text
    Error: PostgrestException(message: column orders.cancel_request_reason does not exist, code: 42703, details: , hint: null)
    ```
*   **Penyebab**: Migrasi database lokal `20260702153000_add_menunggu_pembatalan.sql` yang menambahkan kolom `cancel_request_reason` dan memperbarui check constraint `orders_status_check` pada tabel `orders` belum diterapkan ke database remote Supabase. Upaya menjalankan `supabase db push` gagal karena adanya konflik data status order yang melanggar batasan constraint sementara (`orders_status_check` yang sempit pada migrasi-migrasi awal terhambat oleh keberadaan row berstatus `'Dibatalkan'`).
*   **Solusi**:
    1. Menjalankan DDL SQL pembaruan constraint akhir secara langsung pada database remote menggunakan Supabase CLI (`supabase db query --linked`) untuk mendukung seluruh status (`'Baru'`, `'Sedang Dimasak'`, `'Siap Diambil'`, `'Siap Diantar'`, `'Selesai'`, `'Dibatalkan'`, `'Menunggu Pembatalan'`) dan menambahkan kolom `cancel_request_reason`.
    2. Mengaplikasikan RPC function `cancel_order` dari file `20260701000200_add_cancel_order_rpc.sql` ke database remote.
    3. Menyinkronkan riwayat migrasi dengan menandai seluruh migrasi tertunda (`20260629170000`, `20260701000100`, `20260701000200`, `20260702153000`) sebagai `applied` menggunakan command `supabase migration repair`.

---

### 14. Error Visual: RenderFlex Overflow pada Kartu Pesanan Kasir (Siswa Minta Batal)
*   **Masalah**: Pada halaman daftar pesanan kasir/petugas, ketika ada pengajuan pembatalan dengan status `'Menunggu Pembatalan'`, kartu pesanan mengalami overflow horizontal (`OVERFLOWED BY 4.5 PIXELS` di sebelah kanan).
*   **Penyebab**: Teks peringatan `"Siswa Minta Batal"`, tombol `"Tolak"`, dan tombol `"Setujui"` ditempatkan bersebelahan dalam satu `Row` tanpa pembatasan ukuran. Akibatnya, pada perangkat dengan ukuran layar standar/sempit, lebar gabungan elemen-elemen tersebut melebihi lebar kartu pesanan.
*   **Solusi**:
    1. Mengubah struktur layout dari `Row` horizontal tunggal menjadi struktur **`Column` vertikal** yang responsive.
    2. Menampilkan teks peringatan `"Siswa Minta Batal"` dalam bentuk **Warning Banner/Chip** yang melintang horizontal (penuh) dengan warna latar belakang merah transparan halus (`AppColors.errorRed2.withValues(alpha: 0.08)`) dan border tipis.
    3. Menempatkan tombol `"Tolak"` dan `"Setujui"` di baris bawahnya, dengan perataan ke kanan (`mainAxisAlignment: MainAxisAlignment.end`) untuk estetika yang lebih bersih dan modern.
    4. Mengganti string literal `"Siswa Minta Batal"`, `"Tolak"`, dan `"Setujui"` dengan merujuk ke konstanta yang didefinisikan di `AppStrings` (`AppStrings.labelSiswaMintaBatal`, `AppStrings.adminReject`, dan `AppStrings.adminApprove`) demi mematuhi aturan arsitektur.
*   **File**:
    - [app_strings.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) (Definisi Konstanta)
    - [order_item_card.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/widgets/order_item_card.dart) (Layout Responsif)

---

### 15. Penyelarasan UI: Rincian Riwayat Transaksi Kasir Mirip dengan Rincian Pesanan
*   **Masalah**: Bottom sheet rincian riwayat transaksi kasir (`showTransactionDetailsSheet`) sebelumnya memiliki desain minimalis/sederhana yang kurang konsisten dengan estetika visual sheet rincian pesanan baru (`OrderDetailSheet`), sehingga memicu disparitas pengalaman pengguna.
*   **Penyebab**: Kode sheet rincian riwayat belum diperbarui untuk mengadopsi elemen visual Design System premium (seperti kartu ber-shadow, daftar barang bergambar/thumbnail, header detail berstatus dinamis, dll.).
*   **Solusi**:
    1. Menulis ulang [transaction_details_sheet.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/widgets/transaction_details_sheet.dart) dengan kelas `TransactionDetailsSheet` (turunan `ConsumerWidget`) untuk mereplikasi desain visual `OrderDetailSheet`.
    2. Menghadirkan header panel premium berketinggian tetap (`height: screenHeight * 0.85`), handle drag iOS minimalis, serta tombol tutup (ikon silang).
    3. Mengintegrasikan **Student Profile Banner** dengan inisial avatar siswa pembeli dan border teal lembut.
    4. Menyusun **Receipt Card** modern yang memuat status transaksi dinamis (hijau `"Berhasil"` / merah `"Dibatalkan"`), tabel informasi meta, dashed divider pemisah, thumbnail gambar jajanan di daftar item, dan kalkulasi total akhir (dengan dekorasi coretan abu-abu jika status transaksi dibatalkan).
*   **File**:
    - [transaction_details_sheet.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/widgets/transaction_details_sheet.dart) (Redesain Visual Sheet Rincian)

---

### 16. Penyelarasan UI: Tampilan Riwayat Penjualan untuk Transaksi Dibatalkan
*   **Masalah**: Penampilan transaksi dibatalkan (Refunded) di tab Penjualan kasir masih menggunakan badge `'Refunded'` berwarna latar merah, yang tidak konsisten dengan layout baru/yang diminta (berupa teks polos merah `"Dibatalkan"`, dan nominal harga dicoret tanpa tanda minus `-`).
*   **Penyebab**: Format string nominal dan status tag di list item penjualan kasir belum dimutakhirkan.
*   **Solusi**:
    1. Memperbarui nominal total penjualan di [sales_history_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/screens/sales_history_screen.dart). Untuk transaksi dibatalkan (`isCancelled`) atau gagal (`isFailed`), tanda minus (`-`) dihilangkan, nominal berwarna abu-abu (`AppColors.textGray`), dan dicoret (`TextDecoration.lineThrough`).
    2. Menghilangkan container badge `"Refunded"` dan menggantinya dengan teks polos `"Dibatalkan"` (warna merah `AppColors.errorRed2`, tebal) untuk transaksi dibatalkan, dan `"Gagal"` untuk transaksi gagal.
    3. Jika transaksi sukses dan tidak bisa direfund (di luar durasi 10 menit), menampilkan teks polos `"Berhasil"` (warna hijau `AppColors.success`, tebal). Jika masih dalam rentang 10 menit, tombol `"Refund"` tetap ditampilkan agar kasir dapat melakukan pembatalan.
*   **File**:
    - [app_strings.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) (Konstanta teks Dibatalkan dan Gagal)
    - [sales_history_screen.dart](file:///D:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/screens/sales_history_screen.dart) (Perubahan Tampilan Daftar Riwayat)
---

### 17. Penyelarasan UI: Sistem Konfirmasi Pembatalan Timbal Balik (Mutual Cancellation)
*   **Masalah**: Siswa tidak bisa membatalkan pesanan yang sedang dimasak/diproses secara langsung (harus disetujui kantin). Sebaliknya, petugas kantin juga tidak bisa membatalkan pesanan yang sudah diterima secara sepihak (harus disetujui siswa). Status pesanan di database perlu mengakomodasi kedua alur persetujuan ini agar saldo aman dan riwayat transaksi akurat.
*   **Penyebab**: Batasan constraint `orders_status_check` di database dan penanganan status batal di modal/layanan belum terintegrasi untuk mendeteksi status persetujuan baru dari murid.
*   **Solusi**:
    1. Membuat migrasi SQL `20260703080000_add_menunggu_persetujuan_murid.sql` untuk memperluas constraint status menjadi: `'Baru'`, `'Sedang Dimasak'`, `'Siap Diambil'`, `'Siap Diantar'`, `'Selesai'`, `'Dibatalkan'`, `'Menunggu Pembatalan'`, dan `'Menunggu Persetujuan Murid'`.
    2. Menjalankan perintah pembaruan constraint di database remote remote Supabase menggunakan redirect pipeline `Get-Content ... | supabase db query --linked` untuk menghindari issue escape karakter PowerShell.
    3. Memperbarui `CancelOrderModal` agar mendeteksi role: Siswa yang membatalkan pesanan in-progress akan mengajukan status `'Menunggu Pembatalan'`, sedangkan operator kantin akan mengajukan status `'Menunggu Persetujuan Murid'`.
    4. Menambahkan layout interaktif di dashboard siswa (`SiswaDashboardScreen`) jika status pesanan `'Menunggu Persetujuan Murid'`, menampilkan banner alasan pembatalan kantin serta tombol "Tolak" (kembali ke `'Sedang Dimasak'`) dan "Setujui Batal" (eksekusi RPC `cancel_order` dan refund saldo).
    5. Menghubungkan RPC `cancel_order` agar otomatis memperbarui status transaksi keuangan terkait di tabel `transactions` menjadi `'cancelled'`, sehingga riwayat pengeluaran siswa langsung sinkron masuk katalog dibatalkan.
*   **File**:
    - [20260703080000_add_menunggu_persetujuan_murid.sql](file:///d:/Kantin-Digital-v2/kantin-digital-v2/supabase/migrations/20260703080000_add_menunggu_persetujuan_murid.sql) (Database DDL & RPC Update)
    - [cancel_order_modal.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/widgets/cancel_order_modal.dart) (Logika Deteksi Role Batal)
    - [siswa_dashboard_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart) (Tampilan Tombol Persetujuan Siswa)
    - [order_list_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/screens/order_list_screen.dart) (Filter Tab Proses Kantin)
    - [order_detail_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/widgets/order_detail_sheet.dart) (Disabled Action Buttons & Badge)
    - [order_item_card.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/kantin/widgets/order_item_card.dart) (Indicator Banner Kantin)

---

### 18. Penyelarasan UI: Restrukturasi Navbar & Relokasi Keranjang Siswa
*   **Masalah**: Pengguna ingin memindahkan menu "Keranjang" dari bottom navbar ke bagian header kanan (sebelah kanan notifikasi) pada role siswa, serta menambahkan tab baru untuk "Pesanan Aktif" di bottom navbar.
*   **Penyebab**: Susunan item `BottomNavigationBar` pada `SiswaMainLayout` sebelumnya memuat item tab Keranjang secara statis, dan belum memiliki rute/screen khusus untuk mendaftar pesanan aktif.
*   **Solusi**:
    1. Membuat file screen baru `lib/features/siswa/screens/siswa_active_orders_screen.dart` untuk menampilkan list scrollable pesanan aktif berdesain premium.
    2. Mendaftarkan rute baru `/student/active-orders` di `lib/core/router/app_router.dart` (ShellRoute).
    3. Mengubah `BottomNavigationBar` di `SiswaMainLayout` dengan mengganti item tab "Keranjang" (index 2) dengan tab "Pesanan" yang menampilkan total pesanan aktif saat ini menggunakan `siswaActiveOrdersProvider` secara asinkron.
    4. Melokasikan akses Keranjang ke `actions` bar kanan atas pada `SiswaDashboardScreen` (sebelah kanan `NotificationBell`) lengkap dengan badge hitungan item keranjang belanja dari `studentCartProvider`.
    5. Menyesuaikan `SiswaCartScreen` dengan tombol back kustom pada `AppBar` agar dapat kembali ke halaman sebelumnya secara natural.
*   **File**:
    - [siswa_active_orders_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_active_orders_screen.dart) (Layar Pesanan Aktif Baru)
    - [siswa_main_layout.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/widgets/siswa_main_layout.dart) (Konfigurasi Bottom Navbar & Sidebar baru)
    - [siswa_dashboard_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart) (Pemindahan icon Keranjang ke header kanan)
    - [siswa_cart_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_cart_screen.dart) (Penambahan tombol back pada AppBar)
    - [app_router.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/router/app_router.dart) (Pendaftaran Rute Baru)

---

### 19. Penyelarasan UI: Kartu Riwayat Jajan Siswa Mirip Kartu Pesanan Aktif
*   **Masalah**: Pengguna ingin tampilan daftar transaksi di menu "Riwayat" pada role siswa diubah agar konsisten dan memiliki gaya visual/catalog yang sama seperti daftar pesanan aktif di menu "Pesanan".
*   **Penyebab**: Kartu riwayat sebelumnya menggunakan desain vertikal dengan garis pembatas samping kiri tebal (indicatorColor), garis putus-putus pembatas total belanja, serta teks yang kurang terstruktur rapat secara horizontal.
*   **Solusi**:
    1. Mengubah struktur kartu transaksi di [siswa_history_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_history_screen.dart) menggunakan tata letak horizontal `Row` berbasis model `_buildActiveOrderCard` dari `SiswaActiveOrdersScreen`.
    2. Menghadirkan leading icon status berlatar transparan soft, kolom info utama di tengah (nama stan/top-up, info metode/waktu transaksi, ID transaksi), serta nominal harga (+ / - Rp) dan badge status transaksi di kolom kanan.
    3. Mendefinisikan konstanta-konstanta string teks statis baru di [app_strings.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) untuk meniadakan penggunaan inline strings di dalam kode layout.
    4. Menghapus method pembantu `_buildHistoryDivider()` yang sudah tidak digunakan lagi untuk menjaga kerapian kode.
*   **File**:
    - [siswa_history_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_history_screen.dart) (Redesain Visual Kartu Riwayat)
    - [app_strings.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) (Definisi Konstanta Teks Baru)

---

### 20. Penyelarasan UI: Tab Filter Riwayat Siswa Menggunakan Sliding Segmented Control
*   **Masalah**: Pengguna ingin menu tab filter di Riwayat Siswa ("Semua", "Jajan", "Top-Up", "Batal") memiliki visual segmented control meluncur (sliding segmented control) dengan badge jumlah/counter seperti di menu Pesanan Aktif Kantin (`OrderStatusTabs`).
*   **Penyebab**: Tab filter riwayat siswa sebelumnya menggunakan deretan tombol scrollable pill minimalis tanpa transisi meluncur, indikator yang statis, dan tidak memuat hitungan/counter dinamis per kategori.
*   **Solusi**:
    1. Membaca data transaksi (`txs`) dari provider di level teratas `build` method di [siswa_history_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_history_screen.dart) menggunakan `.value`.
    2. Menghitung jumlah riwayat transaksi secara dinamis per kategori (Jajan, Top-Up, Batal).
    3. Merestrukturisasi filter tab menggunakan sliding segmented control modern yang memuat track container abu-abu rounded (`BorderRadius.circular(28)`), indikator aktif meluncur berwarna primer (`AppColors.primary`), label GoogleFonts.inter, dan badge jumlah dinamis (berlatar `Colors.blueAccent` ketika tidak terpilih dan semi transparan putih ketika terpilih).
    4. Menghapus scroll controller dan listeners indikator chevron pills karena tab filter baru sudah pas di layar (maksimal 500px, terpusat) tanpa membutuhkan scroll horizontal.
    5. Menambahkan konstanta teks `AppStrings.labelJajan` ke [app_strings.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) untuk label tab Jajan.
    6. Mengatasi error layout "RenderFlex overflowed" pada layar sempit dengan mengecilkan ukuran font label dari `13` menjadi `12`, mempersempit padding horizontal/vertikal badge, mengubah bentuk badge menjadi kapsul rounded (`BorderRadius.circular(10)`), dan membungkus teks label menggunakan widget `Flexible` dengan `TextOverflow.ellipsis`.
*   **File**:
    - [siswa_history_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_history_screen.dart) (Redesain & Perbaikan Overflow Tab Filter)
    - [app_strings.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/constants/app_strings.dart) (Konstanta Teks Baru)

---

### 21. Penyelarasan UI & Fitur: Carousel Promo Makanan Mingguan Dinamis & Unlimited
*   **Masalah**: Slider iklan/promo di beranda siswa sebelumnya berupa placeholder statis dengan jumlah halaman tetap 3 item tanpa data riil, sementara pengguna menginginkan setiap stan kantin memiliki menu andalan sendiri yang dipromosikan di sana secara otomatis berotasi mingguan tanpa batasan (unlimited).
*   **Penyebab**: Implementasi `_buildPromoCarousel()` sebelumnya memakai PageView statis dengan widget `_buildPromoCard()` tanpa fetching database.
*   **Solusi**:
    1. Mengimpor `publicMenuProvider` untuk me-watch data jajanan aktif dari database secara dinamis.
    2. Menyaring menu makanan/minuman yang aktif (`isAvailable == true`).
    3. Mengelompokkan menu berdasarkan operator kantin (`operator_id`), lalu mengurutkan list di setiap kelompok secara stabil.
    4. Menggunakan index minggu kalender sejak epoch (`weekIndex`) untuk memilih 1 produk dari masing-masing kantin secara deterministik modulo (`weekIndex % group.length`). Ini menjamin setiap kantin memiliki tepat 1 menu per minggu di slider, dan menu tersebut otomatis berotasi ganti dengan menu kantin lain di minggu berikutnya.
    5. Membuat antarmuka kartu promo `_buildPromoCard(ProductWithCanteen)` berbasis foto produk secara penuh (full-bleed) menggunakan `CachedNetworkImage` ber-radius `15` (`fit: BoxFit.cover`) tanpa teks bawaan untuk menciptakan billboard promosi visual yang bersih dan premium.
    6. Menambahkan metode `_buildPromoFallbackCard(ProductWithCanteen)` berupa kartu gradasi berwarna teal/putih yang menyajikan nama makanan, nama stan kantin, harga terformat rupiah, dan dekorasi icon foto sebagai fallback visual apabila menu andalan tidak memiliki gambar/gagal dimuat.
    7. Mengatur dots indicators agar terbuat secara dinamis berdasarkan total jumlah stan kantin andalan minggu tersebut.
*   **File**:
    - [siswa_dashboard_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/siswa/screens/siswa_dashboard_screen.dart) (Implementasi Promo Carousel Dinamis & Full-bleed Billboard)

---

### 22. Perbaikan UI: Penghapusan Campuran Dark Mode pada Mode Terang (Light Mode)
*   **Masalah**: Di beberapa halaman seperti menu Beranda dan Riwayat di role Petugas Kantin, terdapat campuran elemen Dark Mode (warna latar belakang atau panel yang sangat gelap/gelap gulita) saat aplikasi diatur ke mode Terang.
*   **Penyebab**: Beberapa widget menggunakan warna latar belakang statis atau hardcoded seperti `Colors.white` yang tidak adaptif, atau merujuk ke parameter warna statis `AppColors` yang tidak sensitif terhadap perubahan tema sistem atau aplikasi, serta hilangnya argument `BuildContext context` pada beberapa fungsi widget helper sehingga tidak dapat menggunakan `ThemeData` dari `ThemeExtensions`. Komponen kustom `NebulaCard` juga menggunakan warna latar belakang statis `Cosmic.surface` secara hardcoded.
*   **Solusi**:
    1. Mengaudit seluruh file layout dan widget pembantu di seluruh role (Siswa, Petugas Kantin, Orang Tua, Staf Keuangan, Super Admin).
    2. Mengganti semua properti warna statis (`Colors.white`, `Colors.black`, dll.) dengan token tema yang adaptif (`context.cardBg`, `context.surfaceBg`, `context.textPrimary`, `context.textSecondary`, `context.dividerCol`, dll.).
    3. Mengubah komponen kustom `NebulaCard` agar mendeteksi tema aktif secara dinamis (`context.cardBg` dan `context.dividerCol`) alih-alih menggunakan warna statis `Cosmic.surface`.
    4. Mengubah tanda tangan method helper (`_sectionHeader`, `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`, `_buildStatCard`, dll.) agar menerima `BuildContext context` sebagai argumen pertamanya. Hal ini memungkinkan pemanggilan extension properti tema secara aman.
    5. Memperbaiki konstruktor `ParentReceiptScreen` agar menerima `receiptData` kembali untuk kompatibilitas penuh dengan rute `GoRouter`, serta menghilangkan deklarasi `const` tidak valid pada widget `Text` yang memuat fungsi non-constant `GoogleFonts.inter`.
*   **File**:
    - [nebula_components.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/core/widgets/nebula_components.dart) (Refaktor `NebulaCard` agar adaptif tema)
    - [parent_receipt_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/parent/screens/parent_receipt_screen.dart) (Perbaikan konstruktor & penghapusan `const` invalid)
    - [parent_receipt_bottom_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/parent/widgets/parent_receipt_bottom_sheet.dart) (Refaktor menjadi theme-aware secara penuh)
    - [keuangan_dashboard_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/screens/keuangan_dashboard_screen.dart) (Penambahan `BuildContext` pada `_buildStatCard`)
    - [operator_list_tab.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/widgets/operator_list_tab.dart) (Refaktor helper `_sectionHeader` dan `_buildEmptyState`)
    - [parent_list_tab.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/widgets/parent_list_tab.dart) (Refaktor helper `_sectionHeader` dan `_buildEmptyState`)
    - [student_detail_header.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/widgets/student_detail_header.dart) (Refaktor helper `_buildProfileSummary` dan `_buildBalanceCard`)
    - [students_add_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/widgets/students_add_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`)
    - [users_add_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/widgets/users_add_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`)
    - [admin_add_canteen_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/admin/widgets/admin_add_canteen_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`)
    - [admin_add_student_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/admin/widgets/admin_add_student_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`)
    - [admin_edit_merchant_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/admin/widgets/admin_edit_merchant_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`)
    - [admin_edit_student_sheet.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/admin/widgets/admin_edit_student_sheet.dart) (Refaktor helper `_sectionLabel`, `_buildFormField`, `_buildDropdownRow`)

---

### 23. Fitur: Penambahan Toggle Dark Mode pada Role Admin Keuangan
*   **Masalah**: Pengguna dengan peran Admin Keuangan (seperti akun Budi Hartono) tidak memiliki opsi untuk beralih antara Mode Terang dan Mode Gelap di halaman "Akun Saya" karena hilangnya kontrol theme switcher.
*   **Solusi**:
    1. Mengimpor widget premium `ThemeToggleTile` ke dalam halaman pengaturan admin keuangan.
    2. Menambahkan instansiasi `ThemeToggleTile` di dalam bagian "Keamanan" pada `KeuanganSettingsScreen` agar selaras dengan tata letak profil siswa, petugas kantin, dan super admin.
*   **File**:
    - [keuangan_settings_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/screens/keuangan_settings_screen.dart) (Integrasi `ThemeToggleTile`)

---

### 24. Perbaikan UI: Koreksi Background Aktivitas Terbaru pada Role Admin Keuangan
*   **Masalah**: Di dashboard Admin Keuangan (Beranda), kontainer daftar "Aktivitas Terbaru" berwarna putih bersih secara statis saat berada di bawah Mode Gelap (*Dark Mode*). Hal ini membuat teks aktivitas (yang sewajarnya berwarna putih) menjadi tidak terlihat (white-on-white).
*   **Penyebab**: Container list aktivitas menggunakan warna latar belakang keras/statis `Colors.white` di dalam `KeuanganDashboardScreen`.
*   **Solusi**: Mengganti properti `color: Colors.white` dengan token tema dinamis `color: context.cardBg` pada container aktivitas terbaru agar menyesuaikan secara mulus dengan tema aktif.
*   **File**:
    - [keuangan_dashboard_screen.dart](file:///d:/Kantin-Digital-v2/kantin-digital-v2/lib/features/keuangan/screens/keuangan_dashboard_screen.dart) (Perbaikan warna latar belakang aktivitas terbaru)

