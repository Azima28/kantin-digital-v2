# Audit Perbedaan Layout & Animasi — Screen-Screen Kritis

> Original: `C:/Work/Project PKL/sistem kantin digital`
> Clone: `~/projects/kantin-digital`
> Tanggal: 21 Juni 2026

---

## Ringkasan Umum

- **Animasi (AnimatedContainer, SlideTransition, FadeTransition, ScaleTransition, Hero):**  
  **Tidak ditemukan** widget animasi eksplisit di screen-screen kritis pada kedua versi.  
  Perbedaan murni bersifat layout/styling/refaktor konstanta.

- **Pola umum:** Clone melakukan refaktor besar-besaran dari hardcoded `Color(0x...)` menjadi konstanta `AppColors.*`, dan dari inline string menjadi `AppStrings.*`. Clone juga menambahkan error handling yang lebih baik dengan tombol `Retry`.

---

## 1. login_screen.dart

| Item | Original (file:line) | Clone (file:line) |
|------|---------------------|-------------------|
| **Skema warna** | 576 baris, sama | 576 baris, sama |
| **Scaffold bg** | `Colors.white` (L184) | `AppColors.white` (L184) |
| **Hint/border warna** | `Color(0xFFBDC9C8)` (L274,276,314,316,327) | `AppColors.gray400` (L274,276,314,316,327) |
| **ActivityIndicator color** | `Colors.white` (L359) | `AppColors.white` (L359) |
| **Button text color** | `Colors.white` (L365) | `AppColors.white` (L365) |
| **Back button text** | Hardcoded `'Kembali'` (L204) | `AppStrings.buttonBack` (L204) |
| **Super admin route** | `context.go('/admin/secure-entry')` (L54) | `context.go('/admin')` (L54) |
| **Layout & animasi** | Sama persis — tidak ada perbedaan padding, margin, border-radius, shadow, atau font | Sama |

**Kesimpulan:** Perbedaan hanya warna hardcoded → AppColors, string hardcoded → AppStrings, dan route super admin. Layout identik.

---

## 2. siswa_dashboard_screen.dart

