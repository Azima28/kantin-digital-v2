# 🏗️ Arsitektur & Tech Stack

## Platform

| Platform | Target User | Teknologi |
|---|---|---|
| **Mobile App** (Android + iOS) | Siswa, Petugas Kantin | Flutter |
| **Web Admin** (URL terpisah) | Super Admin, Admin Keuangan | Flutter Web |
| **Web Publik** | Orang Tua | Flutter Web |
| **ESP32 Reader** (opsional) | Petugas Kantin tanpa HP NFC | Arduino/PlatformIO |

## URL Structure

```
📱 MOBILE APP (Flutter)
├── Siswa / Orang Tua    → Play Store / App Store
├── Petugas Kantin        → Mode kasir (NFC tap)
└── Admin Keuangan        → Mobile dashboard (opsional)

🌐 WEB
├── kantin.sekolah.id                → Landing page publik
├── kantin.sekolah.id/topup          → Orang Tua top-up (by ID siswa)
├── kantin.sekolah.id/cek-saldo      → Cek saldo (by ID siswa)
└── admin.kantin.sekolah.id          → Super Admin & Admin Keuangan
```

> ⚠️ Web admin di URL/subdomain **terpisah** dari web publik.

## Arsitektur Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENTS                             │
│                                                          │
│  📱 Flutter Mobile App        🌐 Flutter Web (Admin)    │
│  ├── Siswa/Ortu               ├── Super Admin Dashboard │
│  ├── Petugas Kantin           └── Admin Keuangan        │
│  └── NFC Reader (HP)                                    │
│                                                          │
│  🌐 Flutter Web (Publik)      🔌 ESP32 + RFID Reader   │
│  ├── Top-up by ID             └── Kantin tanpa HP NFC   │
│  └── Cek Saldo                                          │
└────────────────────┬────────────────────────────────────┘
                     │ REST API / Realtime
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  BACKEND (Supabase)                       │
│                                                          │
│  ├── PostgreSQL Database                                 │
│  ├── Auth (email/password)                               │
│  ├── Edge Functions (server-side logic)                  │
│  ├── Realtime Subscriptions (saldo update live)          │
│  ├── Row Level Security (RLS)                            │
│  └── Storage (foto profil, bukti bayar)                  │
│                                                          │
│  Integrasi:                                              │
│  ├── 💳 Midtrans Payment Gateway                        │
│  ├── 🔔 FCM Push Notifications                          │
│  └── 📊 Logging & Analytics                             │
└─────────────────────────────────────────────────────────┘
```

## Tech Stack Detail

| Layer | Teknologi | Keterangan |
|---|---|---|
| **Mobile App** | Flutter (Dart) | Android + iOS dari 1 codebase |
| **Web Admin** | Flutter Web | Codebase sama, responsive layout |
| **Web Publik** | Flutter Web | Landing page + top-up |
| **Backend** | Supabase | BaaS (Backend as a Service) |
| **Database** | PostgreSQL (Supabase) | Relational, ACID, cocok untuk keuangan |
| **Auth** | Supabase Auth | Email/password |
| **Realtime** | Supabase Realtime | Update saldo live |
| **Storage** | Supabase Storage | Foto profil, bukti bayar |
| **Payment** | Midtrans (Snap API) | Top-up online |
| **Push Notif** | Firebase Cloud Messaging | Notifikasi transaksi |
| **NFC (Mobile)** | `nfc_manager` package | Baca UID kartu dari HP |
| **NFC (ESP32)** | RC522 / PN532 module | Reader tanpa smartphone |
| **State Mgmt** | Riverpod | State management Flutter |
| **Routing** | GoRouter | Navigasi & deep linking |

## Kenapa Supabase (bukan Firebase)?

| Aspek | Supabase ✅ | Firebase |
|---|---|---|
| Database | PostgreSQL (relational, SQL) | Firestore (NoSQL) |
| Query kompleks | JOIN, aggregate, subquery | Terbatas |
| Data keuangan | ACID transactions ✅ | Eventual consistency |
| Laporan | SQL query langsung | Harus olah di client |
| Self-host | Bisa (di masa depan) | Tidak bisa |
| Flutter SDK | Official (`supabase_flutter`) | Official (`FlutterFire`) |
| Pricing | Lebih murah di skala besar | Free tier generous |

> 💡 **Keputusan: Supabase** — data keuangan/transaksi butuh database relational yang kuat.

## Skala Sistem

| Aspek | Saat ini (PKL) | Masa Depan |
|---|---|---|
| Sekolah | 1 sekolah | Multi-sekolah |
| Siswa | ~500-1000 | Bisa ribuan |
| Petugas Kantin | 2-5 orang | Per sekolah |
| Admin | 1-2 orang | Per sekolah |
