# memory.md — Codebase Map (Campus Transit frontend)

Read this before touching the repo. It describes what's actually **in the code today** — file by file, what each defines. Product plan lives in `prd.md`/`flow.md`/`design.md`; build order lives in `phases.md`; stack rationale lives in `techstack.md`.

---

## Repo root

- `pubspec.yaml` — deps: `flutter_riverpod`, `go_router`, `flutter_map` + `latlong2`, `geolocator`, `mobile_scanner`, `intl`, `uuid`
- `lib/main.dart` — entry point. Wraps the app in `ProviderScope`, builds `MaterialApp.router` from `appRouterProvider` and `AppTheme`

## lib/app/ — app shell

- **`router.dart`** — `appRouterProvider` (`Provider<GoRouter>`). Watches `authControllerProvider`. `redirect` logic: not logged in → `/login`; logged in and on `/login` → `user.role.homeRoute`; logged in but outside the role's path prefix → sent back. Routes: `/login`, `/student`, `/student/live`, `/student/route`, `/driver`, `/manager`, `/admin`. `_prefixFor(UserRole)` maps role → allowed path prefix.
- **`providers.dart`** — **the swap point.** `authRepositoryProvider` and `transportRepositoryProvider` currently return `Mock*Repository`. `AuthController` (`StateNotifier<AppUser?>`) wraps `AuthRepository` for login/logout/session-restore; `authControllerProvider` exposes it.
- **`theme/app_colors.dart`** — `AppColors`: neutrals (light/dark), five role accents (`accentFor(UserRole)`), five status colors (good/warning/critical/unavailable/info).
- **`theme/app_typography.dart`** — `AppTypography` (display/title/heading/body/bodySmall/caption/driverPrimary), `AppSpacing` (xs..xxxl), `AppRadius` (input/card/sheet).
- **`theme/app_theme.dart`** — `AppTheme.light()` / `.dark()` build `ThemeData` from the tokens above.

## lib/core/ — shared across every role

- **`models/role.dart`** — `UserRole` enum (masterAdmin/manager/driver/student/faculty), `.label`, `.homeRoute`.
- **`models/app_user.dart`** — `AppUser` (id, name, role, collegeId, collegeName).
- **`models/trip_stage.dart`** — `TripStage` enum, the full 9-stage lifecycle plus 3 terminal variants, `.label`, `.isActive` / `.isTerminal`.
- **`models/transport_models.dart`** — `Stop`, `TransportRoute`, `Bus`, `DriverProfile`, `LiveLocation` (has `.isStale()`), `Trip` (has `.copyWith`), `EligibilityStatus` enum.
- **`widgets/freshness_label.dart`** — `FreshnessLabel(updatedAt, staleAfter)`. Renders "Live · updated Xs ago" or "Tracking unavailable · last seen Xs ago".
- **`widgets/trip_stage_badge.dart`** — `TripStageBadge(stage)`. Colored pill.
- **`widgets/eligibility_message_card.dart`** — `EligibilityMessageCard(status)`; static `messageFor(status)` holds the standard wording from `design.md` §12.
- **`widgets/primary_button.dart`** — `PrimaryButton(label, onPressed, isLoading, accentColor)`.

## lib/data/ — the swappable data layer

- **`repositories/auth_repository.dart`** — abstract `AuthRepository` (login/logout/restoreSession), `AuthException`.
- **`repositories/transport_repository.dart`** — abstract `TransportRepository` (getMyEligibility/getMyRoute/getMyActiveTrip/watchLiveLocation).
- **`mock/mock_seed.dart`** — `MockSeed`: one college (VJIT), one route (Route 7, 4 stops), one bus, one driver, five demo `AppUser`s (one per role — password is always `demo`), `activeTrip()`.
- **`mock/mock_auth_repository.dart`** — `MockAuthRepository implements AuthRepository`. Matches the entered username to a seeded `AppUser.name` (case-insensitive); password must be `demo`.
- **`mock/mock_transport_repository.dart`** — `MockTransportRepository implements TransportRepository`. `watchLiveLocation()` is a `Stream` that interpolates a position between consecutive stops every 2s (`_lerp`, `_bearing` helpers) — this is what makes the live map show a moving bus.
- **`remote/`** — empty. `remote_auth_repository.dart` and `remote_transport_repository.dart` go here once the backend is ready (Phase 6 in `phases.md`).

## lib/features/ — one folder per role, never cross-imports

- **`student/login_screen.dart`** — `LoginScreen`. Actually shared by every role today (everyone lands here first) — worth moving to a `features/common/` folder once that exists.
- **`student/student_providers.dart`** — `myEligibilityProvider`, `myRouteProvider`, `myActiveTripProvider` (`FutureProvider`), `liveLocationProvider` (`StreamProvider.family<LiveLocation, String>` keyed by trip id). All built on `transportRepositoryProvider` — **this is the pattern to copy** for driver/manager/admin providers.
- **`student/student_home_screen.dart`** — `StudentHomeScreen`. Nested `.when()` on eligibility → route → trip, each with its own loading/error/data branch. `_HomeContent` is the private widget for the happy path.
- **`student/student_live_map_screen.dart`** — `StudentLiveMapScreen` + `_LiveMap`. Uses `flutter_map` with `TileLayer` (OpenStreetMap tiles), `PolylineLayer` (route), `MarkerLayer` (stops + bus, bus icon rotated by heading).
- **`student/student_route_screen.dart`** — `StudentRouteScreen`. Simple stop list.
- **`driver/driver_home_screen.dart`, `manager/manager_home_screen.dart`, `master_admin/master_admin_home_screen.dart`** — stubs. Each just reads `authControllerProvider` and shows a placeholder. Replace the body when building that role's phase.

## Conventions to follow when extending this code

1. New repository method → add to the abstract interface first, implement it in the `Mock*` class, only then call it from a screen.
2. New role-scoped data need → add a `<role>_providers.dart` next to that role's screens, shaped like `student_providers.dart` (thin `FutureProvider`/`StreamProvider` wrappers over the repository).
3. New screen → register its route in `app/router.dart`, inside that role's path prefix.
4. Colors/type/spacing → always reference `app/theme/`, never hardcode a hex or font size in a screen.
5. Anything mocked because the backend doesn't support it yet → leave a comment pointing at the relevant `BACKEND_CHANGES.md` item, same as the existing mock files do.
