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

const globalStylingText = `### 🎨 2. STANDARISASI GAYA & PEWARNAAN VISUAL (THEME STYLE)
Untuk memastikan estetika desain premium, modern, dan selaras antar diagram, wajib gunakan palet warna di bawah ini:
- 🔵 **Siswa / Orang Tua**: fill \`#DAE8FC\`, stroke \`#6C8EBF\`, text \`#0A2540\`
- 🟡 **Petugas Kantin (Kasir)**: fill \`#FFE6CC\`, stroke \`#D79B00\`, text \`#5A3200\`
- 🟢 **Admin Keuangan**: fill \`#D5E8D4\`, stroke \`#72B095\`, text \`#0A3F2C\`
- ⚙️ **Sistem / Database / Backend**: fill \`#E6F2F2\`, stroke \`#0E8A8A\`, text \`#0E8A8A\`
- ✅ **Success State**: fill \`#C6F6D5\`, stroke \`#38A169\`, text \`#22543D\`
- ❌ **Fail / Error State**: fill \`#FED7D7\`, stroke \`#E53E3E\`, text \`#742A2A\`
- **Font Utama**: Segoe UI / Arial (Sans-serif)
- **Shadow**: Nonaktifkan shadow/bayangan objek untuk tampilan flat modern yang bersih.`;

// Function to format nodes list
function formatNodes(nodes) {
  return nodes.map(n => {
    let str = `- **ID ${n.id}**: ${n.emoji || ''} ${n.label}`;
    let details = [];
    if (n.shape) details.push(`Bentuk: ${n.shape}`);
    if (n.swimlane) details.push(`Swimlane: ${n.swimlane}`);
    if (n.color) details.push(`Warna: ${n.color}`);
    if (details.length > 0) str += ` (${details.join(', ')})`;
    return str;
  }).join('\n');
}

// Function to format connections list
function formatConnections(connections) {
  return connections.map(c => {
    let str = `- Dari **ID ${c.from}** Ke **ID ${c.to}**`;
    let details = [];
    if (c.label) details.push(`Label: "${c.label}"`);
    if (c.routing) details.push(`Aturan Rute: ${c.routing}`);
    if (c.cardinality) details.push(`Kardinalitas: ${c.cardinality}`);
    if (c.bidirectional) details.push(`Dua Arah: Ya`);
    if (details.length > 0) str += ` (${details.join(', ')})`;
    return str;
  }).join('\n');
}

// Function to parse and format sequence messages
function formatSequenceMessages(messages, indent = 0) {
  const spaces = ' '.repeat(indent);
  return messages.map((m, idx) => {
    if (m.type === 'alt') {
      let condStr = `${spaces}- **Blok Alternatif (Kondisi Cabang)**:\n`;
      condStr += m.conditions.map(c => {
        let stepStr = `${spaces}  * **Kondisi: ${c.name}**\n`;
        stepStr += formatSequenceMessages(c.steps, indent + 4);
        return stepStr;
      }).join('\n');
      return condStr;
    } else {
      let details = [];
      if (m.from) details.push(`Dari: ${m.from}`);
      if (m.to) details.push(`Ke: ${m.to}`);
      if (m.note) details.push(`Catatan: "${m.note}"`);
      if (m.label) details.push(`Label: "${m.label}"`);
      return `${spaces}- **Langkah ${idx + 1}**: ${m.emoji || ''} ${details.join(' | ')}`;
    }
  }).join('\n');
}

// Keep track of diagram prompts for the compiled prompt-text.md
const compiledPrompts = [];

// Get all files and sort them to keep 01 to 11 sequence order
const files = fs.readdirSync(DIRECTORY).filter(file => file.endsWith('.json') && file !== 'prompt.json').sort();

