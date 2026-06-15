# 🏫 Overview — Sistem Kantin Digital

## Nama Project
**Sistem Kantin Digital** — RFID/NFC + Flutter

## Misi
Menggantikan uang saku tunai dengan saldo digital terkontrol melalui kartu RFID/NFC.

## Masalah yang Dipecahkan
- Siswa membawa uang tunai → rawan hilang/jajan berlebihan
- Orang tua tidak bisa kontrol pengeluaran anak di sekolah
- Transaksi kantin tidak tercatat → tidak transparan

## Solusi
- Menggunakan **kartu RFID/NFC** sebagai alat transaksi siswa
- Orang tua **top-up saldo** via app/web/tunai
- Siswa **tap kartu** saat membeli di kantin
- Saldo **otomatis terpotong** dari database
- **Semua transaksi tercatat** — transparan & terkontrol

## Manfaat
- ✅ Mengurangi penggunaan uang tunai di sekolah
- ✅ Membantu orang tua mengontrol pengeluaran anak
- ✅ Meningkatkan keamanan transaksi
- ✅ Menciptakan sistem sekolah yang modern dan transparan
- ✅ Anti-korupsi: semua aksi admin tercatat di audit log

## Flow Utama
```
Orang Tua top-up saldo
    ↓
Siswa tap kartu RFID/NFC di kantin
    ↓
Petugas kantin input nominal pembelian
    ↓
Saldo otomatis terpotong + transaksi tercatat
    ↓
Orang tua bisa pantau pengeluaran anak
```

## Catatan
- Saldo tersimpan 100% di **database** (bukan di kartu)
- Kartu hanya menyimpan **UID** (ID unik) sebagai identitas
- Top-up bisa dilakukan melalui: guru, koperasi, atau online (Midtrans)