| Item | Original (file:line) | Clone (file:line) |
|------|---------------------|-------------------|
| **Total baris** | ~680 baris | ~720 baris |
| **Import tambahan** | - | `app_strings.dart`, `cached_network_image.dart` |
| **Dialog Cancel** | `Text('Batal')` (L29) | `Text(AppStrings.buttonCancel)` (L32) |
| **Error message** | `'Gagal memproses status kartu: $e'` (L58) | `'${AppStrings.labelFailed} memproses status kartu'` (L61) |
| **Type balance** | `double` (L380, L77) | `int` (L416, L80) |
| **DateFormat locale** | `DateFormat('dd MMM yyyy, HH:mm')` (L79) | `DateFormat(..., 'id_ID')` (L82) |
| **BottomSheet** | Basic `showModalBottomSheet` (L83) | + `isScrollControlled: true` (L88) |
| **BS content padding** | `EdgeInsets.symmetric(horizontal: 24, vertical: 16)` (L95) | `EdgeInsets.only(left:24, right:24, top:16, bottom: padding.bottom + 16)` (L104-105) |
| **BS scroll** | `Container` langsung (L94) | `SingleChildScrollView` wrapping `Container` (L98) |
| **Error state items** | `Text('Gagal memuat detail barang: $err')` (L207) | `Column` + `Text('${AppStrings.labelFailed}...')` + retry `TextButton` (L217-226) |
| **PDF buttons** | 1 button: "Bagikan Struk PDF" (L275) | 2 buttons: "Simpan Struk PDF" (L264) + "Bagikan Struk PDF" (L318) |
| **Profile avatar** | Hardcoded URL `avatarUrl` (L299) | Dinamis dari `authState.profile?['avatar_url']` (L341) |
| **Avatar widget** | Custom `Container` + `ClipOval` + `Image.network` (L315-330) | `CircleAvatar` + `CachedNetworkImageProvider` (L358-366) |
| **Scaffold bg** | `Color(0xFFF2F2F7)` (L303) | `AppColors.systemBackground` (L346) |
| **AppBar bg** | `Color(0xFFF9F9FE)` (L307) | `AppColors.systemBackground` (L350) |
| **AppBar border** | `Color(0xFFBDC9C8).withValues(alpha: 0.3)` (L311) | `AppColors.gray400.withValues(alpha: 0.3)` (L354) |
| **Greeting color** | `Color(0xFF3D4949)` (L337) | `AppColors.darkGray` (L373) |
| **Heading "Beranda"** | `Color(0xFF006767)` (L345) | `AppColors.teal` (L381) |
| **Bell icon** | `Color(0xFF006767)` (L355) | `AppColors.teal` (L391) |
| **Balance card border** | `Color(0xFFE5E5EA)` (L396) | `AppColors.borderLight` (L432) |
| **Decorative circle** | `Color(0xFF72D6D6).withValues(alpha: 0.2)` (L410) | `AppColors.softTeal.withValues(alpha: 0.2)` (L446) |
| **"SALDO SAKU" text** | `Color(0xFF3D4949)` (L425) | `AppColors.darkGray` (L461) |
| **Status badge (Aktif)** | `Color(0xFF006767)` (L433) | `AppColors.teal` (L469) |
| **Status badge (Dibekukan)** | `Color(0xFFBA1A1A)` (L434) | `AppColors.errorRed2` (L470) |
| **Rp prefix color** | `Color(0xFF1A1C1F)` (L469) | `AppColors.textDark` (L505) |
| **Saldo amount color** | `Color(0xFF006767)` (L478) | `AppColors.teal` (L514) |
| **"Isi Saldo" button** | `Color(0xFF006767)` (L501) | `AppColors.teal` (L537) |
| **"Bekukan/Aktifkan" button** | `Color(0xFFE2E2E7)` (L529) | `AppColors.grayLight` (L565) |
| **Button text/icons color** | `Color(0xFF1A1C1F)` (L537,544) | `AppColors.textDark` (L573,580) |
| **Saldo error state** | `Text('Gagal memuat saldo: $err')` (L560) | `Column` + `Text('${AppStrings.labelFailed}...')` + `ElevatedButton` retry (L596-604) |
| **Empty state border** | `Color(0xFFE5E5EA)` (L606) | `AppColors.borderLight` (L652) |
| **Empty state icon** | `Color(0xFF7A7A7A)` (L610) | `AppColors.textGray` (L656) |
| **Empty state text** | `Color(0xFF7A7A7A)` (L614) | `AppColors.textGray` (L660) |
| **Tx time format** | `DateFormat('HH:mm')` (L628) | `DateFormat('HH:mm', 'id_ID')` (L674) |
| **Tx icon bg (topup)** | `Color(0xFF006767).withValues(alpha: 0.1)` (L651) | `AppColors.teal.withValues(alpha: 0.1)` (L697) |
| **Tx icon bg (purchase)** | `Color(0xFFF2F2F7)` (L652) | `AppColors.systemBackground` (L698) |
| **Tx icon (topup)** | `CupertinoIcons.square_arrow_down`, color `Color(0xFF006767)` (L656-657) | Sama icon, color `AppColors.teal` (clone not shown yet) |
| **Tx purchase icon** | `Icons.restaurant`, color `Color(0xFF1A1C1F)` (L657) | Sama icon, color `AppColors.textDark` |
| **Tx title color** | `Color(0xFF1A1C1F)` (L671) | `AppColors.textDark` |
| **Tx subtitle color** | `Color(0xFF3D4949)` (L678) | `AppColors.darkGray` |
| **Tx amount topup** | `Color(0xFF006767)` (L694) | `AppColors.teal` |
| **Tx amount purchase** | `Color(0xFFBA1A1A)` (L694) | `AppColors.errorRed2` |

