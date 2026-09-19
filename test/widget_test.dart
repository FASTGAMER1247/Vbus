// Basic smoke test for CampusTransitApp.
//
// The generated default test referenced MyApp which doesn't exist in this
// project — replaced with a minimal pump of CampusTransitApp to verify
// the widget tree builds without errors.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_transit/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CampusTransitApp()));
    // Login screen should render
    expect(find.text('Campus Transit'), findsOneWidget);
  });
}
