import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TodayProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const TodayProgressBar({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : done / total;
    final pct = (percent * 100).round();
    final color = AppColors.scoreColor(percent);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              total == 0 ? 'No tasks yet' : '$done of $total done today',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            color: color,
            backgroundColor: cs.outline.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
