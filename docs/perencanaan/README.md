# 📋 Dokumen Perencanaan — Sistem Kantin Digital

Folder ini berisi semua dokumen perencanaan sistem, dipisah per topik agar mudah direview dan diubah.

## Daftar Dokumen

| # | File | Isi |
|---|---|---|
| 1 | `01-overview.md` | Gambaran umum project, misi, dan solusi |
| 2 | `02-aktor-hak-akses.md` | Daftar aktor, role, dan hak akses masing-masing |
| 3 | `03-arsitektur-tech-stack.md` | Arsitektur sistem, platform, dan teknologi yang dipakai |
| 4 | `04-alur-sistem.md` | Flow top-up, transaksi, dan anti-korupsi |
| 5 | `05-database-schema.md` | Semua tabel database + relasi antar tabel |
| 6 | `06-fitur-per-platform.md` | Daftar fitur untuk setiap platform (mobile, web admin, web publik) |
| 7 | `07-design-direction.md` | Gaya visual, warna, typography, dan indeks spesifikasi UI detail per role (`design/`) |
| 8 | `08-rfid-nfc-integration.md` | Integrasi hardware RFID/NFC (HP NFC + ESP32) |
| 9 | `09-roadmap.md` | Timeline & fase pengembangan |

## 📊 Daftar Diagram (Draw.io XML)

Diagram teknis untuk sistem kantin digital telah dibuat secara lengkap dan disimpan di folder **[docs/diagram/](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/)**:

1.  **[01-activity-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/01-activity-diagram.drawio)** — Diagram alur aktivitas multi-swimlane (Siswa, Kasir, Admin Keuangan).
2.  **[02-class-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/02-class-diagram.drawio)** — Class diagram logis sistem perangkat lunak (properti & metode).
3.  **[03-er-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/03-er-diagram.drawio)** — Entity Relationship Diagram skema basis data PostgreSQL.
4.  **[04-sequence-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/04-sequence-diagram.drawio)** — Sequence diagram alur pemotongan saldo aman via tap NFC di kantin.
5.  **[05-timeline.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/05-timeline.drawio)** — Gantt chart timeline pengembangan proyek selama 6 minggu.
6.  **[06-use-case-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/06-use-case-diagram.drawio)** — Use Case Diagram interaksi pengguna dengan fungsionalitas sistem.
7.  **[07-context-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/07-context-diagram.drawio)** — DFD Level 0 (Context Diagram) aliran data masuk & keluar sistem.
8.  **[08-architecture-diagram.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/08-architecture-diagram.drawio)** — Diagram arsitektur High Level Design (BaaS Supabase + Client Flutter).
9.  **[09-agile-development-method.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/09-agile-development-method.drawio)** — Alur metode pengembangan menggunakan framework Agile Scrum.
10. **[10-system-features-map.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/10-system-features-map.drawio)** — Mindmap pemetaan modul & fitur sistem berdasarkan role.
11. **[11-workflow-navigation.drawio](file:///c:/Work/Project%20PKL/sistem%20kantin%20digital/docs/diagram/11-workflow-navigation.drawio)** — Diagram alur navigasi layar (sitemap) tiap aplikasi/role.

---

## Status

> ⚠️ **DRAFT** — Semua dokumen masih dalam tahap perencanaan dan perlu review sebelum mulai coding.
