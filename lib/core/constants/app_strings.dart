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
  static const String loginCredentialFilled = 'Kredensial ';
  static const String loginCredentialFilledSuffix = ' berhasil diisi!';
  static const String loginRoleAdmin = 'Super Admin';
  static const String loginRoleKantin = 'Operator Kantin';
  static const String loginRoleKeuangan = 'Petugas Keuangan';
  static const String loginRoleSiswa = 'Siswa';
  static const String loginRoleOrangTua = 'Orang Tua';
  static const String loginSessionActive = '1 Sesi aktif di perangkat iOS (iPhone 15 Pro Max).';
  static const String errorSessionActive = 'Sesi aktif';

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

  // General Actions
  static const String buttonCancel = 'Batal';
  static const String buttonSave = 'Simpan';
  static const String buttonLogout = 'Keluar';
  static const String buttonRefresh = 'Muat Ulang';
  static const String buttonRetry = 'Coba Lagi';
  static const String buttonDelete = 'Hapus';
  static const String buttonBack = 'Kembali';
  
  // General Labels
  static const String labelAll = 'Semua';
  static const String labelNoData = 'Tidak ada data';
  static const String labelLoading = 'Memuat...';
  static const String labelLoadingData = 'Memuat data...';
  static const String labelSearch = 'Cari...';
  static const String labelError = 'Terjadi kesalahan';
  static const String labelSuccess = 'Berhasil';
  static const String labelFailed = 'Gagal';
  static const String labelFailedPickImage = 'Gagal memilih gambar';
  static const String labelFailedDeleteNotification = 'Gagal menghapus notifikasi';
  static const String labelFailedSave = 'Gagal menyimpan';
  static const String labelFailedSaveProduct = 'Gagal menyimpan jajanan';
  static const String labelFailedChangePassword = 'Gagal mengubah kata sandi';
  static const String labelFailedDeactivate = 'Gagal menonaktifkan akun';
  static const String labelFailedSaveSettings = 'Gagal menyimpan setelan global';
  static const String labelTransaction = 'Transaksi';
  static const String labelFullName = 'Nama Lengkap';
  static const String labelSisaSaldo = 'Sisa Saldo';
  static const String labelTotalBelanja = 'Total Belanja';
  static const String labelIdTransaksi = 'ID Transaksi';
  static const String labelWaktu = 'Waktu';
  static const String labelMetodeLokasi = 'Metode/Lokasi';
  static const String labelRincianPembelian = 'Rincian Pembelian:';
  static const String labelTotalPembayaran = 'Total Pembayaran:';
  static const String labelPelanggan = 'Pelanggan';
  static const String labelReset = 'Reset';
  static const String labelResetDate = 'Reset Tanggal';
  static const String labelSavePdf = 'Simpan Struk PDF';
  static const String labelUploadingPhoto = 'Mengupload foto...';
  static const String labelTakePhoto = 'Ambil Foto dari Kamera';
  static const String labelPickGallery = 'Pilih dari Galeri';
  static const String labelDeleteImage = 'Hapus Gambar';
  
  // Dialog
  static const String titleDetail = 'Detail';
  static const String titleConfirmation = 'Konfirmasi';
  static const String labelYes = 'Ya';
  static const String labelNo = 'Tidak';
  
  // Actions
  static const String buttonAdd = 'Tambah';
  static const String buttonSelect = 'Pilih';
  static const String buttonEdit = 'Edit';
  
  // Admin specific
  static const String adminChangePassword = 'Ubah Kata Sandi';
  static const String adminNonaktifkan = 'Nonaktifkan';
  static const String adminAktifkan = 'Aktifkan';
  static const String adminUsers = 'Pengguna';
  static const String adminMerchants = 'Pedagang';
  static const String adminStudents = 'Siswa';
  static const String adminStaff = 'Staf';
  static const String adminFieldRequired = 'Nama, NISN, dan password wajib diisi';
  static const String adminFieldRequiredRfid = 'Nama, NISN, password, dan nomor kartu RFID wajib diisi';
  static const String adminFieldRequiredNameNisn = 'Nama dan username wajib diisi';
  static const String adminFieldRequiredNameEmail = 'Nama dan email wajib diisi';
  static const String adminStudentRegistered = ' berhasil didaftarkan sebagai siswa';
  static const String adminUserAdded = ' berhasil ditambahkan';
  static const String adminFinishLabel = 'Selesai';
  static const String adminLogoutConfirm = 'Apakah Anda yakin ingin keluar dari akun kasir?';
  static const String adminClose = 'Tutup';
  static const String adminRefund = 'Refund';
  static const String adminReject = 'Tolak';
  static const String adminProcess = 'Proses';
  static const String adminSessionActiveLabel = 'Sesi Aktif';
  static const String adminNoProductsLabel = 'Tidak ada produk.';
  static const String adminNoSalesLabel = 'Belum ada penjualan.';
  static const String adminAllUsersLabel = 'Semua Pengguna';
  static const String adminOnlyMerchants = 'Khusus Pedagang';
  static const String adminOnlyStudents = 'Khusus Siswa';
  static const String adminOnlyStaff = 'Khusus Staf';
  
  // Errors
  static const String errorNetwork = 'Tidak ada koneksi internet';
  static const String errorGeneral = 'Terjadi kesalahan, silakan coba lagi';
  static const String errorPasswordMismatch = 'Kata sandi tidak cocok';
  static const String errorInvalidSession = 'Sesi kasir tidak valid. Harap login kembali.';
  static const String errorStudentNotFound = 'Data siswa tidak ditemukan';
  static const String errorParentNoChild = 'Akun orang tua tidak memiliki data anak yang tertaut.';
  static const String errorAccessDenied = 'Akses ditolak: Hak akses tidak dikenali.';
  static const String errorRfidRequired = 'UID kartu tidak boleh kosong.';
  static const String errorTopupFailed = 'Top-up gagal';
  static const String errorCorrectionFailed = 'Koreksi gagal';

  // History & Refund (Riwayat & Rekap)
  static const String titleHistorySales = 'Rekap Penjualan Hari Ini';
  static const String labelTotalTransactions = 'Total Penjualan';
  static const String labelActivitySales = 'Aktivitas Penjualan';
  static const String buttonRefund = 'BATALKAN TRANSAKSI / REFUND';

  // Admin screens
  static const String adminAllUsers = 'Semua Pengguna';
  static const String adminMerchantsOnly = 'Pedagang';
  static const String adminStudentsOnly = 'Siswa';
  static const String adminStaffOnly = 'Staf';
  static const String adminNoProducts = 'Tidak ada produk.';
  static const String adminNoSales = 'Belum ada penjualan.';
  static const String adminActiveSession = 'Sesi aktif';

  // Kantin screens
  static const String kantinOrderNew = 'Baru';
  static const String kantinOrderCooking = 'Sedang Dimasak';
  static const String kantinOrderReady = 'Siap Diambil';
  static const String kantinOrderDelivering = 'Siap Diantar';
  static const String kantinAllActivity = 'Semua Aktivitas';
  static const String kantinAddMenu = 'Tambah Menu';
  static const String kantinEditMenu = 'Ubah Menu';
  static const String kantinRefund = 'Refund Transaksi';
  static const String kantinLogoutConfirm = 'Apakah Anda yakin ingin keluar dari akun kasir?';
  static const String kantinDeleteProductConfirm = 'Apakah Anda yakin ingin menghapus "';
  static const String kantinDeleteProductConfirmSuffix = '" dari katalog stan Anda?';
  static const String kantinRefundConfirmPrefix = 'Apakah Anda yakin ingin membatalkan transaksi belanja senilai ';
  static const String kantinRefundConfirmSuffix = ' oleh ';
  static const String kantinRefundConfirmAfter = '? Saldo siswa akan dikembalikan.';
  static const String kartuAktif = 'Aktif';
  static const String kartuTidakTerdaftar = 'Kartu Tidak Terdaftar';

  // Keuangan screens
  static const String keuanganAllTransactions = 'Semua Transaksi';
  static const String keuanganTopupTunai = 'Top-Up Tunai';
  static const String keuanganKoreksiSaldo = 'Koreksi Saldo';
  static const String keuanganCardRegistration = 'Registrasi Kartu';
  static const String keuanganProfile = 'Profil';
  static const String keuanganCardDetected = 'Kartu terdeteksi: ';
  static const String keuanganStudentRegistered = 'Siswa ';
  static const String keuanganStudentRegisteredSuffix = ' berhasil didaftarkan';
  static const String keuanganDeleteCardTitle = 'Hapus Tautan Kartu';
  static const String keuanganDeleteCardContent = 'Apakah Anda yakin ingin menghapus tautan kartu dari siswa ini? Kartu tidak akan bisa digunakan lagi.';
  static const String keuanganLogoutConfirm = 'Apakah Anda yakin ingin keluar dari akun keuangan ini?';
  static const String keuanganChangePasswordDesc = 'Masukkan kata sandi baru untuk akun Anda.';
  static const String keuanganReportSent = 'Laporan berhasil diexport dan dikirim ke ';
  static const String keuanganRejectParentConfirm = 'Tolak pendaftaran orang tua "';
  static const String keuanganRejectParentConfirmSuffix = '"?';
  static const String keuanganRejected = 'Pendaftaran ';
  static const String keuanganRejectedSuffix = ' ditolak';
  static const String keuanganVerified = ' berhasil diverifikasi';

  // Siswa screens
  static const String siswaWelcome = 'Selamat Datang';
  static const String siswaNoCards = 'Belum ada kartu';

  // Parent screens
  static const String parentTopup = 'Isi Saldo';
  static const String parentDashboard = 'Dashboard';
  static const String parentReceipt = 'Struk Transaksi';
  static const String parentSettingsSaved = 'Pengaturan berhasil disimpan!';

  // Public screens
  static const String publicHome = 'Beranda';
  static const String publicMenu = 'Menu Kantin';
  static const String publicInfo = 'Info Sekolah';

  // Shared
  static const String noTransactions = 'Belum ada transaksi.';
  static const String noActivity = 'Belum ada aktivitas.';
  static const String topupSuccess = 'Top-Up Berhasil';
  static const String paymentSuccess = 'Pembayaran Berhasil';
  static const String successPdfDownloaded = 'Struk PDF berhasil diunduh';
  static const String successPasswordUpdated = 'Kata sandi berhasil diperbarui!';
  static const String successPasswordChanged = 'Kata sandi berhasil diubah!';
  static const String successSettingsSaved = 'Setelan global berhasil disimpan!';
  static const String successPushSent = 'Notifikasi push broadcast berhasil dikirim!';
  static const String successProductDeleted = 'Jajanan berhasil dihapus';
  static const String successProductSaved = 'Jajanan berhasil ditambahkan!';
  static const String successProductUpdated = 'Jajanan berhasil diubah!';
  static const String successStatusChanged = 'Status akun berhasil ';
  static const String successCardUnlinked = 'Tautan kartu berhasil dihapus.';
  static const String successCardActivated = 'Kartu berhasil diaktifkan!';
  static const String successCardActivatedBack = 'Kartu berhasil diaktifkan kembali!';
  static const String successCardFrozen = 'Kartu berhasil dibekukan!';
  static const String successCardFrozenTemp = 'Kartu Anda telah dibekukan sementara.';
  static const String successTransactionRefunded = 'Transaksi berhasil dibatalkan dan saldo dikembalikan.';
  static const String successOrderStatusChanged = 'Status pesanan berhasil diubah menjadi ';
  static const String successProfilePhotoUpdated = 'Foto profil berhasil diperbarui!';
  static const String successOldPasswordWrong = 'Sandi lama yang dimasukkan salah.';
  static const String successTopupDetail = 'Selamat, saldo saku Anda telah bertambah sebesar ';
}
