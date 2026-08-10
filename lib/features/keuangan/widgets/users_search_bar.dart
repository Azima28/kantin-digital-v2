import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/extensions/theme_extensions.dart';

class UsersSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final List<String> hints; // Index 0=students, 1=parents, 2=staff
  final bool showClear;

  const UsersSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hints,
    this.showClear = false,
  });

  @override
  State<UsersSearchBar> createState() => _UsersSearchBarState();
}

class _UsersSearchBarState extends State<UsersSearchBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hints.isNotEmpty
              ? (widget.hints.length > 1
                  ? widget.hints[0]
                  : widget.hints.first)
              : 'Cari...',
          hintStyle: GoogleFonts.inter(
            color: context.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: context.textSecondary,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: context.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          filled: true,
          fillColor: context.cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
      ),
    );
  }
}