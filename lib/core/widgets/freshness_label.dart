import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// design.md §7.4 / §8.2: "Updated 6 sec ago", turning to a warning
/// style when stale. §9.3 defines the three tracking states this
/// reflects: Live / Delayed updates / Tracking unavailable.
class FreshnessLabel extends StatelessWidget {
  final DateTime updatedAt;
  final Duration staleAfter;

  const FreshnessLabel({
    super.key,
    required this.updatedAt,
    this.staleAfter = const Duration(seconds: 30),
  });

  @override
  Widget build(BuildContext context) {
    final age = DateTime.now().difference(updatedAt);
    final isStale = age > staleAfter;

    final color = isStale ? AppColors.statusUnavailable : AppColors.statusGood;
    final text = isStale
        ? 'Tracking unavailable · last seen ${_ago(age)}'
        : 'Live · updated ${_ago(age)}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppTypography.caption.copyWith(color: color)),
      ],
    );
  }

  String _ago(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }
}
