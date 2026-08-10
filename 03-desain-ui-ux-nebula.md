# 🎨 Spesifikasi UI/UX Desain Sistem: "Nebula Kantin Digital v2"
**Tujuan:** Menciptakan tampilan Welcome & Login yang bersih, fungsional, dan nyaman di mode **Dark** maupun **Light**, serta menghindari kesan "generik buatan AI".

---

## 1. Filosofi Desain & Cara Menghindari "Terlihat Buatan AI"

| Kesalahan Umum AI | Solusi Desain Manusia (Yang akan kita pakai) |
| :--- | :--- |
| Menggunakan gradien cerah di 100% area background. | Background **solid** (abu-abu gelap/terang). Gradien hanya digunakan pada **tombol aksi utama** atau **ilustrasi dekoratif**. |
| Teks diletakkan di atas gambar foto yang sibuk. | Teks hanya diletakkan di atas **solid color** atau **pattern/ilustrasi vektor sederhana** yang diberi efek blur/overlay. |
| Menggunakan `BorderRadius.circular(25)` di semua elemen. | Radius konsisten: **`12px`** untuk Card, **`8px`** untuk Input Field, **`16px`** untuk Tombol Besar. |
| Spacing (jarak) antar elemen tidak beraturan. | Menerapkan **8px Grid System**. Semua margin/padding adalah kelipatan 8 (8, 16, 24, 32). |
| Menggunakan terlalu banyak efek *Glassmorphism* (kaca buram). | Glassmorphism hanya digunakan di **1 elemen utama** (misal: Card Login). Elemen lainnya dibuat *opaque* (solid) agar mudah dibaca. |

---

## 2. Design Tokens (Warna & Tipografi)

### A. Tema Gelap (Dark Mode)
- **Background Utama (Scaffold)**: `#0B0F19` (Dark Navy - bukan hitam pekat agar mata rileks).
- **Surface / Card**: `#1A1F2E` (abu-abu kebiruan gelap).
- **Elevasi Card (Shadow)**: Tidak pakai shadow di dark mode, pakai **border** halus `#2A3142` untuk membedakan layer.
- **Teks Utama**: `#F1F5F9` (Putih kebiruan).
- **Teks Sekunder (Hint/Label)**: `#94A3B8` (Abu-abu slate).

### B. Tema Terang (Light Mode)
- **Background Utama (Scaffold)**: `#F8FAFC` (Off-white / Abu-abu sangat terang - bukan putih `#FFF` agar tidak menyilaukan).
- **Surface / Card**: `#FFFFFF` (Putih bersih) dengan **bayangan (Shadow)** level 2 (`offset: 0,4, blur:12, opacity: 0.05`).
- **Teks Utama**: `#0F172A` (Hitam pekat kebiruan).
- **Teks Sekunder**: `#475569` (Abu-abu slate gelap).

### C. Warna Aksen (Primary - Berlaku untuk Kedua Mode)
- **Primary (Tombol Utama)**: `#6366F1` (Indigo).
- **Primary Hover / Disabled**: `#818CF8` (Indigo terang).
- **Success (Top-up/Saldo masuk)**: `#10B981` (Emerald).
- **Error (Password salah/Saldo gagal)**: `#EF4444` (Merah, gunakan hanya untuk pesan error).

### D. Tipografi (Font)
- **Font Family**: **Inter** atau **Roboto** (font standar yang sudah ada di Flutter). Hindari font unik yang ribet.
- **Skala Ukuran (Spacing)**: 
  - Headline (Judul Halaman): `24px / Bold / Height 1.2`
  - Subtitle: `16px / SemiBold / Height 1.4`
  - Body (Isi teks / Label input): `14px / Regular / Height 1.5`
  - Caption (Versi app / Hints): `12px / Regular / Height 1.4`

---

## 3. Tampilan 1: "Selamat Datang" (Welcome / Splash Screen)

**Tujuan**: Menyambut pengguna dan memberikan identitas visual aplikasi.

### Layout (Center Align Vertikal & Horizontal)
1. **Header (Logo & Nama Aplikasi)**: 
   - Di tengah atas (40% tinggi layar).
   - Gunakan asset logo `.png` dengan ukuran `128x128`.
   - Di bawah logo: Teks **"Kantin Digital"** (`size: 28, Bold, Primary Color`).
   - Di bawahnya: Teks **"v2.0 by Nebula Labs"** (`size: 14, Sekunder Color`).

