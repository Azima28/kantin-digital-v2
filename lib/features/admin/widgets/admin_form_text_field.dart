import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';

class AdminFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType inputType;
  final Widget? suffix;
  final Widget? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  const AdminFormTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.inputType = TextInputType.text,
    this.suffix,
    this.prefix,
    this.inputFormatters,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: context.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: prefix,
        prefixIconConstraints: prefix != null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: context.cardBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.dividerCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Nebula.teal, width: 1.5),
        ),
      ),
    );
  }
}