files.forEach(file => {
  const filePath = path.join(DIRECTORY, file);
  const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
  const d = data.diagram;
  
  let diagramContent = '';
  
  if (d.type === 'activity_swimlane') {
    diagramContent += `### 🌊 Swimlanes (Kolom Aktivitas):\n`;
    diagramContent += d.swimlanes.map(s => `- **${s.name}** (Warna: ${s.color})`).join('\n') + '\n\n';
    diagramContent += `### 📍 Nodes (Langkah Aktivitas):\n`;
    diagramContent += formatNodes(d.nodes) + '\n\n';
    diagramContent += `### 🔌 Connections (Aliran & Label Hubungan):\n`;
    diagramContent += formatConnections(d.connections);
  } 
  
  else if (d.type === 'class_diagram') {
    diagramContent += `### 📦 Kelas UML (Entities):\n`;
    diagramContent += d.nodes.map(n => {
      let str = `- **Kelas ${n.label}** ${n.emoji || ''} (Warna: ${n.color})\n`;
      str += `  * Atribut:\n`;
      str += n.attributes.map(a => `    - ${a}`).join('\n');
      return str;
    }).join('\n') + '\n\n';
    
    diagramContent += `### 🏷️ Enums:\n`;
    diagramContent += d.enums.map(e => {
      return `- **Enum ${e.name}** ${e.emoji || ''}\n  * Nilai: ${e.values.join(', ')}`;
    }).join('\n') + '\n\n';
    
    diagramContent += `### 🔗 Relasi & Kardinalitas:\n`;
    diagramContent += formatConnections(d.connections);
  } 
  
  else if (d.type === 'er_diagram') {
    diagramContent += `### 🗄️ Tabel Database (snake_case):\n`;
    diagramContent += d.nodes.map(n => {
      let str = `- **Tabel \\\`${n.label}\\\`** ${n.emoji || ''} (Warna: ${n.color})\n`;
      str += `  * Kolom & Kunci:\n`;
      str += n.fields.map(f => `    - ${f}`).join('\n');
      return str;
    }).join('\n') + '\n\n';
    
    diagramContent += `### 🔑 Hubungan Relasi (Crow's Foot):\n`;
    diagramContent += formatConnections(d.connections);
  } 
  
  else if (d.type === 'sequence_diagram') {
    diagramContent += `### 👥 Lifelines (Objek/Aktor):\n`;
    diagramContent += d.lifelines.map(l => `- **${l.id}**: ${l.label} ${l.emoji || ''} (Warna: ${l.color})`).join('\n') + '\n\n';
    diagramContent += `### 💬 Urutan Pesan (Messages):\n`;
    diagramContent += formatSequenceMessages(d.messages);
  } 
  
  else if (d.type === 'gantt_chart') {
    diagramContent += `### 📅 Pembagian Sprint & Durasi Tugas:\n`;
    diagramContent += d.sprints.map(s => {
      let str = `- **${s.name}**\n`;
      str += `  * Daftar Tugas:\n`;
      str += s.tasks.map(t => `    - ${t.emoji || ''} ${t.name} (Durasi: ${t.duration}, Warna: ${t.color})`).join('\n');
      return str;
    }).join('\n');
  } 
  
  else if (d.type === 'use_case') {
    diagramContent += `### 👥 Aktor (Actors):\n`;
    diagramContent += d.actors.map(a => `- **${a.id}** ${a.emoji || ''} (Warna: ${a.color})`).join('\n') + '\n\n';
    
    diagramContent += `### 🎯 Use Cases (Fungsi Sistem):\n`;
    diagramContent += d.usecases.map(u => `- **ID ${u.id}**: ${u.label} (Kelompok/Stereotype: ${u.stereotype || 'umum'})`).join('\n') + '\n\n';
    
    diagramContent += `### 🔗 Hubungan Use Case (Associations):\n`;
    diagramContent += d.associations.map(as => `- Aktor **${as.actor}** terhubung ke Use Case: ${as.usecase.join(', ')}`).join('\n');
  } 
  
  else if (d.type === 'context_diagram') {
    diagramContent += `### 💻 Pusat Sistem (Central System):\n`;
    diagramContent += `- **ID ${d.centralSystem.id}**: ${d.centralSystem.label.replace('\n', ' ')} ${d.centralSystem.emoji || ''} (Bentuk: ${d.centralSystem.shape})\n\n`;
    
    diagramContent += `### 👥 Entitas Luar (External Entities):\n`;
    diagramContent += d.entities.map(e => `- **ID ${e.id}**: ${e.label} ${e.emoji || ''} (Warna: ${e.color})`).join('\n') + '\n\n';
    
    diagramContent += `### 🔄 Aliran Data (Data Flows):\n`;
    diagramContent += d.flows.map(f => `- Dari **ID ${f.from}** Ke **ID ${f.to}** (Aliran: "${f.label.replace(/\n/g, ' ')}", Dua Arah: ${f.bidirectional ? 'Ya' : 'Tidak'})`).join('\n');
  } 
  
  else if (d.type === 'architecture_diagram') {
    diagramContent += `### 🏢 Tingkat Arsitektur (Tiers):\n`;
    diagramContent += d.tiers.map(t => {
      let str = `- **Tier: ${t.name}**\n`;
      str += `  * Komponen:\n`;
      str += t.components.map(c => `    - **ID ${c.id}**: ${c.label} ${c.emoji || ''} ${c.color ? `(Warna: ${c.color})` : ''}`).join('\n');
      return str;
    }).join('\n') + '\n\n';
    
    diagramContent += `### 🔗 Hubungan Komponen (Data Connection):\n`;
    diagramContent += formatConnections(d.connections);
  } 
  
  else if (d.type === 'scrum_flow') {
    diagramContent += `### ♻️ Tahapan Scrum (Nodes):\n`;
    diagramContent += formatNodes(d.nodes) + '\n\n';
    
    diagramContent += `### 🔌 Aliran Proses (Connections):\n`;
    diagramContent += formatConnections(d.connections);
  } 
  
  else if (d.type === 'mindmap') {
    const rootNode = d.nodes.find(n => n.id === 'root') || { id: 'root', label: 'ROOT', color: 'system_backend', emoji: '🌟' };
    diagramContent += `### 🌟 Node Pusat (Mindmap Root):\n`;
    diagramContent += `- **ID ${rootNode.id}**: ${rootNode.label} ${rootNode.emoji || ''} (Warna: ${rootNode.color})\n\n`;
    
    diagramContent += `### 🌿 Cabang Utama & Sub-Fitur (Branches & Children):\n`;
    diagramContent += d.nodes.map(n => {
      if (n.id === 'root') return '';
      let str = `- **Cabang ${n.label}** ${n.emoji || ''} (Warna: ${n.color})\n`;
      str += `  * Sub-fitur:\n`;
      str += n.children.map(c => `    - ${c.emoji || ''} ${c.label}`).join('\n');
      return str;
    }).filter(Boolean).join('\n');
  } 
  
  else if (d.type === 'screen_navigation') {
    diagramContent += `### 📱 Platform Aplikasi (Groups):\n`;
    diagramContent += d.groups.map(g => {
      let str = `- **Platform: ${g.name}** (Warna: ${g.color})\n`;
      str += `  * Daftar Layar (Screens):\n`;
      str += g.screens.map(s => `    - **ID ${s.id}**: ${s.label} ${s.emoji || ''}`).join('\n') + '\n';
      str += `  * Perpindahan Layar (Transitions):\n`;
      str += g.transitions.map(t => `    - Dari **ID ${t.from}** Ke **ID ${t.to}** (Pemicu: "${t.label}" ${t.routing ? `| Rute: ${t.routing}` : ''})`).join('\n');
      return str;
    }).join('\n\n');
  }

  // 1. Write the self-contained text prompt file for this diagram
  const outputText = `# PROMPT DIAGRAM: ${d.title}

Halo AI Diagram Builder! Tugas Anda adalah membuat/memperbaiki diagram **"${d.title}"** untuk **Sistem Kantin Digital** berdasarkan spesifikasi teknis di bawah ini.

PENTING:
- Pastikan semua diagram memiliki nama aktor, entitas, dan logika alur yang **selaras 100%** dengan diagram lainnya dalam sistem.
- Terapkan gaya visual, warna latar, warna batas, dan emoji yang telah ditentukan agar diagram terlihat rapi, modern, dan profesional.

---

${systemContext}

---

## 📊 PART 2: SPESIFIKASI DIAGRAM ${d.title}

- **Tipe Diagram**: \`${d.type}\`
- **Deskripsi**: ${d.description}

${globalStylingText}

---

### 🧱 KOMPONEN & HUBUNGAN DIAGRAM

${diagramContent}
`;

  const outFileName = file.replace('.json', '.txt');
  const outFilePath = path.join(DIRECTORY, outFileName);
  fs.writeFileSync(outFilePath, outputText, 'utf-8');
  console.log(`Berhasil menulis file prompt: ${outFileName}`);

  // 2. Format for compiled prompt-text.md
  compiledPrompts.push(`### 🗺️ Prompt ${d.title}

- **Tipe Diagram**: \`${d.type}\`
- **Deskripsi**: ${d.description}

${globalStylingText}

#### 🧱 KOMPONEN & HUBUNGAN DIAGRAM

${diagramContent}
`);
});