### Perbedaan Layout Signifikan:
1. **Bottom Sheet** — Clone pakai `isScrollControlled: true` + `SingleChildScrollView` + dynamic bottom padding; original statis.
2. **PDF Buttons** — Clone punya 2 tombol (Simpan + Bagikan); original cuma 1 (Bagikan).
3. **Avatar** — Clone pakai `CircleAvatar` + `CachedNetworkImageProvider` (cache + dynamic URL); original hardcoded + `Image.network`.
4. **Error States** — Clone konsisten pakai `Column` + ikon + teks `AppStrings.labelFailed` + `ElevatedButton` retry; original cuma `Text` polos.
5. **Balance type** — Original `double` → Clone `int`.
6. **Semua hardcoded color** diganti `AppColors.*`.

---

## 3. pos_dashboard_screen.dart

| Item | Original (file:line) | Clone (file:line) |
|------|---------------------|-------------------|
| **Total baris** | 480 | 482 |
| **Import** | `Image.network` (L6) | `cached_network_image.dart` (L6) |
| **Cancel button text** | `'Batal'` (L63) | `AppStrings.buttonCancel` (L63) |
| **Logout button text** | `'Keluar'` (L73) | `AppStrings.buttonLogout` (L73) |
| **Revenue error msg** | `'Gagal memuat'` (L128-129) | `'${AppStrings.labelFailed} memuat'` (L129-130) |
| **Image widget** | `Image.network` (L278) | `CachedNetworkImage` (L278) |
| **Product empty error** | `'Gagal mengambil katalog...'` (L378) | `'${AppStrings.labelFailed} mengambil...'` (L380) |
| **Cart "Detail" text** | `'Detail'` (L455) | `AppStrings.titleDetail` (L455) |
| **Bottom spacing comment** | `// not const` — no comment | `// not const — depends on runtime value` (L391) |
| **Layout & animasi** | Sama persis — grid SliverGrid, floating cart bar, CupertinoSegmentedControl | Sama |
| **Padding/margin/spacing** | Identik | Identik |
| **Border-radius/shadow** | Identik | Identik |

**Kesimpulan:** Clone mengganti `Image.network` → `CachedNetworkImage` (caching), dan inline string → `AppStrings.*`. Layout identik.

---

## 4. pos_home_screen.dart

