# 📝 PROMPT PANDUAN PENGEMBANGAN DIAGRAM — SISTEM KANTIN DIGITAL

Gunakan dokumen spesifikasi ini sebagai instruksi (prompt) lengkap bagi AI Diagram Builder (seperti Draw.io AI, Mermaid, atau PlantUML) untuk merancang, meregenerasi, atau menyelaraskan semua diagram sistem. Dokumen ini memastikan **konsistensi objek 100%** di seluruh diagram sehingga tidak ada inkonsistensi nama tabel, aktor, atau alur layar.

---

## 🏛️ 1. INFORMASI UMUM SISTEM & KONSISTENSI DATA

Sistem yang dibangun adalah **Sistem Kantin Digital** berbasis **Flutter (Mobile & Web)** dan **Supabase (PostgreSQL Cloud Backend)** dengan fitur pembayaran utama menggunakan kartu **RFID/NFC (Tap-to-Pay)**.

### A. Daftar Aktor & Peran (Harus Konsisten di Diagram 01, 04, 06, 07, 08, 11)
1.  **Siswa**: Memiliki kartu NFC, login ke Mobile App untuk cek saldo, riwayat belanja, dan menerima notifikasi jajan.
2.  **Orang Tua**: Tanpa akun (akses web publik menggunakan NIS anak) untuk top-up saldo via Midtrans.
3.  **Petugas Kantin**: Kasir stan kantin. Menggunakan POS Mobile App untuk memilih menu jajan, scan kartu NFC siswa, dan mengelola stok stan.
4.  **Admin Keuangan**: Staf sekolah (koperasi/tata usaha). Menggunakan Web Admin untuk menginput top-up tunai, koreksi saldo, dan melihat laporan.
5.  **Super Admin**: Mengelola master data sekolah, akun petugas/admin, dan memantau live audit logs untuk pencegahan korupsi.

### B. Skema Database & Model Kelas (Harus Konsisten di Diagram 02 & 03)
*Semua nama kelas pada Class Diagram (PascalCase) harus tepat berkorespondensi dengan nama tabel pada ERD (snake_case).*

1.  **User / `users`**: Menyimpan kredensial login.
    *   Kolom: `id` (PK, UUID), `email` (UK), `password_hash`, `full_name`, `role` (enum: `super_admin`, `admin_keuangan`, `siswa`, `petugas_kantin`), `is_active`, `created_at`.
2.  **School / `schools`**: Data sekolah (sistem mendukung multi-sekolah).
    *   Kolom: `id` (PK, UUID), `name`, `address`, `logo_url`, `is_active`, `created_at`.
3.  **Student / `students`**: Profil siswa, terhubung ke user dan sekolah.
    *   Kolom: `id` (PK, UUID), `user_id` (FK to `users`), `school_id` (FK to `schools`), `nis` (UK), `balance` (numeric, check balance >= 0), `card_uid` (UK, RFID/NFC UID), `is_card_frozen`, `is_active`.
4.  **CanteenOperator / `canteen_operators`**: Penjual/operator stan kantin.
    *   Kolom: `id` (PK, UUID), `user_id` (FK to `users`), `school_id` (FK to `schools`), `stall_name`, `is_active`.
5.  **Product / `products`**: Menu makanan/minuman yang dijual oleh operator stan.
    *   Kolom: `id` (PK, UUID), `canteen_operator_id` (FK to `canteen_operators`), `name`, `price`, `image_url`, `is_available`.
6.  **Transaction / `transactions`**: Riwayat keluar masuk keuangan siswa.
    *   Kolom: `id` (PK, UUID), `student_id` (FK to `students`), `type` (enum: `topup_online`, `topup_cash`, `purchase`, `refund`, `adjustment`), `amount`, `performed_by` (FK to `users`), `method` (enum: `midtrans`, `cash`, `nfc_tap`, `manual`), `status` (enum: `pending`, `success`, `failed`, `refunded`), `notes` (alasan jika adjustment/koreksi), `created_at`.
7.  **TransactionItem / `transaction_items`**: Detail makanan/minuman yang dibeli dalam satu transaksi belanja.
    *   Kolom: `id` (PK, UUID), `transaction_id` (FK to `transactions`), `product_id` (FK to `products`), `name` (snap harga saat beli), `price`, `quantity`, `subtotal`.
8.  **AuditLog / `audit_logs`**: Log audit ketat untuk melacak aksi manual Admin Keuangan.
    *   Kolom: `id` (PK, UUID), `user_id` (FK to `users`), `action`, `target_table`, `target_id` (UUID), `old_value` (JSONB), `new_value` (JSONB), `ip_address`, `created_at`.

---

## 🎨 2. PANDUAN WARNA & TATA LETAK DIAGRAM (VISUAL SPECIFICATIONS)

