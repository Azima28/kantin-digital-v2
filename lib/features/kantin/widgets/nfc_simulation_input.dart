import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/constants/app_colors.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';

class NfcSimulationInput extends ConsumerWidget {
  final TextEditingController controller;
  final int totalAmount;

  const NfcSimulationInput({
    super.key,
    required this.controller,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(CupertinoIcons.device_phone_portrait, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  '🛠️ SIMULASI TAP KARTU SISWA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: 'Masukkan RFID UID (Contoh: RFID123)',
                  placeholderStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
                  style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight, width: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final String uid = controller.text.trim();
                  if (uid.isNotEmpty) {
                    ref.read(nfcPaymentProvider.notifier).simulateTagTap(uid, totalAmount);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tap',
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Preset Kartu Terdaftar:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              controller.text = '04:A3:F8:12';
              ref.read(nfcPaymentProvider.notifier).simulateTagTap('04:A3:F8:12', totalAmount);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      CupertinoIcons.person_fill,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ahmad Subarjo (04:A3:F8:12)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