| Item | Original (file:line) | Clone (file:line) |
|------|---------------------|-------------------|
| **Total baris** | 443 | 465 |
| **AppStrings import** | ❌ Tidak ada | ✅ Ada (`app_strings.dart`) |
| **CachedNetworkImage** | ❌ Tidak ada | ✅ Ada |
| **Dialog Cancel** | `'Batal'` (L23) | `AppStrings.buttonCancel` (L26) |
| **Dialog Logout** | `'Keluar'` (L33) | `AppStrings.buttonLogout` (L36) |
| **Profile photo** | Hardcoded `avatarUrl` (L47-48) | Dinamis `authState.profile?['avatar_url']` (L47) |
| **Scaffold bg** | `Color(0xFFF2F2F7)` (L51) | `AppColors.systemBackground` (L52) |
| **AppBar bg** | `Color(0xFFF9F9FE)` (L55) | `AppColors.systemBackground` (L56) |
| **AppBar border** | `Color(0xFFBDC9C8).withValues(alpha: 0.3)` (L59) | `AppColors.gray400.withValues(alpha: 0.3)` (L60) |
| **Avatar widget** | Custom `Container` + `ClipOval` + `Image.network` (L63-78) | `CircleAvatar` + `CachedNetworkImageProvider` (L64-72) |
| **Greeting color** | `Color(0xFF3D4949)` (L85) | `AppColors.darkGray` (L79) |
| **"Beranda" color** | `Color(0xFF006767)` (L93) | `AppColors.teal` (L87) |
| **Earnings card border** | `Color(0xFFE5E5EA)` (L138) | `AppColors.borderLight` (L132) |
| **Decorative circle** | `Color(0xFF72D6D6).withValues(alpha: 0.2)` (L152) | `AppColors.softTeal.withValues(alpha: 0.2)` (L146) |
| **Revenue text color** | `Color(0xFF3D4949)` (L167) | `AppColors.darkGray` (L161) |
| **"Buka" badge color** | `Color(0xFF006767)` (L175,186,193) | `AppColors.teal` (L169,180,187) |
| **Rp prefix color** | `Color(0xFF1A1C1F)` (L209) | `AppColors.textDark` (L203) |
| **Revenue amount color** | `Color(0xFF006767)` (L218) | `AppColors.teal` (L212) |
| **"Kasir POS" button color** | `Color(0xFF006767)` (L247) | `AppColors.teal` (L255) |
| **"Cek Kartu" button** | Route: `/pos/check-card` (L271), bg `Color(0xFFE2E2E7)` (L275), icon `CupertinoIcons.creditcard` (L281), text `'Cek Kartu'` (L285), color `Color(0xFF1A1C1F)` (L282,289) | Route: `/pos/orders` (L279), bg `AppColors.grayLight` (L283), icon `CupertinoIcons.cart` (L289), text `'Pesanan'` (L293), color `AppColors.textDark` (L290,297) |
| **Revenue error state** | `Text('Gagal memuat pendapatan: $err')` (L234) | `Column` + ikon `error_outline` + `Text('${AppStrings.labelFailed}...')` + `ElevatedButton` retry (L228-242) |
| **Empty state border** | `Color(0xFFE5E5EA)` (L342) | `AppColors.borderLight` (L350) |
| **Empty state icon color** | `Color(0xFF7A7A7A)` (L346) | `AppColors.textGray` (L354) |
| **Empty state text color** | `Color(0xFF7A7A7A)` (L350) | `AppColors.textGray` (L358) |
| **Tx amount type** | `final double amount = tx.totalAmount;` (L359) | `final int amount = tx.totalAmount;` (L367) |
| **Tx student name fallback** | `'Siswa'` (L360) | `AppStrings.adminStudents` (L368) |
| **Tx time format** | `DateFormat('HH:mm').format(...)` (L365) | `DateFormat('HH:mm', 'id_ID').format(...)` (L373) |
| **Tx card border** | `Color(0xFFE5E5EA)` (L374) | `AppColors.borderLight` (L382) |
| **Tx cancelled bg** | `Color(0xFFBA1A1A).withValues(alpha: 0.1)` (L383) | `AppColors.errorRed2.withValues(alpha: 0.1)` (L391) |
| **Tx success bg** | `Color(0xFF006767).withValues(alpha: 0.1)` (L384) | `AppColors.teal.withValues(alpha: 0.1)` (L392) |
| **Tx cancelled icon color** | `Color(0xFFBA1A1A)` (L389) | `AppColors.errorRed2` (L397) |
| **Tx success icon color** | `Color(0xFF006767)` (L389) | `AppColors.teal` (L397) |
| **Tx title color** | `Color(0xFF1A1C1F)` (L403) | `AppColors.textDark` (L411) |
| **Tx subtitle color** | `Color(0xFF3D4949)` (L410) | `AppColors.darkGray` (L418) |
| **Tx cancelled amount color** | `Color(0xFFBA1A1A)` (L423) | `AppColors.errorRed2` (L431) |
| **Tx success amount color** | `Color(0xFF006767)` (L423) | `AppColors.teal` (L431) |
| **Tx error state** | `Text('Gagal memuat riwayat: $err')` (L433) | `Column` + ikon + `Text('${AppStrings.labelFailed}...')` + `ElevatedButton` retry (L441-455) |
| **System health values** | `'42ms'`, `'12%'`, `'99.8%'` (L525-529) | `'-'`, `'0%'`, `'100%'` (L531-535) |

### Perbedaan Layout Signifikan:
1. **Avatar profile** — Clone pakai `CircleAvatar` + `CachedNetworkImageProvider` (cache + dynamic); original hardcoded + `Image.network`.
2. **Button kanan** — Original "Cek Kartu" (route `/pos/check-card`); Clone "Pesanan" (route `/pos/orders`).
3. **Error states everywhere** — Clone tambah tombol Retry, ikon error, dan konsisten pakai `AppStrings.labelFailed`; original cuma teks.
4. **double → int** untuk amount.
5. **`id_ID` locale** pada DateFormat.
6. **System health mock values** berbeda.

---

## 5. admin_dashboard_screen.dart