Untuk menjamin estetika premium dan konsistensi visual, semua diagram wajib mengikuti palet warna berikut:
*   🔵 **Siswa / Orang Tua**: Kode warna `#DAE8FC` (Biru Lembut), border `#6C8EBF`.
*   🟡 **Petugas Kantin (Kasir)**: Kode warna `#FFE6CC` (Kuning/Orange Lembut), border `#D79B00`.
*   🟢 **Admin Keuangan**: Kode warna `#D5E8D4` (Teal Lembut), border `#72B095`.
*   🟢 **Sistem / Database / Backend**: Kode warna `#E6F2F2` (Teal Tua Lembut), border `#0E8A8A`.
*   🔴 **Error / Transaksi Ditolak**: Kode warna `#FED7D7` (Merah Lembut), border `#E53E3E`.

---

## 📊 3. SPESIFIKASI RINCI UNTUK 11 DIAGRAM

### 🗺️ Diagram 01: Activity Diagram (Alur Kerja Operasional)
*   **Swimlanes (3 Kolom)**: `Siswa / Orang Tua` | `Petugas Kantin` | `Admin Keuangan`.
*   **Alur Logis (Non-Paralel)**: Dimulai dari satu Start Node, mengalir ke diamond "Pilih Aksi / Jalur transaksi":
    1.  **Jalur Top-up Online**: Siswa/Ortu bayar via App -> Pembayaran Midtrans -> DB Update Saldo & Notif -> End Node.
    2.  **Jalur Belanja NFC**: Siswa tap kartu NFC -> Petugas pilih menu POS & scan NFC -> Backend validasi saldo -> Jika Saldo Cukup: Potong saldo DB, notif sukses ke siswa, transaksi selesai. Jika Saldo Kurang: Layar POS merah (ditolak), transaksi selesai.
    3.  **Jalur Admin Keuangan (Sejajar horizontal di kolom Admin)**:
        *   Cabang A: **Top-up Tunai** -> Terima uang tunai -> Input nominal & NIS -> Simpan ke DB & Audit Log -> End Node.
        *   Cabang B: **Koreksi Saldo** -> Input nominal & alasan wajib -> Simpan ke DB & Audit Log -> End Node.
    *   *PENTING*: Pastikan garis alur Top-up Tunai dan Koreksi Saldo keluar dari sisi kanan diamond Pilih Aksi, lalu naik secara horizontal sebelum ke kanan, agar **tidak menimpa** garis vertikal Start Node.

### 📐 Diagram 02: Class Diagram
*   Gambarkan 8 kelas (`User`, `School`, `Student`, `CanteenOperator`, `Product`, `Transaction`, `TransactionItem`, `AuditLog`) lengkap dengan tipe atributnya dan 4 enums (`UserRole`, `TxType`, `TxMethod`, `TxStatus`).
*   Gunakan warna header Indigo (`#4F46E5`) untuk kelas biasa dan Orange (`#ED8936`) untuk enum.
*   Tunjukkan relasi kardinalitas: `User (1) -- (0..1) Student`, `Student (1) -- (*) Transaction`, `Transaction (1) -- (*) TransactionItem`, dll.

### 🗄️ Diagram 03: ER Diagram (Entity Relationship Diagram)
*   Gambarkan 8 tabel database PostgreSQL secara detail dengan notasi Crow's Foot.
*   Header tabel berwarna Orange Database (`#ED8936`).
*   Gunakan penanda kunci yang jelas: `* id : UUID <<PK>>`, `* user_id : UUID <<FK>>`, `* email : VARCHAR <<UK>>`.

### 🔄 Diagram 04: Sequence Diagram (Validasi Pembayaran NFC)
*   **Lifelines (3 Aktor/Sistem)**: `Siswa (Kartu NFC)` (Biru) | `App POS Mobile (Kasir)` (Kuning) | `Supabase Database (Backend)` (Teal).
*   **Alur Pesan**:
    1.  Siswa tap kartu -> POS App read UID.
    2.  POS App query saldo ke Database -> DB return nama & saldo terbaru.
    3.  POS App melakukan pengecekan saldo lokal (Jika saldo cukup -> Lanjut ke stored procedure transaksi).
    4.  POS App mengirim request `Jalankan Transaksi (ACID)` ke DB.
    5.  DB memvalidasi harga asli produk secara server-side (anti-hack), mengurangi saldo, mencatat riwayat transaksi, lalu mengembalikan status sukses.
    6.  POS App bergetar & menampilkan centang hijau. DB mengirim notifikasi push secara real-time ke HP Siswa.

