# 🔌 Integrasi RFID/NFC — Sistem Kantin Digital

Dokumen ini menjelaskan opsi implementasi teknis integrasi pembaca kartu RFID/NFC fisik dengan aplikasi Flutter Mobile dan perangkat keras eksternal.

---

## 8.1 Arsitektur Pembacaan Kartu

Untuk menjamin keamanan saldo, sistem ini menerapkan prinsip **Database-Centric Security**:
1. **Kartu RFID/NFC fisik hanya digunakan sebagai pengidentifikasi**. Kartu tersebut hanya menyimpan **UID (Unique Identifier)** unik bawaan pabrik (biasanya 4 atau 7 byte hex).
2. **Tidak ada data nominal saldo yang ditulis ke dalam kartu**. Saldo sepenuhnya disimpan di database Supabase (PostgreSQL) yang terlindungi.
3. Hal ini mencegah manipulasi saldo lokal (hacking isi kartu) dan jika kartu hilang, kartu bisa langsung diblokir di sistem tanpa perlu memodifikasi fisik kartu.

---

## 8.2 Opsi Implementasi Hardware

Sistem kantin digital ini mendukung dua metode pembacaan kartu RFID/NFC di lapangan:

### Opsi A: Smartphone Android dengan Built-in NFC (Rekomendasi Kasir Kantin)

Petugas kantin cukup menggunakan smartphone Android yang memiliki fitur NFC untuk menerima transaksi pembayaran dari siswa.

```
┌─────────────────┐             ┌──────────────────┐             ┌────────────────┐
│  Kartu RFID/NFC │  NFC Signal │   HP Android     │  REST/HTTPS │  Database      │
│  (MIFARE / NTAG)├────────────>│  (Flutter App)   ├────────────>│  (Supabase)    │
│  UID: A1-B2-C3  │             │  `nfc_manager`   │             │  Siswa: A1-B2  │
└─────────────────┘             └──────────────────┘             └────────────────┘
```

#### Alur Teknis Flutter:
1. Flutter menggunakan package [`nfc_manager`](https://pub.dev/packages/nfc_manager) untuk berinteraksi dengan sensor NFC HP.
2. Ketika mode kasir aktif, aplikasi mendengarkan (`startSession`) aktivitas NFC.
3. Saat kartu ditempelkan di punggung HP, aplikasi membaca tag UID.
4. UID dikonversi ke format string Hexadecimal (misal: `04:A3:F8:12`).
5. Aplikasi mengirimkan query ke API Supabase `/rest/v1/students?card_uid=eq.04:A3:F8:12` untuk menarik data siswa dan saldo.

---

### Opsi B: ESP32 + RC522 / PN532 Reader (Hardware Khusus)

Jika petugas kantin tidak memiliki smartphone dengan NFC, sekolah dapat merakit perangkat kasir terpisah yang murah menggunakan mikrokontroler.

```
┌───────────────┐           ┌─────────────────┐           ┌──────────────┐
│  Kartu RFID   │ SPI / I2C │     ESP32       │ Wi-Fi / IP  │   Supabase   │
│  (13.56 MHz)  ├──────────>│  (RC522 Reader) ├────────────>│   REST API   │
│               │           │  OLED Display   │             │              │
└───────────────┘           └─────────────────┘             └──────────────┘
```

#### Alur Teknis ESP32:
1. Mikrokontroler **ESP32** dihubungkan ke modul RFID reader **MFRC522** (frekuensi 13.56 MHz) melalui pin bus SPI.
2. ESP32 terkoneksi ke jaringan Wi-Fi sekolah.
3. Saat kartu di-tap, pustaka `<MFRC522.h>` membaca UID kartu.
4. ESP32 mengirimkan request HTTP POST ke endpoint Supabase Edge Function atau REST API dengan menyertakan UID kartu.
5. Supabase memproses transaksi dan mengembalikan response JSON (Nama Siswa, Sisa Saldo, Status Sukses).
6. ESP32 menampilkan status transaksi di layar OLED mini dan membunyikan buzzer (nada tinggi untuk sukses, nada rendah panjang untuk gagal).

---

## 8.3 Pendaftaran Kartu Baru (Link Card)

Agar kartu RFID/NFC dapat digunakan oleh siswa, kartu tersebut harus didaftarkan ke NIS siswa yang bersangkutan:

1. **Oleh Admin Keuangan (Web)**:
   - Admin membuka form edit siswa di Web Admin.
   - Admin dapat mengetik manual nomor UID kartu, atau
   - Menempelkan kartu ke USB RFID reader yang dicolok ke komputer admin, yang bertindak sebagai keyboard input (keyboard emulator) untuk mengisi field UID secara otomatis.
2. **Oleh Siswa/Petugas (App Mobile)**:
   - Menu "Daftarkan Kartu" di aplikasi mobile.
   - Tempelkan kartu baru di sensor NFC HP.
   - Aplikasi membaca UID dan mengirimkan update ke database siswa (`update students set card_uid = ... where id = ...`).
