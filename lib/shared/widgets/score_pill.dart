import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final double? rate; // 0.0–1.0, drives color; if null defaults to green

  const ScorePill({super.key, required this.label, required this.value, this.rate});

  @override
  Widget build(BuildContext context) {
    final r = rate ?? 1.0;
    final bg = AppColors.scoreBg(r);
    final fg = AppColors.scoreColor(r);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.radiusFull,
      ),
      child: Text(
        value.isEmpty ? label : '$label $value',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}