### 📅 Diagram 05: Timeline (Roadmap Agile 6 Minggu)
*   Diagram Gantt Chart Agile Roadmap dengan skala mingguan (weekly).
*   **Sprint 1 (W01-W02)**: `Planning & DB Setup` (Blue), `Setup Supabase Schema + RLS` (Orange), `Auth & Multi-Role Routing` (Green).
*   **Sprint 2 (W03-W04)**: `POS Catalog & Cart UI` (Orange), `NFC Tap Checkout Core` (Blue).
*   **Sprint 3 (W05-W06)**: `Midtrans Integration` (Purple), `Push Notification & Reports` (Orange), `QA, Polish & Deploy` (Green).

### 🎭 Diagram 06: Use Case Diagram
*   **Aktor**: `Siswa` (Biru), `Orang Tua` (Biru), `Petugas Kantin` (Kuning), `Admin Keuangan` (Teal), `Super Admin` (Gray).
*   Gambarkan batas sistem (System Boundary Box) putus-putus.
*   Hubungkan aktor ke 10 Use Case utama yang dikelompokkan dengan warna yang sama dengan aktor penanggung jawabnya.

### 🌐 Diagram 07: Context Diagram (DFD Level 0)
*   Gambarkan aktor sebagai bentuk stick-figure **UML Actor** dan sistem pusat sebagai **Double Ellipse** (DFD standar).
*   **PENTING**: Hubungkan tiap aktor ke sistem pusat menggunakan **satu garis panah dua arah (bidirectional arrow)** untuk mencegah penumpukan kabel.
*   Labeli garis dengan format: `In: [aliran data masuk] \n Out: [aliran data keluar]` (misal: `In: Req Jajan / UID NFC \n Out: Info Saldo, Notifikasi`).

### 🏗️ Diagram 08: Architecture Diagram (Tiga Tingkat)
*   **Client Tier (Box Atas)**: `Siswa App` (Biru), `Petugas App` (Kuning), `Admin Web` (Teal), `ESP32 Hardware` (Abu-abu).
*   **Backend Tier (Box Tengah)**: `Supabase Auth`, `Edge Functions (Midtrans Webhook)`, `Realtime Channel`, dan `PostgreSQL Database` (Teal).
*   **Third-Party Tier (Box Bawah)**: `Midtrans Payment Gateway`, `Firebase Cloud Messaging (FCM)`.
*   Tunjukkan garis koneksi HTTPS, REST API, Webhook, dan Push Notifications antar komponen.

### 🔄 Diagram 09: Agile Development Method (Scrum Flow)
*   Gambarkan siklus pengembangan Agile Scrum:
    `Product Backlog` -> `Sprint Planning` -> `Sprint Backlog` -> `Sprint Cycle (2 Minggu)` <-> `Daily Standup` -> `Working App Increment` -> `Sprint Review & Retrospective` -> Loop kembali ke `Sprint Planning`.
*   *PENTING*: Hubungan timbal-balik antara `Sprint Cycle` dan `Daily Standup` harus berupa satu garis panah dua arah (`Daily Sync`) agar tidak terjadi garis tumpang tindih.

### 🗺️ Diagram 10: System Features Map (Mindmap Fitur)
*   Gambarkan Mindmap dengan node pusat `FITUR UTAMA KANTIN DIGITAL`.
*   Cabangkan ke 5 modul utama (Siswa Mobile, Kasir Mobile, Admin Web, Master Admin Web, Orang Tua Web), di mana masing-masing modul memiliki daftar sub-fitur spesifiknya (sesuai dokumen `06-fitur-per-platform.md`).
*   Gunakan pewarnaan box visual yang seragam per modul.

### 🛣️ Diagram 11: Workflow Navigation (Screen Sitemap)
*   Tunjukkan alur layar (sitemap navigasi) untuk 3 platform berbeda dalam bentuk box container putus-putus:
    1.  **Siswa App**: `Login Screen` -> `Dashboard` -> `Top-up Grid` -> `Midtrans Snap Webview` | `History Screen` | `Profile Screen`.
    2.  **Petugas App**: `Login` -> `POS Catalog` -> `Cart Screen` -> `NFC Pay Modal` | `Menu CRUD Screen` | `Cek Saldo Screen`.
    3.  **Admin Web**: `Web Login` -> `Dashboard Summary` -> `Top-up Tunai TU` | `Koreksi Saldo Form` | `Audit Logs Viewer` | `Manage Siswa & Kartu`.
*   *PENTING*: Garis navigasi dari `Dashboard`/`POS Catalog` ke layar di bawahnya **tidak boleh ditarik lurus ke bawah menembus box lain**. Garis tersebut harus dibelokkan memutari box perantara lewat margin kiri dan kanan (`edgeStyle=orthogonalEdgeStyle` dengan koordinat belokan yang ditentukan).
