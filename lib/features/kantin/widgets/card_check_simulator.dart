import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';

/// A development-only simulator panel for testing card scans.
class CardCheckSimulator extends StatelessWidget {
  final void Function(String rfidUid) onSimulateScan;

  const CardCheckSimulator({super.key, required this.onSimulateScan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.device_phone_portrait,
                  size: 18, color: AppColors.accentOrange),
              SizedBox(width: 8),
              Text(
                'Simulator Scan Kartu (Dev Only)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Klik tombol di bawah untuk menyimulasikan pembacaan kartu RFID via hardware:',
            style: TextStyle(fontSize: 11, color: AppColors.textGray),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: AppColors.primaryLight,
                side: BorderSide.none,
                label: const Text('Ahmad Subarjo (Aktif)',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                onPressed: () => onSimulateScan('04:A3:F8:12'),
              ),
              ActionChip(
                backgroundColor: AppColors.errorLight,
                side: BorderSide.none,
                label: const Text('Kartu Tidak Terdaftar',
                    style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                onPressed: () => onSimulateScan('11:22:33:44'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