| Item | Original (file:line) | Clone (file:line) |
|------|---------------------|-------------------|
| **Total baris** | 640 | 647 |
| **Import tambahan** | - | `app_colors.dart`, `app_strings.dart` |
| **Scaffold bg** | `Color(0xFFFBF9F8)` (L20) | `AppColors.offWhite` (L20) |
| **AppBar bg** | `Color(0xFFFBF9F8)` (L25,35) | `AppColors.offWhite` (L25,35) |
| **Shadow color** | `Colors.black.withValues(alpha: 0.02)` (L28) | `AppColors.black.withValues(alpha: 0.02)` (L28) |
| **Avatar circle** | `Color(0xFF004D4D)` (L43) | `AppColors.darkTeal2` (L43) |
| **SA text color** | `Colors.white` (L53) | `AppColors.white` (L53) |
| **Title "Kantin Digital"** | `primaryTeal` (`Color(0xFF003434)`) (L63) | `AppColors.darkTeal` (L63) |
| **Bell icon** | `primaryTeal` (`Color(0xFF003434)`) (L70) | `AppColors.darkTeal` (L70) |
| **Loading indicator** | `primaryTeal` (`Color(0xFF003434)`) (L80) | `AppColors.darkTeal` (L80) |
| **Error text color** | `Color(0xFFBA1A1A)` (L84) | `AppColors.errorRed` (L84) |
| **Error state (body)** | `Text('Gagal memuat dashboard: $err')` (L83) | `Column` + ikon + `Text('${AppStrings.labelFailed}...')` + `ElevatedButton(Rerty)` (L82-95) |
| **_buildBody params** | `primaryTeal, accentOrange, successGreen` sebagai parameter (L91-97) | Hanya `data` sebagai parameter (L102-104) — menggunakan `AppColors.*` langsung |
| **Fallback globalBalance type** | `102500000.0` (double) (L101) | `102500000` (int) (L107) |
| **Greeting "Halo, Super Admin"** | `primaryTeal` (`Color(0xFF003434)`) (L120) | `AppColors.darkTeal` (L126) |
| **Subtitle text** | `'Real-time command center overview.'` (L125-126), color `Color(0xFF3F4848)` (L129) | `'Pusat kendali real-time.'` (L131-132), color `AppColors.darkGray` (L135) |
| **"Global Metrics" title** | `'Global Metrics'` (L143), color `primaryTeal` (L147) | `'Metrik Global'` (L149), color `AppColors.darkTeal` (L153) |
| **Inner card bg** | `Color(0xFFF5F3F2)` (L159,191) | `AppColors.offWhite2` (L165,197) |
| **"TOTAL USERS" text** | `'TOTAL USERS'` (L166), color `Color(0xFF3F4848)` (L170) | `'TOTAL PENGGUNA'` (L172), color `AppColors.darkGray` (L176) |
| **Users count color** | `Color(0xFF1B1C1B)` (L180) | `AppColors.nearBlack` (L186) |
| **"DAILY VOLUME" text** | `'DAILY VOLUME'` (L199), color `Color(0xFF3F4848)` (L203) | `'VOLUME HARIAN'` (L205), color `AppColors.darkGray` (L209) |
| **Volume count color** | `Color(0xFF1B1C1B)` (L215) | `AppColors.nearBlack` (L221) |
| **Daily volume fallback** | `'42.5K'` (L211) | `'0'` (L217) |
| **Global balance card** | `Color(0xFFFCA558).withValues(alpha: 0.1)` bg (L231), border `Color(0xFFFCA558).withValues(alpha: 0.2)` (L232) | `AppColors.accentOrange2.withValues(alpha: 0.1)` (L237), border `AppColors.accentOrange2...` (L238) |
| **"GLOBAL BALANCE" text** | `'GLOBAL BALANCE'` (L238), color `accentOrange` (L242) | `'SALDO GLOBAL'` (L244), color `AppColors.darkOrange` (L249) |
| **"Rp" color (balance)** | `accentOrange` (`Color(0xFF904D00)`) (L258) | `AppColors.darkOrange` (L265) |
| **Balance amount color** | `accentOrange` (L269) | `AppColors.darkOrange` (L275) |
| **"Transaction Trend" title** | `'Transaction Trend'` (L291), color `primaryTeal` (L296) | `'Tren Transaksi'` (L297), color `AppColors.darkTeal` (L303) |
| **Trend badge** | `Color(0xFFEFEDEC)` bg (L305), `'30 Days'` text (L309), color `Color(0xFF3F4848)` (L313) | `AppColors.lightGray` bg (L311), `'30 Hari'` text (L315), color `AppColors.darkGray` (L319) |
| **Trend chart color** | `primaryTeal` (L326) | `AppColors.darkTeal` (L332) |
| **_buildBentoCard** | `color: Colors.white` (L379), shadow `Colors.black.withValues(alpha: 0.04)` (L382) | `color: AppColors.white` (L385), shadow `AppColors.black.withValues(alpha: 0.04)` (L388) |
| **_buildContributionCard title** | `'Role Activity'` (L433) | Sama `'Role Activity'` (L438) |
| **_buildContributionCard params** | `primaryTeal`, `successGreen` | `primaryColor`, `successColor` — menggunakan `AppColors.darkTeal`, `AppColors.successGreen` |
| **Legend colors** | `primaryTeal` (L466), `Color(0xFFFCA558)` (L468), `successGreen` (L470) | `AppColors.darkTeal` (L472), `AppColors.accentOrange2` (L474), `AppColors.successGreen` (L476) |
| **System health** | `successGreen` colors (L498,509,517,524) | `AppColors.successGreen` (L504,515,523,530) |
| **Health icon color** | `Color(0xFF6F7978)` (L538) | `AppColors.mutedGray` (L544) |
| **Health label color** | `Color(0xFF1B1C1B)` (L548,559) | `AppColors.nearBlack` (L554,565) |
| **TrendChartPainter data type** | `List<double>` (L570) | `List<num>` (L576) |
| **TrendChartPainter cast** | Langsung `data[i]` (L612) | `data[i].toDouble()` (L618) |

