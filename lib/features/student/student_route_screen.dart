import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import 'student_providers.dart';

/// flow.md S3 — View my route and stops (Screens ST-9 / ST-10).
/// Visual live stop-by-stop progress timeline with dynamic ETAs.
class StudentRouteScreen extends ConsumerWidget {
  const StudentRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(myRouteProvider);
    final tripAsync = ref.watch(myActiveTripProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route & Stop Schedule'),
        backgroundColor: AppColors.studentAccent,
      ),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Something went wrong.')),
        data: (route) {
          if (route == null) {
            return const Center(child: Text('Route not assigned yet.'));
          }

          final trip = tripAsync.value;
          final progress = trip != null ? ref.watch(routeProgressProvider(trip.id)) : null;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Route Header Summary
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.studentAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.route, color: AppColors.studentAccent, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(route.name, style: AppTypography.heading),
                                const SizedBox(height: 2),
                                Text(
                                  '${route.stops.length} stops • ${route.estimatedDistanceKm ?? 12.4} km total',
                                  style: AppTypography.bodySmall.copyWith(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          if (trip != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Text(
                                'BUS EN ROUTE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('Live Stops Timeline', style: AppTypography.heading),
                  const SizedBox(height: 12),

                  // Stop Timeline
                  ...List.generate(route.stops.length, (index) {
                    final stop = route.stops[index];
                    final isLast = index == route.stops.length - 1;
                    final isMine = isLast; // In demo, student's assigned stop is Bharat Nagar (last)

                    final stopProgress = progress?.allStops.where((p) => p.stop.id == stop.id).firstOrNull;
                    final stage = stopProgress?.stage ?? StopStage.upcoming;
                    final isPassed = stage == StopStage.passed;
                    final isNext = stage == StopStage.next || stage == StopStage.atStop;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left column: Icon and vertical connector line
                          SizedBox(
                            width: 44,
                            child: Column(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isPassed
                                        ? AppColors.statusGood
                                        : (isNext
                                            ? AppColors.studentAccent
                                            : (isMine ? Colors.deepOrange : Colors.grey.shade300)),
                                    shape: BoxShape.circle,
                                    border: isNext
                                        ? Border.all(color: Colors.green.shade200, width: 3)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: isPassed
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : (isMine
                                          ? const Icon(Icons.star, size: 14, color: Colors.white)
                                          : Text(
                                              '${stop.order}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isNext ? Colors.white : Colors.grey.shade700,
                                              ),
                                            )),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: isPassed ? AppColors.statusGood : Colors.grey.shade300,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Right column: Stop Card details
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isNext
                                      ? Colors.blue.shade50
                                      : (isMine ? Colors.orange.shade50 : Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isNext
                                        ? AppColors.studentAccent
                                        : (isMine ? Colors.orange.shade300 : Colors.grey.shade200),
                                    width: isNext || isMine ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                stop.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: isPassed ? Colors.grey.shade600 : Colors.black87,
                                                ),
                                              ),
                                              if (isMine) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.deepOrange,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'YOUR STOP',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isPassed
                                                ? 'Departed'
                                                : (stop.expectedTime != null
                                                    ? 'Scheduled: ${stop.expectedTime}'
                                                    : 'Pickup Point'),
                                            style: AppTypography.caption.copyWith(
                                              color: isPassed ? Colors.grey : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Right badge (ETA or Status)
                                    if (isPassed)
                                      const Text(
                                        'Passed',
                                        style: TextStyle(
                                          color: AppColors.statusGood,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    else if (stopProgress != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isNext ? AppColors.studentAccent : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          stage == StopStage.atStop
                                              ? 'Arriving'
                                              : '~${stopProgress.estimatedMinutes} min',
                                          style: TextStyle(
                                            color: isNext ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
