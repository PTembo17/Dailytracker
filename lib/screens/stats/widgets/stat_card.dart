import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final double? rate; // 0.0–1.0 for color coding the value
  final bool small;  // shrink value font for long strings

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    this.rate,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valueColor = rate != null ? AppColors.scoreColor(rate!) : cs.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: small ? 13 : 20,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
