# 👥 Aktor & Hak Akses

## Daftar Aktor

| # | Aktor | Platform | Login? | Deskripsi |
|---|---|---|---|---|
| 1 | **Super Admin** | Web Admin | Ya (akun) | Mengelola seluruh sistem |
| 2 | **Admin Keuangan** | Web Admin + Mobile | Ya (akun) | Mengelola keuangan & top-up |
| 3 | **Siswa** | Mobile App | Ya (akun) | Lihat saldo & riwayat |
| 4 | **Petugas Kantin** | Mobile App / ESP32 | Ya (akun) | Kurangi saldo saat pembelian |
| 5 | **Orang Tua** | Web Publik | Tidak (pakai ID siswa) | Top-up & cek saldo anak |

---

## Detail Hak Akses

### 1. Super Admin
Mengelola keseluruhan sistem. Bisa melihat semua log aktivitas untuk mencegah korupsi.

**Kemampuan:**
- Login / Logout
- Tambah & kelola **role** (Admin Keuangan, Petugas Kantin)
- Kelola data **sekolah** (untuk multi-sekolah di masa depan)
- Kelola data **siswa** (CRUD)
- Kelola data **petugas kantin** (CRUD)
- Kelola data **admin keuangan** (CRUD)
- Lihat **semua transaksi** seluruh sistem
- Lihat **audit log** — semua aksi admin keuangan tercatat
- Lihat **laporan & statistik** keseluruhan
- Export laporan (PDF/Excel)
- Pengaturan sistem global

### 2. Admin Keuangan
Mengelola keuangan harian. **Setiap aksi tercatat di audit log** yang bisa dilihat Super Admin.

**Kemampuan:**
- Login / Logout
- **Top-up saldo** siswa (tunai dari guru/koperasi)
- **Kurangi saldo** siswa (koreksi jika ada kesalahan)
- Verifikasi pembayaran online (Midtrans)
- Lihat data siswa & saldo
- Lihat **riwayat transaksi** yang dia lakukan
- Lihat **laporan keuangan** (harian/mingguan/bulanan)
- Export laporan

> ⚠️ Semua aksi top-up & pengurangan saldo oleh Admin Keuangan **selalu tercatat** di audit log — siapa, kapan, berapa, untuk siapa.

### 3. Siswa
Pengguna utama kartu RFID/NFC.

**Kemampuan:**
- Register & Login
- Lihat **saldo** saat ini
- Lihat **riwayat transaksi** (pembelian & top-up)
- Lihat **detail transaksi** per item
- Lihat **history** lengkap
- Link/unlink **kartu NFC** ke akun
- Edit profil & ubah password
- Terima **notifikasi** setiap ada transaksi

> 💡 Orang tua bisa login menggunakan **akun siswa** di app untuk top-up.

### 4. Petugas Kantin (Bude Kantin)
Operator di kantin yang melayani pembelian dan mengelola menu makanannya.

**Kemampuan:**
- Login (akun petugas)
- **Manajemen Produk**: Tambah produk/menu makanan, edit harga produk, dan hapus/nonaktifkan produk.
- **Transaksi Berbasis Keranjang (Cart)**: Memilih menu makanan/minuman yang dibeli siswa dari list produk (menghindari kesalahan ketik harga).
- **Aksi Biaya Kustom (Custom Charge)**: Menambahkan biaya kustom (misal: ekstra porsi, tambahan telur) dengan **kewajiban menulis catatan/keterangan**.
- **Tap kartu NFC** → lihat profil siswa + proses potong saldo sesuai total keranjang belanja.
- **Cek saldo** siswa (tap kartu tanpa transaksi).
- Lihat **riwayat transaksi hari ini** yang dia lakukan.
- Lihat **total pendapatan hari ini**.

**TIDAK BISA:**
- ❌ Top-up saldo.
- ❌ Lihat data siswa selain nama & saldo.
- ❌ Akses dashboard admin keuangan sekolah / super admin.

### 5. Orang Tua (Tanpa Akun)
Akses terbatas via web publik, tanpa perlu registrasi.

**Kemampuan:**
- Masukkan **ID siswa** di web → lihat saldo anak
- Lihat **5 transaksi terakhir** anak
- **Top-up online** via Midtrans (bayar dari mana saja)
- Download/screenshot **bukti top-up**

**Alternatif akses:**
- Login pakai **akun siswa** di mobile app → bisa top-up juga
- Datang ke **guru/koperasi** → top-up tunai (diinput Admin Keuangan)

---

## Ringkasan Permissions

| Aksi | Super Admin | Admin Keuangan | Siswa | Petugas Kantin | Orang Tua |
|---|:---:|:---:|:---:|:---:|:---:|
| Kelola user & role | ✅ | ❌ | ❌ | ❌ | ❌ |
| Top-up saldo | ✅ | ✅ | ❌ | ❌ | ✅ (online) |
| Kurangi saldo (koreksi) | ✅ | ✅ | ❌ | ❌ | ❌ |
| Kurangi saldo (pembelian) | ❌ | ✅ | ❌ | ✅ | ❌ |
| Lihat saldo sendiri | — | — | ✅ | ❌ | ✅ (by ID) |
| Lihat semua transaksi | ✅ | Miliknya | Miliknya | Miliknya | 5 terakhir |
| Audit log | ✅ | ❌ | ❌ | ❌ | ❌ |
| Laporan & export | ✅ | ✅ | ❌ | ❌ | ❌ |
| NFC tap (beli) | ❌ | ❌ | — (tap kartu) | ✅ | ❌ |
| Notifikasi | ✅ | ✅ | ✅ | ❌ | ❌ |
