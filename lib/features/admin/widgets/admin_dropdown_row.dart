import 'package:flutter/material.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class AdminDropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const AdminDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.dividerCol),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                ),
                onChanged: onChanged,
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
