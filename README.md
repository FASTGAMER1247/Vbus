# Vbus — Campus Transit Frontend Scaffold

College bus tracking SaaS platform.

Flutter/Dart, one app, five role-based shells. Built against **mock data
behind a swappable repository layer**, per the plan agreed earlier — this
lets UI work proceed without waiting on the backend, which currently has
six gaps versus the PRD (see `BACKEND_CHANGES.md`, `prd.md` §15.4).

## Run it

```
flutter pub get
flutter run
```

Demo logins (any college name, password is always `demo`):

| Username | Role |
|---|---|
| Sanjay | Student |
| Dr. Meera Rao | Faculty |
| Ramesh K | Driver |
| Priya Nair | Manager |
| Platform Admin | Master Admin |

## What's built

- **App shell:** theme (`app/theme/`, tokens taken straight from
  `design.md` §3/§6), router with role-based redirect (`app/router.dart`,
  implements `flow.md` C1/C2), the mock↔real switch point
  (`app/providers.dart`).
- **Core:** shared models (`core/models/`) matching `prd.md`'s glossary
  and `flow.md` Y1's trip lifecycle; a few of the domain widgets from
  `design.md` §7.4 (freshness label, trip stage badge, eligibility
  message card).
- **Data layer:** `data/repositories/` has the two abstract interfaces
  (`AuthRepository`, `TransportRepository`) every screen depends on.
  `data/mock/` implements them with seeded data and a simulated moving
  bus. `data/remote/` is empty — that's where the Supabase
  implementation goes once the backend gaps in `BACKEND_CHANGES.md` are
  closed. **Swapping mock → real is a two-line change in
  `app/providers.dart`, nothing else.**
- **Student/Faculty, fully wired:** login (C1), home with all four
  eligibility branches (S1 / ST-1–4, ST-6), live map with a moving bus
  (S2 / ST-5), route and stops (S3 / ST-9–10).
- **Driver, fully wired (Phase 2):** permission onboarding (DR-2, real
  `geolocator` permission requests — test this on a real device, not
  just the emulator), identify bus by QR scan or manual Bus ID
  (DR-3/DR-4, blocked states DR-5/D5 all reachable via the demo Bus
  IDs below), trip confirmation, active trip with live health
  indicators and warnings (DR-6/D2), offline banner (D3), manual end
  with confirmation (D4/DR-8), completed summary (DR-9).
- **Manager, Master Admin:** stub home screens only, so the router and
  role-switching work end to end. Not yet built out.

### Demo Bus IDs for the driver flow (D5 blocked states)

Enter these on the "Enter Bus ID" tab (or type them as a QR payload if
testing the scanner against a printed code) to exercise every blocked
reason without needing a real backend:

| Bus ID | Result |
|---|---|
| `023` | Succeeds — proceeds to trip confirmation |
| `999` | Bus not found |
| `011` | Bus belongs to another college |
| `007` | Bus not assigned to this driver |
| `023-busy` | Bus already has an active trip |

### Native project setup — do this before running on a device

This scaffold is Dart source only; it doesn't include the generated
`android/` and `ios/` folders. Once you run `flutter create .` in this
directory to generate them, you'll need to add, at minimum:

- **Android** (`android/app/src/main/AndroidManifest.xml`): `ACCESS_FINE_LOCATION`,
  `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, and `CAMERA`
  permissions (the last for `mobile_scanner`).
- **iOS** (`ios/Runner/Info.plist`): `NSLocationWhenInUseUsageDescription`,
  `NSLocationAlwaysAndWhenInUseUsageDescription`, and `NSCameraUsageDescription`.

Without these, `geolocator`'s permission requests and `mobile_scanner`'s
camera will fail silently or crash on a real device — this is exactly
the kind of thing worth testing early, per `prd.md` §14's test scenarios.

## What's next, in order

1. **Manager flow (M1–M5).** The biggest surface area — setup
   (buses/drivers/routes/assignments), live fleet map, tracking-unavailable
   handling, trip summaries. Web layout (design.md §4.2) matters here.
2. **Master Admin flow (A1–A3).** Smallest surface area — college
   creation/config, manager accounts, activate/deactivate.
3. **Design system open items** (`design.md` §14) will start mattering
   once more screens exist: brand/product name, dark-mode default for
   drivers, battery/update thresholds, tablet layout.

## Reconciling with the backend, later

When the backend catches up (or the team decides to scope the MVP down
to match it — see `prd.md` §15.4), the reconciliation work is:

1. Write `data/remote/remote_auth_repository.dart` and
   `remote_transport_repository.dart` against the same two interfaces.
2. Swap the two provider bodies in `app/providers.dart`.
3. Everywhere a screen assumed a feature that doesn't exist yet (QR
   bus lookup, campus geofence, real ERP data, trip summaries) —
   flagged with `⚠` throughout `flow.md` and `design.md` — either wire
   it to the real thing or fall back to the manual/mock behavior the
   comments in this codebase describe.

No screen should need to be rewritten for this — that's the point of
the repository layer.
