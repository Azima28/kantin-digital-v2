# 🔄 Alur Sistem (Flow) — Sistem Kantin Digital

Dokumen ini menjelaskan alur kerja utama (workflow) dari sistem kantin digital, termasuk top-up saldo, transaksi di kantin, dan pencatatan audit log untuk mencegah penyalahgunaan.

---

## 4.1 Alur Top-Up Saldo

Top-up saldo siswa dapat dilakukan melalui tiga jalur berbeda sesuai dengan kebutuhan orang tua dan siswa:

```mermaid
graph TD
    Ortu[Orang Tua / Siswa] --> Choose{Pilih Metode}
    
    Choose -->|A. Via Mobile App| App[Login Akun Siswa di App]
    Choose -->|B. Via Web Publik| Web[Input ID Siswa di Web]
    Choose -->|C. Via Sekolah/Koperasi| Cash[Bayar Tunai ke Koperasi]

    App --> PG[Midtrans Payment Gateway]
    Web --> PG
    Cash --> Admin[Admin Keuangan Input Manual]

    PG -->|Pembayaran Berhasil| DB[Update Database]
    Admin -->|Simpan Transaksi| DB

    DB -->|1. Saldo Siswa bertambah| Finish[Selesai]
    DB -->|2. Transaksi topup tersimpan| Finish
    DB -->|3. Push Notification kirim| Finish
```

### Penjelasan Detil Jalur Top-up:
1. **Via Mobile App**: Siswa atau orang tua login ke aplikasi, pilih nominal top-up, dan melakukan pembayaran instan di dalam app menggunakan Midtrans (E-Wallet, VA Bank, QRIS).
2. **Via Web Publik (Orang Tua)**: Orang tua mengakses situs web top-up tanpa login, memasukkan ID Siswa (NIS/Student ID Code), memverifikasi nama siswa yang muncul, lalu membayar via Midtrans.
3. **Via Guru/Koperasi (Tunai)**: Siswa membawa uang tunai ke koperasi sekolah atau guru penanggung jawab. Admin Keuangan menerima uang tunai dan menginput top-up secara manual ke sistem melalui Web Admin.

---

## 4.2 Alur Transaksi di Kantin

Transaksi di kantin dirancang agar berjalan sangat cepat dan memiliki validasi saldo berlapis di sisi database server untuk mencegah kecurangan (hacking saldo lokal di client).

```mermaid
sequenceDiagram
    actor Siswa as Siswa (Kartu RFID/NFC)
    actor Kantin as Petugas Kantin (App POS Mobile)
    participant DB as Supabase DB
    
    Note over Kantin: Petugas memilih item produk<br/>ke keranjang belanja (Cart)
    Siswa->>Kantin: Tap Kartu RFID/NFC
    Kantin->>DB: Kirim request baca UID Kartu
    DB-->>Kantin: Kembalikan Nama Siswa & Saldo Teraktual dari DB
    
    Note over Kantin: Aplikasi mencocokkan Saldo vs Total Keranjang
    ALT Saldo Kurang (Saldo < Total Keranjang)
        Note over Kantin: UI berubah Merah & Tombol Terkunci
        Kantin-->>Siswa: Transaksi Ditolak (Saldo Kurang)
    ELSE Saldo Cukup (Saldo >= Total Keranjang)
        Kantin->>DB: Kirim data transaksi (student_id, item list, total belanja)
        Note over DB: Server-Side Validation:<br/>1. Query saldo riil teraktual<br/>2. Cek apakah saldo >= total belanja riil<br/>3. Jalankan transaksi database (ACID)
        ALT Verifikasi Server Sukses
            DB->>DB: Potong saldo di DB & simpan ke `transactions` & `transaction_items`
            DB-->>Kantin: Transaksi Sukses & Saldo Sisa
            Kantin-->>Siswa: Berikan Makanan / Struk (optional)
            DB-->>Siswa: Kirim Push Notification ke HP Siswa
        ELSE Verifikasi Server Gagal (Data Tampered / Hack)
            DB-->>Kantin: Error: Transaksi Tidak Valid (Ditolak Server)
            Kantin-->>Siswa: Transaksi Dibatalkan
        END
    END
```

> [!CAUTION]
> **Pencegahan Manipulasi Saldo (Anti-Hacking)**:
> Aplikasi client (HP Petugas) **tidak diizinkan** melakukan kalkulasi sisa saldo lalu menyimpannya langsung ke database. Data saldo akhir siswa dihitung sepenuhnya di database server (Supabase PostgreSQL) melalui ACID transaction/stored procedure. Jika data input dari client telah dimanipulasi (misalnya total belanja dikirim lebih murah dari harga riil produk), server akan memvalidasi ulang harga produk dari tabel `products` di backend sebelum memotong saldo. Tabel `students` juga dilengkapi constraint `CHECK (balance >= 0)` untuk menjamin saldo tidak akan pernah menjadi negatif secara tidak sah.

---

## 4.3 Alur Anti-Korupsi & Transparansi (Audit Logs)

Untuk meminimalkan manipulasi saldo oleh Admin Keuangan, setiap perubahan saldo secara manual (di luar payment gateway otomatis) harus dicatat dengan ketat.

```mermaid
graph TD
    Admin[Admin Keuangan] -->|Melakukan Aksi Manual<br/>Topup Tunai / Koreksi Saldo| Action[Sistem Proses Aksi]
    Action --> DB[Update Saldo Siswa]
    Action --> Audit[Simpan Entri di Audit Logs]
    
    Audit -->|Catat detail| LogDetails[
      - Siapa yang melakukan (Admin ID)
      - Kapan (Timestamp)
      - Aksi apa (topup / deduct)
      - Nominal perubahan
      - Siswa target (NIS/ID)
      - IP Address & Device Info
      - Nilai Sebelum vs Sesudah (JSONB)
    ]
    
    LogDetails --> View[Super Admin Monitoring]
    View -->|Tinjau real-time| Alert[Cegah & Deteksi Penyimpangan]
```

> [!IMPORTANT]
> **Row Level Security (RLS)** di Supabase akan dikonfigurasi agar Petugas Kantin dan Admin Keuangan tidak bisa mengedit data tabel `audit_logs`. Tabel ini hanya bersifat *insert-only* bagi sistem dan *read-only* bagi Super Admin.
