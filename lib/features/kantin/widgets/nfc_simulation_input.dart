import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/features/kantin/providers/nfc_payment_provider.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

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
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(CupertinoIcons.device_phone_portrait, size: 16, color: Nebula.teal),
                SizedBox(width: 6),
                Text(
                  '🛠️ SIMULASI TAP KARTU SISWA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Nebula.teal,
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
                  placeholderStyle: TextStyle(color: context.textSecondary, fontSize: 13),
                  style: TextStyle(fontSize: 13, color: context.textPrimary),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.borderLight, width: 0.5),
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
                    color: Nebula.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tap',
                    style: TextStyle(
                      color: context.cardBg,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Preset Kartu Terdaftar (Uji Coba):',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: () {
                  controller.text = '04:18:7D:CA:C1:21:90';
                  ref.read(nfcPaymentProvider.notifier).simulateTagTap('04:18:7D:CA:C1:21:90', totalAmount);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.person_fill,
                        size: 13,
                        color: Nebula.teal,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Ahmad Subarjo (Aktif)',
                        style: TextStyle(
                          color: Nebula.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.text = '04:F4:1B:CA:C1:21:90';
                  ref.read(nfcPaymentProvider.notifier).simulateTagTap('04:F4:1B:CA:C1:21:90', totalAmount);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Nebula.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Nebula.teal.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.person_fill,
                        size: 13,
                        color: Nebula.teal,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Ahmad Fauzi (Aktif)',
                        style: TextStyle(
                          color: Nebula.teal,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  controller.text = '11:22:33:44';
                  ref.read(nfcPaymentProvider.notifier).simulateTagTap('11:22:33:44', totalAmount);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Nebula.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Nebula.rose.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        CupertinoIcons.xmark_shield_fill,
                        size: 13,
                        color: Nebula.rose,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Kartu Tidak Terdaftar',
                        style: TextStyle(
                          color: Nebula.rose,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}