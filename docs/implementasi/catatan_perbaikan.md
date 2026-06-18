# Catatan Perbaikan & Penyelesaian Masalah (Troubleshooting Logs)

Dokumen ini mencatat riwayat kendala teknis yang ditemukan selama pengembangan aplikasi beserta solusi perbaikannya, agar agen AI berikutnya dapat menghindari masalah yang sama.

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
    *   Menghapus properti `background` pada `ColorScheme.fromSeed` di [app_theme.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/theme/app_theme.dart) karena Material 3 secara otomatis mewarisi nilainya dari properti `surface` yang sudah kita konfigurasikan.
    *   Mengganti properti `anonKey` menjadi **`publishableKey`** pada pemanggilan `Supabase.initialize` di [main.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/main.dart) sesuai standar terbaru dari Supabase Flutter SDK.

---

### 3. Masalah Visual: Teks "Splash Screen" Berwarna Merah dan Bergaris Bawah Kuning
*   **Masalah**: Saat aplikasi dijalankan pertama kali, teks di layar placeholder utama tampil berwarna merah tebal dengan dua garis bawah kuning.
*   **Penyebab**: Kelas `_PlaceholderScreen` menggunakan widget iOS `CupertinoPageScaffold` di bawah konfigurasi `MaterialApp.router`. Karena tidak dibungkus oleh parent widget bertipe `Material` (seperti `Scaffold` atau `Material` canvas), Flutter tidak dapat menemukan konteks tipe data dan gaya teks bawaan (*default typography*).
*   **Solusi**: Mengubah modul visual placeholder di [app_router.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/core/router/app_router.dart) untuk menggunakan widget **`Scaffold`** dan **`AppBar`** standar Material. Perubahan ini secara otomatis mewarisi konfigurasi tema font `Inter` dari `AppTheme.lightTheme`.

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
    2.  Menulis ulang [auth_service.dart](file:///C:/Work/Project%20PKL/sistem%20kantin%20digital/lib/features/auth/services/auth_service.dart) agar memanggil `Supabase.auth.signInWithPassword()` terlebih dahulu sebelum mengambil profil dari database. Hal ini menjamin session JWT terbentuk sehingga `auth.uid()` berfungsi dengan benar di semua policy RLS. Method `currentSession` dan `signOut` juga diperbaiki agar menggunakan Supabase Auth secara penuh.
    
    **File migrasi SQL ini WAJIB dijalankan di Supabase SQL Editor** agar perubahan RLS berlaku di database online.
