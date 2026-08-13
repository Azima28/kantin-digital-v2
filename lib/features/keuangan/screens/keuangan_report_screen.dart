import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/core/services/report_export_service.dart';
import 'package:kantin_digital/features/keuangan/providers/keuangan_providers.dart';
import 'package:kantin_digital/features/keuangan/widgets/daily_trend_chart_dialog.dart';

import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/constants/app_strings.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class KeuanganReportScreen extends ConsumerStatefulWidget {
  const KeuanganReportScreen({super.key});

  @override
  ConsumerState<KeuanganReportScreen> createState() => _KeuanganReportScreenState();
}

class _KeuanganReportScreenState extends ConsumerState<KeuanganReportScreen> {

  late DateTime _startDate;
  late DateTime _endDate;
  String _quickChoice = 'Bulan Ini';
  int _monthPickerYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _quickChoice = 'Bulan Ini';
    _monthPickerYear = now.year;
  }

  String get _formattedPeriodLabel {
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    final startStr = fmt.format(_startDate);
    final endStr = fmt.format(_endDate);

    if (_startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == 1 &&
        _endDate.day == DateTime(_endDate.year, _endDate.month + 1, 0).day) {
      return DateFormat('MMMM yyyy', 'id_ID').format(_startDate);
    }
    if (_startDate.year == _endDate.year &&
        _startDate.month == _endDate.month &&
        _startDate.day == _endDate.day) {
      return startStr;
    }
    return '$startStr - $endStr';
  }

  ReportFilterParam get _currentFilterParam {
    return ReportFilterParam(
      periodLabel: _formattedPeriodLabel,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Widget _buildExportFormatCard({
    required String title,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final isExcel = title.contains('Excel');
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : context.dividerCol,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            // Top accent line
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? accentColor : accentColor.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isExcel)
                    const Icon(Icons.table_chart_rounded, size: 40, color: Color(0xFF16A34A))
                  else
                    const Icon(Icons.picture_as_pdf_rounded, size: 40, color: Color(0xFFDC2626)),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isSelected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: accentColor),
                        const SizedBox(width: 4),
                        Text(
                          'Terpilih',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    )
                  else
                    const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: context.textPrimary,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: Nebula.teal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool excelChecked = true;
        bool includeAudit = true;
        bool includeStudents = false;
        bool isProcessing = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Nebula.teal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            CupertinoIcons.doc_text_search,
                            color: Nebula.teal,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Export Laporan',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section: Format Laporan
                    Text(
                      'Format Laporan:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildExportFormatCard(
                            title: 'Excel (.xls)',
                            isSelected: excelChecked,
                            accentColor: const Color(0xFF16A34A),
                            onTap: () {
                              setDialogState(() {
                                excelChecked = true;
                              });
                            },
                            context: context,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExportFormatCard(
                            title: 'PDF',
                            isSelected: !excelChecked,
                            accentColor: const Color(0xFFDC2626),
                            onTap: () {
                              setDialogState(() {
                                excelChecked = false;
                              });
                            },
                            context: context,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section: Pilih Data Yang Disertakan
                    Text(
                      'Pilih Data Yang Disertakan:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildExportSwitchTile(
                      title: 'Rekap Riwayat Audit Log',
                      value: includeAudit,
                      onChanged: (val) {
                        setDialogState(() {
                          includeAudit = val;
                        });
                      },
                      context: context,
                    ),
                    const SizedBox(height: 6),
                    _buildExportSwitchTile(
                      title: 'Detail Per-Siswa (Data Sensitif)',
                      value: includeStudents,
                      onChanged: (val) {
                        setDialogState(() {
                          includeStudents = val;
                        });
                      },
                      context: context,
                    ),
                    const SizedBox(height: 20),

                    // Batal Action
                    Center(
                      child: TextButton(
                        onPressed: isProcessing
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.inter(
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Download Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final nav = Navigator.of(dialogContext);
                                final messenger = ScaffoldMessenger.of(context);

                                setDialogState(() {
                                  isProcessing = true;
                                });

                                try {
                                  final reportData = ref
                                          .read(keuanganReportProvider(
                                              _currentFilterParam))
                                          .valueOrNull ??
                                      {};
                                  final canteens = List<Map<String, dynamic>>.from(
                                      reportData['canteens'] ?? []);
                                  final totalTopup =
                                      (reportData['totalTopup'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final totalPurchase =
                                      (reportData['totalPurchase'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final totalCorrection =
                                      (reportData['totalCorrection'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final topupCount =
                                      (reportData['topupCount'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final purchaseCount =
                                      (reportData['purchaseCount'] as num?)
                                              ?.toInt() ??
                                          0;

                                  List<Map<String, dynamic>> auditLogs = [];
                                  if (includeAudit) {
                                    final rawLogs = ref
                                            .read(keuanganHistoryProvider)
                                            .valueOrNull ??
                                        [];
                                    final start = DateTime(_startDate.year,
                                        _startDate.month, _startDate.day, 0, 0, 0);
                                    final end = DateTime(_endDate.year,
                                        _endDate.month, _endDate.day, 23, 59, 59);

                                    auditLogs = rawLogs
                                        .where((l) {
                                          if (l.createdAt == null) return true;
                                          final created = l.createdAt!.toLocal();
                                          return (created.isAfter(start) ||
                                                  created.isAtSameMomentAs(start)) &&
                                              (created.isBefore(end) ||
                                                  created.isAtSameMomentAs(end));
                                        })
                                        .map((l) => l.toJson())
                                        .toList();
                                  }

                                  List<Map<String, dynamic>> studentsList = [];
                                  if (includeStudents) {
                                    final rawStudents = ref
                                            .read(keuanganStudentsProvider)
                                            .valueOrNull ??
                                        [];
                                    studentsList = rawStudents
                                        .map((s) => {
                                              'full_name': s.fullName,
                                              'nisn': s.nisn,
                                              'class_name': s.class_,
                                              'balance': s.balance,
                                              'is_active': s.isActive,
                                            })
                                        .toList();
                                  }

                                  if (excelChecked) {
                                    await ReportExportService.downloadExcelReport(
                                      period: _currentFilterParam.formattedPeriodLabel,
                                      totalTopup: totalTopup,
                                      totalPurchase: totalPurchase,
                                      totalCorrection: totalCorrection,
                                      topupCount: topupCount,
                                      purchaseCount: purchaseCount,
                                      canteens: canteens,
                                      includeAudit: includeAudit,
                                      includeStudents: includeStudents,
                                      auditLogs: auditLogs,
                                      students: studentsList,
                                    );
                                  } else {
                                    await ReportExportService.downloadPdfReport(
                                      period: _currentFilterParam.formattedPeriodLabel,
                                      totalTopup: totalTopup,
                                      totalPurchase: totalPurchase,
                                      totalCorrection: totalCorrection,
                                      topupCount: topupCount,
                                      purchaseCount: purchaseCount,
                                      canteens: canteens,
                                      includeAudit: includeAudit,
                                      includeStudents: includeStudents,
                                      auditLogs: auditLogs,
                                      students: studentsList,
                                    );
                                  }

                                  if (mounted) {
                                    nav.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          excelChecked
                                              ? 'File Laporan Keuangan (.xlsx) berhasil diunduh!'
                                              : 'File Laporan Keuangan (.pdf) berhasil diunduh!',
                                        ),
                                        backgroundColor: Nebula.teal,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setDialogState(() {
                                      isProcessing = false;
                                    });
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Gagal mengunduh laporan: $e'),
                                        backgroundColor: Nebula.rose,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download_rounded,
                                size: 20, color: Colors.white),
                        label: Text(
                          'Download File',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Nebula.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTrendsDialog() {
    showDialog(
      context: context,
      builder: (context) => DailyTrendChartDialog(filterParam: _currentFilterParam),
    );
  }

  Widget _buildQuickChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Nebula.teal : context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Nebula.teal : context.dividerCol,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showDaySelectionDialog({
    required BuildContext context,
    required String title,
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final daysInMonth =
            DateTime(initialDate.year, initialDate.month + 1, 0).day;
        int selectedDay = initialDate.day;

        return StatefulBuilder(
          builder: (ctx, setDayState) {
            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 340),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(dialogCtx),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daysInMonth,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (gCtx, index) {
                        final day = index + 1;
                        final isSelected = day == selectedDay;

                        return InkWell(
                          onTap: () {
                            final newDate = DateTime(
                                initialDate.year, initialDate.month, day);
                            onDateSelected(newDate);
                            Navigator.pop(dialogCtx);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Nebula.teal : context.surfaceBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Nebula.teal
                                    : context.dividerCol,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$day',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterPeriodeDialog() {
    final now = DateTime.now();
    DateTime tempStartDate = _startDate;
    DateTime tempEndDate = _endDate;
    String tempQuickChoice = _quickChoice;
    int tempYear = _monthPickerYear;
    final yearController = TextEditingController(text: '$tempYear');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final fmtDate = DateFormat('dd MMM yyyy', 'id_ID');
            final shortMonths = [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'Mei',
              'Jun',
              'Jul',
              'Agt',
              'Sep',
              'Okt',
              'Nov',
              'Des'
            ];

            return Dialog(
              backgroundColor: context.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title + X Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Periode',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 1: PILIHAN CEPAT
                    Text(
                      'PILIHAN CEPAT',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildQuickChoiceChip(
                          label: 'Hari Ini',
                          isSelected: tempQuickChoice == 'Hari Ini',
                          onTap: () {
                            setDialogState(() {
                              tempQuickChoice = 'Hari Ini';
                              tempStartDate =
                                  DateTime(now.year, now.month, now.day);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          },
                          context: context,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChoiceChip(
                          label: 'Minggu Ini',
                          isSelected: tempQuickChoice == 'Minggu Ini',
                          onTap: () {
                            setDialogState(() {
                              tempQuickChoice = 'Minggu Ini';
                              final startOfWeek = now
                                  .subtract(Duration(days: now.weekday - 1));
                              tempStartDate = DateTime(startOfWeek.year,
                                  startOfWeek.month, startOfWeek.day);
                              tempEndDate =
                                  DateTime(now.year, now.month, now.day);
                            });
                          },
                          context: context,
                        ),
                        const SizedBox(width: 8),
                        _buildQuickChoiceChip(
                          label: 'Bulan Ini',
                          isSelected: tempQuickChoice == 'Bulan Ini',
                          onTap: () {
                            setDialogState(() {
                              tempQuickChoice = 'Bulan Ini';
                              tempYear = now.year;
                              tempStartDate =
                                  DateTime(now.year, now.month, 1);
                              tempEndDate =
                                  DateTime(now.year, now.month + 1, 0);
                            });
                          },
                          context: context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: RENTANG WAKTU
                    Text(
                      'RENTANG WAKTU',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dari Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dari',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  _showDaySelectionDialog(
                                    context: dialogContext,
                                    title: 'Pilih Tanggal Mulai',
                                    initialDate: tempStartDate,
                                    onDateSelected: (picked) {
                                      setDialogState(() {
                                        tempStartDate = picked;
                                        if (tempStartDate
                                            .isAfter(tempEndDate)) {
                                          tempEndDate = tempStartDate;
                                        }
                                        tempQuickChoice = '';
                                      });
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: context.dividerCol),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: context.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fmtDate.format(tempStartDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Sampai Box
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sampai',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () {
                                  _showDaySelectionDialog(
                                    context: dialogContext,
                                    title: 'Pilih Tanggal Selesai',
                                    initialDate: tempEndDate,
                                    onDateSelected: (picked) {
                                      setDialogState(() {
                                        tempEndDate = picked;
                                        if (tempEndDate
                                            .isBefore(tempStartDate)) {
                                          tempStartDate = tempEndDate;
                                        }
                                        tempQuickChoice = '';
                                      });
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        Border.all(color: context.dividerCol),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: context.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          fmtDate.format(tempEndDate),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: PILIH BULAN 🔒
                    Row(
                      children: [
                        Text(
                          'PILIH BULAN ',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: context.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.surfaceBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: context.dividerCol.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        children: [
                          // Year selector row (< 2026 >) - Typable Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    tempYear--;
                                    yearController.text = '$tempYear';
                                    tempStartDate = DateTime(
                                        tempYear, tempStartDate.month, 1);
                                    tempEndDate = DateTime(
                                        tempYear,
                                        tempStartDate.month,
                                        DateTime(tempYear,
                                                tempStartDate.month + 1, 0)
                                            .day);
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: context.textPrimary,
                                    size: 22,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 76,
                                height: 36,
                                child: TextField(
                                  controller: yearController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 4),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide:
                                          BorderSide(color: context.dividerCol),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Nebula.teal, width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color: context.dividerCol
                                              .withValues(alpha: 0.5)),
                                    ),
                                    fillColor: context.cardBg,
                                    filled: true,
                                  ),
                                  onChanged: (val) {
                                    if (val.length == 4) {
                                      final parsedYear = int.tryParse(val);
                                      if (parsedYear != null &&
                                          parsedYear >= 2000 &&
                                          parsedYear <= 2099) {
                                        setDialogState(() {
                                          tempYear = parsedYear;
                                          tempStartDate = DateTime(
                                              tempYear, tempStartDate.month, 1);
                                          tempEndDate = DateTime(
                                              tempYear,
                                              tempStartDate.month,
                                              DateTime(tempYear,
                                                      tempStartDate.month + 1, 0)
                                                  .day);
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    tempYear++;
                                    yearController.text = '$tempYear';
                                    tempStartDate = DateTime(
                                        tempYear, tempStartDate.month, 1);
                                    tempEndDate = DateTime(
                                        tempYear,
                                        tempStartDate.month,
                                        DateTime(tempYear,
                                                tempStartDate.month + 1, 0)
                                            .day);
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: context.textPrimary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 12 Months Grid (3 rows x 4 cols)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 12,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemBuilder: (gridContext, index) {
                              final monthNum = index + 1;
                              final monthLabel = shortMonths[index];
                              final isMonthSelected =
                                  (tempStartDate.year == tempYear &&
                                      tempStartDate.month == monthNum &&
                                      tempEndDate.month == monthNum &&
                                      tempStartDate.day == 1 &&
                                      tempEndDate.day ==
                                          DateTime(tempYear, monthNum + 1, 0)
                                              .day);

                              return InkWell(
                                onTap: () {
                                  setDialogState(() {
                                    tempStartDate =
                                        DateTime(tempYear, monthNum, 1);
                                    tempEndDate = DateTime(
                                        tempYear,
                                        monthNum,
                                        DateTime(tempYear, monthNum + 1, 0)
                                            .day);
                                    if (tempYear == now.year &&
                                        monthNum == now.month) {
                                      tempQuickChoice = 'Bulan Ini';
                                    } else {
                                      tempQuickChoice = '';
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  decoration: BoxDecoration(
                                    color: isMonthSelected
                                        ? Nebula.teal.withValues(alpha: 0.12)
                                        : context.cardBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isMonthSelected
                                          ? Nebula.teal
                                          : context.dividerCol,
                                      width: isMonthSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      monthLabel,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: isMonthSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isMonthSelected
                                            ? Nebula.teal
                                            : context.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 5: Footer Buttons (Batal & Terapkan)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.dividerCol),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _startDate = tempStartDate;
                              _endDate = tempEndDate;
                              _quickChoice = tempQuickChoice;
                              _monthPickerYear = tempYear;
                            });
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Nebula.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 22, vertical: 10),
                            elevation: 0,
                          ),
                          child: Text(
                            'Terapkan',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(keuanganReportProvider(_currentFilterParam));
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Laporan Keuangan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Nebula.teal,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(keuanganReportProvider(_currentFilterParam)),
          color: Nebula.teal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single Filter Button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _showFilterPeriodeDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.dividerCol),
                          boxShadow: [
                            BoxShadow(
                              color: context.shadowColor,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Nebula.teal,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Periode Laporan',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formattedPeriodLabel,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Nebula.teal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ubah',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Nebula.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Nebula.teal,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                reportAsync.when(
                  data: (data) {
                    final rawCanteens = data['canteens'] as List<dynamic>;
                    final canteens = rawCanteens
                        .map((e) => CanteenOperator.fromJson(
                            Map<String, dynamic>.from(e)))
                        .toList();
                    final totalTopup = (data['totalTopup'] as num?)?.toDouble() ?? 0.0;
                    final totalPurchase = (data['totalPurchase'] as num?)?.toDouble() ?? 0.0;
                    final totalCorrection = (data['totalCorrection'] as num?)?.toDouble() ?? 0.0;
                    final topupCount = (data['topupCount'] as num?)?.toInt() ?? 0;
                    final purchaseCount = (data['purchaseCount'] as num?)?.toInt() ?? 0;

                    // Calculate net balance flow
                    final netInflow = totalTopup + totalCorrection;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: context.cardBg.withValues(alpha: 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(CupertinoIcons.graph_square_fill, color: Nebula.teal, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ringkasan Periode (${_currentFilterParam.formattedPeriodLabel})',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Nebula.teal),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildReportRow('Total Top-Up Tunai', fmt.format(totalTopup), detail: '$topupCount transaksi'),
                              Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                              _buildReportRow('Total Pembayaran Belanja', fmt.format(totalPurchase), detail: '$purchaseCount transaksi', valueColor: Nebula.amber),
                              Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                              _buildReportRow('Total Koreksi Saldo', '${totalCorrection >= 0 ? "+" : ""}${fmt.format(totalCorrection)}', valueColor: totalCorrection >= 0 ? Nebula.teal : Nebula.rose),
                              Divider(height: 16, thickness: 0.5, color: context.dividerCol),
                              _buildReportRow(
                                'Net Aliran Masuk',
                                fmt.format(netInflow),
                                isBold: true,
                                valueColor: Nebula.teal,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Canteen operators revenue header
                        Text(
                          'Pendapatan per Stan Kantin:',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
                        ),
                        const SizedBox(height: 12),

                        // Canteens list Bento Card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: context.cardBg.withValues(alpha: 0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: canteens.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'Belum ada pendapatan terekam untuk stan kantin.',
                                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: canteens.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final canteen = entry.value;
                                    final name = canteen.canteenName;
                                    final int earned = canteen.balanceEarned;

                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Nebula.teal.withValues(alpha: 0.08),
                                            child: Icon(CupertinoIcons.house_alt_fill, color: Nebula.teal, size: 18),
                                          ),
                                          title: Text(
                                            name,
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                                          ),
                                          trailing: Text(
                                            fmt.format(earned),
                                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Nebula.teal),
                                          ),
                                        ),
                                        if (i < canteens.length - 1)
                                          Divider(height: 1, thickness: 0.5, color: context.dividerCol, indent: 72),
                                      ],
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showTrendsDialog,
                                icon: Icon(CupertinoIcons.chart_bar, size: 18),
                                label: Text(
                                  'Grafik Tren',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Nebula.teal,
                                  side: BorderSide(color: Nebula.teal),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _showExportDialog,
                                icon: Icon(CupertinoIcons.share_up, size: 18),
                                label: Text(
                                  'Export Laporan',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.cardBg),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Nebula.teal,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                  loading: () => Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CupertinoActivityIndicator(color: Nebula.teal),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Nebula.rose),
                          const SizedBox(height: 12),
                          Text('${AppStrings.labelFailed} memuat laporan'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(keuanganReportProvider(_currentFilterParam)),
                            child: const Text(AppStrings.buttonRetry),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? valueColor, String? detail}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
            ),
            if (detail != null)
              Text(
                detail,
                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 11),
              ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? context.textPrimary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
