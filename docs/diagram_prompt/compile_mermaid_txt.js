const fs = require('fs');
const path = require('path');

const DIRECTORY = __dirname;
const systemContext = `## 🏛️ PART 1: PENJELASAN KONTEKS & WORKFLOW SISTEM

Sistem Kantin Digital adalah platform transaksi cashless (non-tunai) di lingkungan sekolah untuk memudahkan siswa melakukan pembelian di kantin menggunakan kartu RFID/NFC (Tap-to-Pay) sebagai pengganti uang tunai. Sistem ini dibangun dengan arsitektur modern menggunakan teknologi Flutter dan Supabase Cloud.

### 👥 Aktor Utama & Hak Akses (Roles)
Sistem memiliki 5 aktor dengan peran dan batasan hak akses yang jelas:
1. 👦 Siswa (Role: \`siswa\` | Warna Visual: Biru 🔵 \`#DAE8FC\`)
   - Memegang kartu fisik RFID/NFC untuk melakukan transaksi tap jajan di kantin.
   - Login ke Mobile App Siswa untuk melihat sisa saldo, memantau riwayat transaksi jajan secara detail, dan menerima push notification real-time.
2. 👩 Orang Tua (Tanpa Login | Warna Visual: Biru 🔵 \`#DAE8FC\`)
   - Mengakses Web Publik khusus orang tua menggunakan NIS (Nomor Induk Siswa) anak.
   - Dapat melihat saldo saat ini, 5 riwayat transaksi terakhir anak, dan melakukan top-up online.
3. 👵 Petugas Kantin / Kasir (Role: \`petugas_kantin\` | Warna Visual: Kuning/Peach 🟡 \`#FFE6CC\`)
   - Penjual stan makanan di kantin sekolah.
   - Login ke Mobile POS App (Point of Sale) untuk mengelola katalog menu jajan, menginput keranjang belanja (cart) siswa, melakukan scan kartu NFC siswa, memotong saldo, dan memproses checkout jajan.
4. 👨‍💼 Admin Keuangan / Koperasi (Role: \`admin_keuangan\` | Warna Visual: Hijau 🟢 \`#D5E8D4\`)
   - Petugas tata usaha atau koperasi sekolah yang mengurusi administrasi kas tunai.
   - Login ke Web Admin Portal untuk melayani top-up manual/tunai (menerima uang tunai fisik dan menginput saldo ke akun siswa) serta melakukan koreksi/penyesuaian saldo jika ada kesalahan input.
5. 👑 Super Admin (Role: \`super_admin\` | Warna Visual: Teal/Abu-abu \`#E6F2F2\`)
   - Pengelola sistem tingkat tertinggi (Dinas Pendidikan atau Kepala Sekolah).
   - Memiliki akses penuh ke seluruh data sekolah, CRUD akun pengguna, dan memantau live audit logs untuk melacak semua perubahan data administratif sensitif.

---

### ⚡ Alur Transaksi Utama & Validasi Keamanan (Anti-Fraud & ACID)
Untuk mencegah eksploitasi keamanan (seperti modifikasi saldo lokal di sisi aplikasi client), sistem menerapkan validasi transaksi yang ketat di sisi server (Server-side Validation):
1. **Penyusunan Belanja**: Petugas Kantin memasukkan makanan/minuman ke keranjang di aplikasi POS Kasir -> Total harga dihitung secara lokal di client.
2. **Scan NFC**: Siswa men-tap kartu RFID/NFC ke HP kasir (atau card reader) -> POS App membaca UID kartu NFC dan mengirimkannya ke Supabase Database.
3. **Cek Saldo Aktual**: Database mengembalikan nama siswa dan saldo teraktual yang ada di server. POS App melakukan verifikasi awal: jika saldo kurang, transaksi dibatalkan langsung.
4. **Eksekusi Transaksi (ACID Stored Procedure)**: Jika saldo cukup, POS App mengirim request checkout berupa daftar item belanja beserta total harga ke Supabase.
5. **Server-Side Validation**: Database Supabase akan memproses transaksi ini dalam sebuah database transaction yang bersifat atomik (all-or-nothing):
   - Database menarik harga aktual produk langsung dari tabel \`products\` di server (bukan mempercayai nominal harga yang dikirim oleh POS App client) untuk mencegah manipulasi harga belanja di client.
   - Database melakukan pengecekan ulang apakah saldo siswa di tabel \`students\` benar-benar cukup.
   - Database memotong saldo siswa (\`balance\` - total_harga) dan mencatat transaksi ke tabel \`transactions\` & \`transaction_items\`.
   - Rantai aksi ini dibungkus dalam ACID Transaction, jika salah satu langkah gagal, seluruh transaksi di-rollback secara otomatis.
6. **Notifikasi Real-time**: Jika transaksi sukses, database memicu trigger push notification melalui Firebase Cloud Messaging (FCM) dan Supabase Realtime Channel untuk langsung mengirimkan pesan instan jajan ke HP Siswa/Orang Tua secara real-time.

---

### 💳 Alur Top-Up Saldo (Online vs Manual)
Sistem mendukung dua metode top-up saldo jajan:
1. **Jalur Online (Midtrans Payment Gateway)**:
   - Siswa atau Orang Tua memilih nominal top-up di aplikasi.
   - Aplikasi memanggil Midtrans Snap SDK untuk melakukan pembayaran online (Virtual Account, QRIS, dll).
   - Setelah pembayaran berhasil, Midtrans mengirimkan webhook HTTP ke Supabase Edge Functions.
   - Edge Functions memvalidasi tanda tangan webhook, mengupdate saldo siswa di database secara aman, dan mengirim notifikasi push sukses.
2. **Jalur Manual (Cash di Koperasi - Audit-Logged)**:
   - Siswa menyerahkan uang tunai ke koperasi sekolah.
   - Admin Keuangan memverifikasi NIS siswa, lalu menginput nominal top-up tunai melalui Web Admin Portal.
   - Sistem memperbarui saldo siswa di database, sekaligus **wajib mencatat entri log secara otomatis ke tabel \`audit_logs\`** (berisi ID admin, NIS target, nominal sebelum dan sesudah top-up, IP Address admin, dan timestamp).
   - **Pencegahan Korupsi**: Tabel \`audit_logs\` diatur menggunakan RLS (Row Level Security) Supabase agar berstatus *Insert-Only*. Tidak ada admin, termasuk Admin Keuangan, yang dapat mengedit atau menghapus log audit ini, sehingga Super Admin memiliki rekam jejak keuangan yang 100% transparan dan tidak dapat dimanipulasi.

---

### 🗄️ Konsistensi Model Data (Class & Database Schema)
Nama kelas perangkat lunak pada Class Diagram (PascalCase) berkorespondensi satu-satu dengan nama tabel fisik database pada ERD (snake_case):
- \`User\` 👤 <=> \`users\`: Akun login utama pengguna (\`id\`, \`email\`, \`password_hash\`, \`full_name\`, \`role\`, \`is_active\`, \`created_at\`).
- \`School\` 🏫 <=> \`schools\`: Profil sekolah mitra (\`id\`, \`name\`, \`address\`, \`logo_url\`, \`is_active\`, \`created_at\`).
- \`Student\` 🎓 <=> \`students\`: Profil siswa pemegang kartu NFC (\`id\`, \`user_id\`, \`school_id\`, \`nis\`, \`balance\`, \`card_uid\`, \`is_card_frozen\`, \`is_active\`).
- \`CanteenOperator\` 🏪 <=> \`canteen_operators\`: Operator stan penjual di kantin (\`id\`, \`user_id\`, \`school_id\`, \`stall_name\`, \`is_active\`).
- \`Product\` 🍔 <=> \`products\`: Produk menu jajan yang dijual stan (\`id\`, \`canteen_operator_id\`, \`name\`, \`price\`, \`image_url\`, \`is_available\`).
- \`Transaction\` 💸 <=> \`transactions\`: Log transaksi masuk/keluar keuangan (\`id\`, \`student_id\`, \`type\`, \`amount\`, \`performed_by\`, \`method\`, \`status\`, \`notes\`, \`created_at\`).
- \`TransactionItem\` 🧾 <=> \`transaction_items\`: Item detail belanja dalam transaksi jajan (\`id\`, \`transaction_id\`, \`product_id\`, \`name\`, \`price\`, \`quantity\`, \`subtotal\`).
- \`AuditLog\` 📜 <=> \`audit_logs\`: Rekaman audit aktivitas sensitif admin (\`id\`, \`user_id\`, \`action\`, \`target_table\`, \`target_id\`, \`old_value\`, \`new_value\`, \`ip_address\`, \`created_at\`).`;