// Write consolidated prompt-text.md
const compiledText = `# 🏫 SPESIFIKASI DIAGRAM & CONTEXT SISTEM KANTIN DIGITAL (TEXT VERSION)

Dokumen ini dirancang sebagai **Text Prompt Master** yang sangat detail untuk diberikan kepada AI Diagram Builder (seperti ChatGPT, Claude, Gemini, atau Draw.io AI). Dokumen ini membantu AI memahami **konteks bisnis, arsitektur backend, dan logika alur kerja** sebelum merancang atau merapikan ke-11 diagram sistem agar selaras dan konsisten.

---

${systemContext}

---

## 📊 PART 2: TEXT PROMPTS RINCI UNTUK 11 DIAGRAM

Gunakan instruksi di bawah ini untuk membuat atau merapikan diagram Anda. Terapkan palet warna visual yang konsisten:
- 🔵 **Siswa / Orang Tua** = Biru Lembut (\`#DAE8FC\`)
- 🟡 **Petugas Kantin** = Kuning/Peach Lembut (\`#FFE6CC\`)
- 🟢 **Admin Keuangan** = Hijau Lembut (\`#D5E8D4\`)
- ⚙️ **Sistem / Database / Backend** = Teal Lembut (\`#E6F2F2\`)

---

${compiledPrompts.join('\n\n---\n\n')}
`;

const mdFilePath = path.join(DIRECTORY, 'prompt-text.md');
fs.writeFileSync(mdFilePath, compiledText, 'utf-8');
console.log('Berhasil menulis file kompilasi: prompt-text.md');
