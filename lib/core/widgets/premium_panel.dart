import 'package:flutter/material.dart';

class PremiumPanel extends StatelessWidget {
  final Widget child;
  final bool isDesktop;
  const PremiumPanel({super.key, required this.child, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