// Read the compiled prompt-text.md to parse out the diagrams
const compiledPath = path.join(DIRECTORY, 'prompt-text.md');
const content = fs.readFileSync(compiledPath, 'utf-8');

// The diagrams are split by "### 🗺️ " or "### 📐 " or "### 🗄️ " etc
const sections = content.split('\n### ');

// We care about sections starting from index 1 (which are the 11 diagrams)
const filenames = [
  '01-activity-diagram.txt',
  '02-class-diagram.txt',
  '03-er-diagram.txt',
  '04-sequence-diagram.txt',
  '05-timeline.txt',
  '06-use-case-diagram.txt',
  '07-context-diagram.txt',
  '08-architecture-diagram.txt',
  '09-agile-development-method.txt',
  '10-system-features-map.txt',
  '11-workflow-navigation.txt'
];

filenames.forEach((fname, idx) => {
  const sec = sections[idx + 1];
  if (!sec) return;
  
  // Reconstruct title
  const titleLine = sec.split('\n')[0];
  const title = titleLine.substring(3).trim(); // strip the icon prefix e.g. "🗺️ "
  
  // Extract diagram code block or specifications
  const details = sec.substring(titleLine.length).trim();
  
  const textContent = `# PROMPT DIAGRAM: ${title}

Halo AI Diagram Builder! Tugas Anda adalah membuat/memperbaiki diagram **"${title}"** untuk **Sistem Kantin Digital** berdasarkan spesifikasi Mermaid.js di bawah ini.

PENTING:
- Pastikan semua diagram memiliki nama aktor, entitas, dan logika alur yang **selaras 100%** dengan diagram lainnya dalam sistem.
- Terapkan gaya visual, warna latar, warna batas, dan emoji yang telah ditentukan agar diagram terlihat rapi, modern, dan profesional.

---

${systemContext}

---

## 📊 PART 2: SPESIFIKASI DIAGRAM & KODE MERMAID

${details}
`;

  const outFilePath = path.join(DIRECTORY, fname);
  fs.writeFileSync(outFilePath, textContent, 'utf-8');
  console.log(`Berhasil menulis file prompt teks Mermaid: ${fname}`);
});