### Perbedaan Layout Signifikan:
1. **Subtitle/keterangan** — Original English "Real-time command center overview."; Clone Bahasa Indonesia "Pusat kendali real-time."
2. **Semua label** — Original English ("Global Metrics", "TOTAL USERS", "DAILY VOLUME", "GLOBAL BALANCE", "Transaction Trend", "30 Days"); Clone Bahasa Indonesia ("Metrik Global", "TOTAL PENGGUNA", "VOLUME HARIAN", "SALDO GLOBAL", "Tren Transaksi", "30 Hari")
3. **Daily volume fallback** — Original `'42.5K'` (mock value); Clone `'0'` (realistic zero)
4. **Error state** — Clone punya tombol Retry dengan `ElevatedButton`; original cuma teks.
5. **`_buildBody` signature** — Original passing 3 colors sebagai parameter; Clone hanya ambil data, sisanya langsung `AppColors.*`.
6. **Type `double` → `int`** untuk globalBalance (L101 vs L107).
7. **TrendChartPainter** menerima `List<double>` vs `List<num>` dengan `.toDouble()`.

---

## Ringkasan Pola Perubahan (Clone vs Original)

### 1. Warna: Hardcoded → AppColors.* (90+ perubahan)
Semua `Color(0x...)` diganti dengan konstanta dari `AppColors`. Contoh mapping:
| Hardcoded | AppColors |
|-----------|-----------|
| `Color(0xFF006767)` | `AppColors.teal` |
| `Color(0xFF003434)` | `AppColors.darkTeal` |
| `Color(0xFF1A1C1F)` | `AppColors.textDark` / `AppColors.nearBlack` |
| `Color(0xFF3D4949)` / `Color(0xFF3F4848)` | `AppColors.darkGray` |
| `Color(0xFF7A7A7A)` | `AppColors.textGray` |
| `Color(0xFFBDC9C8)` | `AppColors.gray400` |
| `Color(0xFFE5E5EA)` / `Color(0xFFF5F3F2)` | `AppColors.borderLight` / `AppColors.offWhite` / `AppColors.offWhite2` |
| `Color(0xFFF2F2F7)` / `Color(0xFFF9F9FE)` | `AppColors.systemBackground` |
| `Color(0xFFFBF9F8)` | `AppColors.offWhite` |
| `Color(0xFFE2E2E7)` | `AppColors.grayLight` |
| `Color(0xFFBA1A1A)` | `AppColors.errorRed2` |
| `Color(0xFF72D6D6)` | `AppColors.softTeal` |
| `Color(0xFFFCA558)` | `AppColors.accentOrange2` |
| `Color(0xFF904D00)` | `AppColors.darkOrange` |
| `Color(0xFF004D4D)` | `AppColors.darkTeal2` |
| `Color(0xFF6F7978)` | `AppColors.mutedGray` |
| `Color(0xFFEFEDEC)` | `AppColors.lightGray` |
| `Color(0xFF006A35)` | `AppColors.successGreen` |

