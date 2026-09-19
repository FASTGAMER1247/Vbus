import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: CampusTransitApp()));
}

/// Root widget.
///
/// Everything role-specific lives under lib/features/<role>/. This file,
/// app/router.dart and app/theme/ are the only things every role shares
/// at the app-shell level — see lib/core/ and lib/data/ for the rest of
/// the shared layer (auth, models, the mock/real data switch).
class CampusTransitApp extends ConsumerWidget {
  const CampusTransitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Campus Transit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Design open question (design.md §14): should the driver role
      // default to dark? Left as system-following until that's decided.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
