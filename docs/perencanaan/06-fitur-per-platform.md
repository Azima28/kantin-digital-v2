# 📱 Fitur per Platform — Sistem Kantin Digital

Dokumen ini menjabarkan spesifikasi fitur untuk masing-masing platform dan aktor di dalam Sistem Kantin Digital.

---

## 6.1 Mobile App (Flutter) — Versi Siswa & Orang Tua

Siswa atau orang tua yang menggunakan smartphone (Android/iOS) memiliki fitur-fitur berikut:

| Fitur | Deskripsi | Prioritas |
|---|---|---|
| **Dashboard Utama** | Menampilkan saldo aktif saat ini, ringkasan pengeluaran hari ini, serta akses cepat ke menu utama. | P0 (Kritis) |
| **Riwayat Transaksi** | Daftar transaksi masuk (top-up) dan keluar (belanja) dengan status sukses/pending, dilengkapi filter tanggal & jenis transaksi. | P0 (Kritis) |
| **Detail Transaksi** | Menampilkan info detail nominal, waktu, stan kantin (jika belanja), atau metode pembayaran (jika top-up). | P1 (Penting) |
| **Top-up Online** | Layar pembuatan invoice pembayaran dengan memilih nominal, disambungkan ke Midtrans SDK/Webview (Virtual Account, E-Wallet, QRIS). | P0 (Kritis) |
| **Kartu Saya & NFC** | Menampilkan kartu RFID/NFC yang terhubung ke akun siswa. Siswa dapat menonaktifkan kartu sementara (Freeze) jika kartu hilang. | P1 (Penting) |
| **Profil Akun** | Pengaturan informasi dasar siswa (foto, password, email/nomor telepon orang tua). | P2 (Tambahan) |
| **Notifikasi Real-time** | Menerima push notification instan via FCM setiap kali kartu di-tap di kantin atau setelah top-up sukses. | P1 (Penting) |

## 6.2 Mobile App (Flutter) — Versi Petugas Kantin

Dirancang khusus untuk operasional kasir warung di kantin sekolah dengan UI yang cepat, berbasis katalog produk, dan meminimalisir kesalahan ketik nominal belanja.

| Fitur | Deskripsi | Prioritas |
|---|---|---|
| **Tap & Pay (Kasir)** | Layar utama yang mendeteksi NFC kartu siswa secara otomatis, lalu menampilkan nama & foto siswa, meminta petugas memasukkan total belanjaan, mengonfirmasi transaksi, dan memotong saldo. | P0 (Kritis) |
| **Cek Saldo Cepat** | Menggunakan NFC HP untuk membaca UID kartu siswa dan hanya menampilkan sisa saldo tanpa memproses belanjaan. | P0 (Kritis) |
| **Riwayat Penjualan Hari Ini** | Menampilkan daftar transaksi belanja siswa yang dilakukan di stan tersebut pada hari ini. | P0 (Kritis) |
| **Total Pendapatan** | Ringkasan akumulasi uang masuk (pendapatan bersih stan) hari ini yang akan dicairkan oleh Admin Keuangan. | P1 (Penting) |

---

## 6.3 Web Admin — Versi Super Admin

Situs web dashboard internal untuk dinas pendidikan atau yayasan sekolah (terpisah secara URL dari web publik).

| Fitur | Deskripsi | Prioritas |
|---|---|---|
| **Executive Dashboard** | Ringkasan total sekolah, total siswa aktif, total perputaran saldo digital, total transaksi harian, dan grafik tren pengeluaran global. | P1 (Penting) |
| **Manajemen Sekolah** | CRUD (Create, Read, Update, Delete) sekolah yang berpartisipasi dalam sistem kantin digital. | P1 (Penting) |
| **Manajemen Pengguna** | Mengelola akun Super Admin, Admin Keuangan, Petugas Kantin, dan Siswa secara keseluruhan. | P0 (Kritis) |
| **Manajemen Role & Hak Akses** | Mengubah otorisasi sistem dan hak akses fitur per role. | P2 (Tambahan) |
| **Audit Log Explorer** | Layar pemantauan aktivitas keuangan manual yang dilakukan oleh Admin Keuangan untuk memantau integritas data saldo. | P0 (Kritis) |
| **Sistem Laporan Global** | Menghasilkan laporan dan melakukan ekspor data (PDF, Excel, CSV) dari seluruh transaksi sekolah. | P1 (Penting) |

---

## 6.4 Web Admin — Versi Admin Keuangan (Sekolah)

Digunakan oleh staf tata usaha, koperasi, atau bendahara sekolah di dashboard web yang sama dengan Super Admin, namun dengan hak akses terbatas sesuai sekolahnya.

| Fitur | Deskripsi | Prioritas |
|---|---|---|
| **Dashboard Keuangan** | Ringkasan uang tunai yang diterima hari ini, pengajuan top-up manual, dan total kas sekolah. | P0 (Kritis) |
| **Top-up Manual (Tunai)** | Input NIS/ID Siswa, verifikasi profil siswa, lalu memasukkan nominal uang tunai yang diserahkan untuk dikonversi menjadi saldo digital. | P0 (Kritis) |
| **Koreksi Saldo (Adjusment)** | Mengoreksi kesalahan nominal saldo siswa atas persetujuan khusus (setiap aksi terikat ketat ke Audit Log). | P1 (Penting) |
| **Verifikasi Pembayaran** | Meninjau status transaksi pembayaran online (Midtrans) yang membutuhkan validasi manual jika terjadi anomali. | P2 (Tambahan) |
| **Registrasi Kartu Siswa** | Menghubungkan UID kartu RFID/NFC fisik baru ke akun siswa menggunakan USB RFID reader atau input manual UID. | P0 (Kritis) |
| **Laporan Kas Sekolah** | Cetak dan unduh laporan kas kantin, riwayat top-up tunai, dan penjualan per stan kantin di sekolah tersebut. | P0 (Kritis) |

---

## 6.5 Web Publik — Versi Orang Tua (Tanpa Login)

Halaman web landing page publik yang dapat diakses oleh orang tua tanpa perlu registrasi akun atau login aplikasi.

| Fitur | Deskripsi | Prioritas |
|---|---|---|
| **Cek Saldo Cepat** | Cukup masukkan kode unik / ID Siswa (NIS) untuk melihat nama siswa dan sisa saldo saat ini. | P0 (Kritis) |
| **Riwayat Singkat** | Menampilkan 5 transaksi belanja terakhir siswa untuk memantau jajanan anak secara transparan. | P1 (Penting) |
| **Top-up Online Instan** | Masukkan nominal top-up, masukkan nama pembayar (orang tua), lalu sistem membuka widget Midtrans Snap untuk pembayaran online (QRIS/VA). | P0 (Kritis) |
| **E-Receipt (Bukti Bayar)** | Unduh bukti pembayaran dalam format PDF atau gambar setelah top-up sukses. | P1 (Penting) |
