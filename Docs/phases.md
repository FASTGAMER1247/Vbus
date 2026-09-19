# Phases — Frontend Build Order (Campus Transit)

Sanjay's build order for the UI, scoped to the frontend only (never touches backend/database). Built against mock data throughout — reconciliation with the real backend is its own final phase, not threaded through the others.

---

## Phase 0: App shell and shared core — done

- Theme (design tokens from `design.md` §3/§6)
- Role-based router with login gate (`flow.md` C1/C2)
- Shared models (`core/models/`)
- Repository interfaces (`AuthRepository`, `TransportRepository`) + mock implementations
- Mock ↔ real switch point (`app/providers.dart`)

**Done when:** app launches to a login screen, any seeded demo account logs in and lands on the correct role's home.

## Phase 1: Student / Faculty flow — done

Covers `flow.md` S1–S4, screens ST-1 through ST-10.

- Home with all eligibility branches (not enrolled / fees pending / route not assigned / bus not started)
- Live tracking map with a simulated moving bus
- Route and stops list

**Done when:** a student can log in, see their bus card, watch it move on the live map, and browse their route — all against mock data.

## Phase 2: Driver flow — next

Covers `flow.md` D1–D5, screens DR-1 through DR-10. The riskiest phase, because background GPS behavior can't really be judged until it runs on a real phone with the screen locked.

- Permission onboarding (location, background location, battery settings)
- Identify bus: QR scan UI (camera view only — no real lookup yet, see `BACKEND_CHANGES.md` #6) and manual Bus ID entry
- Trip confirmation screen
- Active trip screen (GPS/network/battery status, warnings)
- Offline banner / synced message
- End trip (manual path; automatic geofence path is mocked since the backend doesn't support it yet)
- Blocked-start states (DR-10)

**Done when:** a driver can go from login through a full mock trip — identify bus, start, see live status update, end — and the permission-onboarding screens are tested against real device permission prompts (even though the GPS data itself is still mocked).

## Phase 3: Manager flow

Covers `flow.md` M1–M5, screens MG-1 through MG-14. The biggest surface area — web layout matters here (`design.md` §4.2).

- Setup: buses, drivers, routes (with route builder), assignments
- Live fleet dashboard and map
- Tracking-unavailable handling
- Trip list and summary (mocked, since the backend has no summary RPC yet — `BACKEND_CHANGES.md` #4)
- End a stuck trip

**Done when:** a manager can complete the full setup sequence (bus → driver → route → assignment) and see mock buses moving on the live fleet map, on both mobile and web layouts.

## Phase 4: Master Admin flow

Covers `flow.md` A1–A3, screens MA-1 through MA-6. Smallest surface area.

- College list and college form (including geofence fields — UI only, backend has nowhere to save them yet)
- Manager account creation (UI only — no provisioning RPC yet, `BACKEND_CHANGES.md` #7)
- Activate / deactivate / archive

**Done when:** a master admin can create a college and a manager account against mock data, and toggle college status.

## Phase 5: Design system polish

Resolve the open items in `design.md` §14 that start mattering once every role exists: brand/product name, dark-mode default for drivers, battery/update thresholds, tablet layout, route builder mobile behavior.

**Done when:** every screen across all five roles uses agreed (not "Proposed") values, and `decisions.md` records what was chosen and why.

## Phase 6: Reconciliation with the real backend

Not threaded through the earlier phases — done once, at the end, once both sides are ready.

1. Write `data/remote/remote_auth_repository.dart` and `remote_transport_repository.dart` (and equivalents for driver/manager/admin repositories built in Phases 2–4) against the same interfaces the mock layer used.
2. Swap the provider bodies in `app/providers.dart`.
3. Resolve every `⚠` flagged in `flow.md` and `design.md` — either the backend gap has closed and the real behavior gets wired in, or the MVP scope gets narrowed to match what actually exists (`prd.md` §15.4 has the list).

**Done when:** the end-to-end MVP journey (`flow.md` Part 7) runs on real phones against the real backend, not mocks.
