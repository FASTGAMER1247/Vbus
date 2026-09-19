import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../models/trip_stage.dart';

/// design.md §7.4: "Scheduled · Started · Leaving college · On route
/// · Final stops · Returning · Approaching · Completed · Ended
/// manually." Neutral colors for normal stages, green for Completed,
/// grey for Ended manually — §9.2.
class TripStageBadge extends StatelessWidget {
  final TripStage stage;
  const TripStageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      TripStage.completed => AppColors.statusGood,
      TripStage.endedManuallyByDriver ||
      TripStage.endedManuallyByManager ||
      TripStage.cancelled =>
        AppColors.statusUnavailable,
      _ => AppColors.statusInfo,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        stage.label,
        style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
