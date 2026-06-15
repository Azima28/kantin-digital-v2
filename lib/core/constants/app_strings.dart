class AppStrings {
  AppStrings._();

  // General & Branding
  static const String appName = 'Kantin Digital';
  static const String appCanteenTitle = 'Kantin Digital Kasir';
  static const String subtitleSplash = 'Mulai Jajan Praktis,\nTanpa Uang Tunai Lagi';
  static const String buttonGetStarted = 'Mulai Sekarang';

  // Authentication
  static const String welcomeAuth = 'Yuk, Masuk!';
  static const String welcomeAuthDesc = 'Silakan masuk ke akun kantin sekolahmu.';
  static const String labelEmailOrNis = 'Nomor Induk Siswa (NIS) / Email';
  static const String labelPassword = 'Kata Sandi';
  static const String buttonLogin = 'MASUK';
  static const String buttonLoginKasir = 'MASUK KASIR';
  static const String loginError = 'Email/NIS atau Kata Sandi salah.';
  static const String contactCooperative = 'Lupa sandi? Hubungi Koperasi Sekolah';

  // Dashboard (Siswa & Kasir)
  static const String greetingSiswa = 'Halo, ';
  static const String greetingKasir = 'Kasir POS';
  static const String labelBalance = 'SALDO SAKU';
  static const String labelBalanceEarned = 'Pendapatan Hari Ini';
  static const String statusCardActive = 'Status Kartu: Aktif (✓)';
  static const String buttonTopUp = 'Isi Saldo';
  static const String buttonFreeze = 'Bekukan';
  static const String sectionTodayPurchase = 'Jajan Hari Ini';
  static const String buttonViewAllHistory = 'Lihat Semua Riwayat';

  // POS Cashier (Kasir)
  static const String titleCart = 'Keranjang Belanja';
  static const String labelTotal = 'Total Belanja';
  static const String buttonTapStudentCard = 'PROSES TAP KARTU SISWA';
  static const String labelAddExtraCharge = 'Tambah Biaya Ekstra (Nasi/Sambal)';
  static const String categoryAll = 'Semua';
  static const String categoryFood = 'Makanan';
  static const String categoryDrink = 'Minuman';

  // NFC & Payment Modal
  static const String nfcReadyToScan = 'SIAP MEMINDAI';
  static const String nfcTapInstruction = 'Tempelkan Kartu Siswa...';
  static const String nfcWaitingTap = 'Status: Menunggu Tap Kartu...';
  static const String nfcVerificationSuccess = 'Pengecekan Berhasil';
  static const String nfcCardVerified = 'Kartu pelajar terverifikasi';
  static const String labelStudentName = 'Nama Siswa';
  static const String labelStudentClass = 'Kelas';
  static const String labelCardStatus = 'Status Kartu';
  static const String labelRemainingBalance = 'Saldo Tersedia';
  static const String buttonBackToScan = 'KEMBALI KE SCAN';

  // Products CRUD (Kelola Jajanan)
  static const String titleManageProducts = 'Kelola Jajanan';
  static const String buttonAddProduct = 'TAMBAH PRODUK BARU';
  static const String labelStatusStock = 'Status Stok: Tersedia';
  static const String buttonEditPrice = 'Edit Harga';
  static const String titleAddEditProduct = 'Tambah / Edit Jajanan';
  static const String labelProductName = 'Nama Jajanan';
  static const String labelProductPrice = 'Harga Jajanan';
  static const String labelProductCategory = 'Kategori';
  static const String labelPhotoOptional = 'Foto Jajanan (Opsional)';
  static const String buttonChoosePhoto = 'Pilih Gambar Dari Galeri';
  static const String buttonSaveProduct = 'SIMPAN JAJANAN';

  // History & Refund (Riwayat & Rekap)
  static const String titleHistorySales = 'Rekap Penjualan Hari Ini';
  static const String labelTotalTransactions = 'Total Penjualan';
  static const String labelActivitySales = 'Aktivitas Penjualan';
  static const String buttonRefund = 'BATALKAN TRANSAKSI / REFUND';
}
