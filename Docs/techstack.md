# Tech Stack — Frontend (Campus Transit)

Written from the UI/frontend side, since that's Sanjay's scope on the team. Backend stack is included for context only — owned and decided by the backend teammate (EshwarAditya).

---

## Frontend stack

| Layer | Choice | Why |
| --- | --- | --- |
| Language / framework | **Flutter / Dart** | One codebase covers Android, iOS, and web — needed because Manager and Master Admin also require web dashboards, not just mobile |
| State management | **Riverpod** (`flutter_riverpod`) | Compile-safe providers, easy to swap an implementation (mock → real) behind one interface, works the same on mobile and web |
| Routing | **go\_router** | Declarative routing with a single `redirect` callback — implements the role-based routing and login gate (`flow.md` C1/C2) in one place |
| Maps | **flutter\_map + OpenStreetMap** (`flutter_map`, `latlong2`) | Free, no billing setup required, good enough for the demo. `google_maps_flutter` was the alternative but needs billing configured |
| Driver GPS | **geolocator** | Standard Flutter location plugin; background tracking support is what makes or breaks the driver flow, so this gets tested on real phones early |
| Bus QR scanning | **mobile\_scanner** | Camera-based QR scanning for `DR-3`. UI-only for now — the backend has no bus-lookup RPC to resolve a scanned code to a trip yet (see `BACKEND_CHANGES.md` #6) |
| Backend client (once wired up) | **supabase\_flutter** | Official Flutter package for Supabase — covers auth, RPC calls, and Realtime subscriptions in one client |
| Utilities | `intl`, `uuid` | Date/time formatting, generating client-side IDs (e.g. offline GPS point de-duplication once real tracking is wired up) |
| Lint / static analysis | `flutter_lints` | Standard Flutter lint set |

## Architectural pattern

**Repository interfaces + swappable implementations.** Every screen depends on an abstract repository (`AuthRepository`, `TransportRepository`, more to come as Driver/Manager/Admin are built), never on a concrete implementation. Two implementations exist per interface:

- `data/mock/` — what every screen runs against today
- `data/remote/` — the real Supabase implementation, written once the backend gaps in `BACKEND_CHANGES.md` are closed

Switching between them is a two-line change in `app/providers.dart`. This is what makes "build the UI now, link it up later" (the team's current plan) work without a rewrite.

## Backend stack (for context — not Sanjay's scope)

| Layer | Choice |
| --- | --- |
| Database | Postgres via **Supabase** |
| Auth | Supabase Auth |
| Realtime | Supabase Realtime (`postgres_changes` on live-location and a few other tables) |
| Service layer | TypeScript |
| API surface | 30 documented RPCs (`frontend-contracts/rpc_catalog.json`) plus some direct table access under RLS |
| Storage | Supabase Storage, private buckets for bus documents and driver photos |

Full detail: `architecture.md` (not written yet — that's the backend/ERP team's document to agree on) and `BACKEND_CHANGES.md`.

## Decisions still open on the frontend side

- **Platforms for first release:** Android only, or Android + iOS? (iOS builds need a Mac — see `prd.md` §17)
- **Dark theme default for the driver role** (`design.md` §14)
- **Web layout details for Manager/Master Admin** — confirmed web is needed (`prd.md` §5), exact desktop breakpoints are "Proposed" in `design.md` §2
