import 'package:flutter/material.dart';
import '../../app/theme/app_typography.dart';
import '../models/transport_models.dart';

/// design.md §7.4 "Eligibility message card" + §12 standard wording.
/// Renders the neutral message for each branch of flow.md S1 that
/// isn't the happy path. Returns null for [EligibilityStatus.eligible]
/// so callers can do `if (card != null) return card;`.
class EligibilityMessageCard extends StatelessWidget {
  final EligibilityStatus status;
  const EligibilityMessageCard({super.key, required this.status});

  static String? messageFor(EligibilityStatus status) {
    switch (status) {
      case EligibilityStatus.eligible:
        return null;
      case EligibilityStatus.notEnrolled:
        return 'You are not enrolled for college transport.';
      case EligibilityStatus.feesPending:
        // prd.md §12: final wording follows the college's configured policy.
        return 'Bus tracking is unavailable while transport fees are pending.';
      case EligibilityStatus.routeNotAssigned:
        return 'Your route is not assigned yet. Please contact the transport office.';
      case EligibilityStatus.cannotCheckRightNow:
        return "We can't check your transport details right now. Try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = messageFor(status);
    if (message == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppTypography.body)),
          ],
        ),
      ),
    );
  }
}
