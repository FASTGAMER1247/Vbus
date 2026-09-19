import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../core/models/transport_models.dart';
import '../../core/widgets/eligibility_message_card.dart';
import '../../core/widgets/trip_stage_badge.dart';
import 'student_providers.dart';

/// flow.md S1 — Home and eligibility. Covers screens ST-1 (home),
/// ST-2/ST-3/ST-4 (not enrolled / fees pending / route not assigned,
/// all via EligibilityMessageCard) and ST-6 (bus not started).
///
/// design.md §5.1: bottom nav has Home / Live / Route / Profile — this
/// scaffold wires Home and Route; Live is reached from the bus card
/// per S1's flow ("Has the bus started? → S2"), and Profile is a stub.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final eligibility = ref.watch(myEligibilityProvider);
    final route = ref.watch(myRouteProvider);
    final trip = ref.watch(myActiveTripProvider);

    final accent = user == null ? AppColors.studentAccent : AppColors.accentFor(user.role);

    return Scaffold(
      appBar: AppBar(
        title: Text('Good morning, ${user?.name ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: eligibility.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const EligibilityMessageCard(status: EligibilityStatus.cannotCheckRightNow),
        data: (status) {
          if (status != EligibilityStatus.eligible) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: EligibilityMessageCard(status: status),
            );
          }

          return route.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => const Center(child: Text('Something went wrong.')),
            data: (myRoute) {
              if (myRoute == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: EligibilityMessageCard(status: EligibilityStatus.routeNotAssigned),
                );
              }

              return trip.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => const Center(child: Text('Something went wrong.')),
                data: (activeTrip) => _HomeContent(
                  route: myRoute,
                  trip: activeTrip,
                  accent: accent,
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Live'),
          NavigationDestination(icon: Icon(Icons.alt_route), label: 'Route'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        onDestinationSelected: (i) {
          if (i == 1) context.push('/student/live');
          if (i == 2) context.push('/student/route');
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final TransportRoute route;
  final Trip? trip;
  final Color accent;

  const _HomeContent({required this.route, required this.trip, required this.accent});

  @override
  Widget build(BuildContext context) {
    final myStop = route.stops.first; // flow.md doesn't specify which stop is "mine" in the mock — first stop stands in

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🚌', style: AppTypography.title),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bus ${trip?.bus.busNumber ?? '—'} · ${route.name}',
                        style: AppTypography.heading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Your stop: ${myStop.name}', style: AppTypography.bodySmall),
                const SizedBox(height: 12),
                if (trip != null) ...[
                  TripStageBadge(stage: trip!.stage),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: () => context.push('/student/live'),
                    child: const Text('View live map'),
                  ),
                ] else
                  // flow.md S4: "Your bus has not started yet"
                  const Text(
                    'Your bus has not started yet.',
                    style: AppTypography.bodySmall,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Transport status: Active', style: AppTypography.bodySmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Route and stops'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/student/route'),
          ),
        ),
      ],
    );
  }
}