2. **Footer (Tombol Aksi)**:
   - Di bagian bawah (40% tinggi layar).
   - Tombol **"Mulai"** (atau "Masuk") dengan lebar penuh (`double.infinity`), tinggi `56px`, warna Primary, teks putih, radius `16px`.
   - Di bawah tombol: Teks kecil "Keamanan data dienkripsi" dengan icon gembok kecil.

### Perbedaan Dark vs Light di Tampilan ini:
- **Dark**: Background mengapung (tanpa shadow), elemen menggunakan warna solid `#1A1F2E` untuk pemisah.
- **Light**: Background menggunakan warna `#FFFFFF` dengan bayangan halus di sekitar card (jika ada card).

### 🚫 Larangan (Biarkan tidak seperti AI):
- Jangan tambahkan animasi bintang berkedip yang ramai.
- Jangan pakai background gradien biru ke ungu di seluruh layar.

---

## 4. Tampilan 2: "Login" (Autentikasi)

**Tujuan**: Form masuk yang aman dan cepat untuk 5 role (Siswa, Petugas, Admin, dll).

### Layout (Responsive - Card di Tengah)
- **Untuk Mobile**: Kartu login memakan `90%` lebar layar.
- **Untuk Web/Tablet**: Kartu login memakan `40%` lebar layar (maks 400px), diposisikan di tengah layar.

### Komponen di Dalam Card Login:
1. **Header Card**:
   - Teks "Selamat Datang Kembali" (size: 20, Bold).
   - Teks "Masukkan NISN / Email dan password Anda" (size: 14, Sekunder).

2. **Input Field 1 (Identifier/NISN/Email)**:
   - Label: "NISN / Email".
   - Prefix Icon: `Icons.person_outline`.
   - Hint Text: "contoh@sekolah.id atau 12345".
   - **Perbedaan Mode**: Di Dark, background input `#2A3142` dengan border `#3B4459`. Di Light, background input `#F1F5F9` dengan border `#E2E8F0`.

3. **Input Field 2 (Password)**:
   - Label: "Kata Sandi".
   - Prefix Icon: `Icons.lock_outline`.
   - Suffix Icon: Toggle visibility (buka/tutup mata).
   - Hint Text: "Minimal 6 karakter".

4. **Baris Bantuan (Row)**:
   - Kiri: Checkbox "Ingat saya" (ukuran kecil).
   - Kanan: Tombol teks "Lupa Password?" (warna Primary, tanpa background).

5. **Tombol Login**:
   - Teks: "Masuk".
   - Status: Jika loading, tampilkan `CircularProgressIndicator` di dalam tombol (tombol menjadi `disabled`).
   - Efek: saat ditekan, terjadi *splash* highlight (bawaan Material).

6. **Footer Card**:
   - Teks kecil: "Dilindungi oleh Supabase SSL" dengan icon badge.

### Perbedaan Dark vs Light di Tampilan ini:
- **Dark Mode Card**: Background `#1A1F2E` dengan border `#2A3142`, tidak ada shadow.
- **Light Mode Card**: Background `#FFFFFF` dengan shadow `BoxShadow(blurRadius: 24, color: #0000001A)`.

---

## 5. Panduan Kode untuk Gemini (Cara Implementasi di Flutter)

Agar Gemini bisa mengeksekusi ini dengan tepat, ikuti logika kode berikut:

### A. Persiapan Theme (di `core/theme/app_theme.dart`)
Buat 2 fungsi `ThemeData`:
```dart
static ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF6366F1),
  scaffoldBackgroundColor: const Color(0xFFF8FAFC),
  cardColor: const Color(0xFFFFFFFF),
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF10B981),
    error: Color(0xFFEF4444),
  ),
  // Terapkan TextTheme, InputDecorationTheme, dan ElevatedButtonTheme di sini.
);

static ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF6366F1),
  scaffoldBackgroundColor: const Color(0xFF0B0F19),
  cardColor: const Color(0xFF1A1F2E),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF6366F1),
    secondary: Color(0xFF10B981),
    error: Color(0xFFEF4444),
  ),
);