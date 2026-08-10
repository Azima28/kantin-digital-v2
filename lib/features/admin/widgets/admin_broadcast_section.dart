import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/features/admin/widgets/setting_section_widget.dart';

/// Broadcast section for sending push notifications.
class AdminBroadcastSection extends StatelessWidget {
  final String selectedAudience;
  final TextEditingController broadcastController;
  final bool isSaving;
  final ValueChanged<String> onAudienceChanged;
  final VoidCallback onSend;

  const AdminBroadcastSection({
    super.key,
    required this.selectedAudience,
    required this.broadcastController,
    required this.isSaving,
    required this.onAudienceChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SettingSectionWidget(
      icon: CupertinoIcons.speaker_2,
      title: 'Siaran Broadcast',
      children: [
        Text(
          'Target Audiens',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedAudience,
              isExpanded: true,
              icon: Icon(CupertinoIcons.chevron_down, size: 16, color: Nebula.teal),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua Pengguna')),
                DropdownMenuItem(value: 'merchants', child: Text('Khusus Pedagang')),
                DropdownMenuItem(value: 'students', child: Text('Khusus Siswa')),
                DropdownMenuItem(value: 'staff', child: Text('Khusus Staf')),
              ],
              onChanged: (val) {
                if (val != null) onAudienceChanged(val);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Message Content',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: broadcastController,
            maxLines: 4,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ketik pesan notifikasi di sini...',
              hintStyle: TextStyle(color: context.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isSaving ? null : onSend,
          style: ElevatedButton.styleFrom(
            backgroundColor: Nebula.teal,
            foregroundColor: context.cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(CupertinoIcons.paperplane_fill, size: 16),
          label: const Text(
            'KIRIM NOTIFIKASI PUSH',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}