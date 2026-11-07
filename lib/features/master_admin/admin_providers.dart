import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/models/admin_models.dart';

/// Master Admin platform aggregate metrics (prd.md Module 13).
final platformSummaryProvider = FutureProvider<PlatformSummary>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPlatformSummary();
});

/// All colleges registered on the platform (flow.md A1, A3).
final collegesProvider = FutureProvider<List<College>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getColleges();
});

/// Specific college details by ID.
final collegeDetailProvider =
    FutureProvider.family<College?, String>((ref, collegeId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getCollegeById(collegeId);
});

/// Transport managers, optionally filtered by college ID (flow.md A2).
final adminManagersProvider =
    FutureProvider.family<List<CollegeManagerProfile>, String?>((ref, collegeId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getManagers(collegeId: collegeId);
});
