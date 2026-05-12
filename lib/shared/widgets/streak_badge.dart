import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (streak >= 14) {
      color = AppColors.green400;
    } else if (streak >= 5) {
      color = AppColors.amber400;
    } else {
      color = AppColors.red400;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(
          '$streak',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}