### 2. String: Hardcoded → AppStrings.*
Semua string UI (label, judul, tombol, error message) diganti dengan konstanta dari `AppStrings`.

### 3. Gambar: Image.network → CachedNetworkImage
Di pos_dashboard_screen.dart dan pos_home_screen.dart, `Image.network` diganti dengan `CachedNetworkImage` yang punya placeholder loading dan caching.

### 4. Avatar: Custom widget → CircleAvatar
Di siswa_dashboard_screen.dart dan pos_home_screen.dart, avatar yang tadinya dibangun manual (`Container` + `ClipOval` + `Image.network`) diganti dengan `CircleAvatar` + `CachedNetworkImageProvider`, dan URL diambil dinamis dari profile (bukan hardcoded).

### 5. Layout bottom sheet → isScrollControlled + SingleChildScrollView
Clone menambahkan `isScrollControlled: true` pada `showModalBottomSheet` dan membungkus konten dengan `SingleChildScrollView` untuk keyboard-aware scrolling.

### 6. Error states → Column + Icon + Retry button
Clone konsisten menambahkan: ikon error, teks ramah (`AppStrings.labelFailed`), dan `ElevatedButton`/`TextButton` retry. Original hanya menampilkan teks error polos.

### 7. Lokalisasi: Locale id_ID
Clone menambahkan `'id_ID'` pada `DateFormat` untuk formatting tanggal/waktu Indonesia.

### 8. Tipe data: double → int
Clone mengubah tipe `amount` dan `balance` dari `double` menjadi `int` (konsisten dengan model data integer untuk uang).

### 9. Admin dashboard: Bahasa Inggris → Bahasa Indonesia
Semua label di admin dashboard diterjemahkan ke Bahasa Indonesia.

### 10. Pos Home: "Cek Kartu" → "Pesanan"
Tombol aksi kedua di pos home screen berubah dari "Cek Kartu" (route `/pos/check-card`) menjadi "Pesanan" (route `/pos/orders`), dengan ikon berubah dari `creditcard` ke `cart`.

### Animasi
**Tidak ada perubahan animasi** — kedua versi tidak menggunakan `AnimatedContainer`, `SlideTransition`, `FadeTransition`, `ScaleTransition`, atau `Hero` pada screen-screen yang diaudit. Semua statis tanpa transisi/widget animasi eksplisit.

---

## Matrix Perubahan Per Screen

| Screen | Warna | String | Layout | Error Handle | Animasi |
|--------|-------|--------|--------|-------------|---------|
| login_screen.dart | ✅ 6 changes | ✅ 1 change | ❌ Identik | ❌ Identik | ❌ None |
| siswa_dashboard_screen.dart | ✅ 25+ changes | ✅ 5+ changes | ✅ Bottom Sheet, PDF buttons, Avatar, Error states | ✅ Retry buttons added | ❌ None |
| pos_dashboard_screen.dart | ✅ Minor | ✅ 4 changes | ❌ Identik | ✅ AppStrings.labelFailed | ❌ None |
| pos_home_screen.dart | ✅ 20+ changes | ✅ 5+ changes | ✅ Button "Cek Kartu"→"Pesanan", Avatar, Error states | ✅ Retry buttons added | ❌ None |
| admin_dashboard_screen.dart | ✅ 20+ changes | ✅ 10+ changes (i18n EN→ID) | ✅ Error states, _buildBody signature simplified | ✅ Retry button added | ❌ None |
