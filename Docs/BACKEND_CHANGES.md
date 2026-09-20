# Backend Changes & RPC Reference

**Status:** Resolved (Updated 20 September 2026)  
**Backend Repository:** `EshwarAditya/BUS_APP` (Supabase / PostgreSQL + TypeScript Edge Functions)  
**Total RPC Count:** 62 (Expanded from 30)

---

## 1. P0 MVP Gaps — All Resolved

All 9 critical gaps previously blocking full end-to-end MVP reconciliation against the real backend have been resolved by the backend team.

| # | Previous Gap | Resolution / New Backend Contract | Impact & Frontend Mapping |
|---|---|---|---|
| **1** | No ERP integration (fees read from native `student_bus_fees` table) | `verify_and_link_student`, `record_erp_sync_batch` RPCs added | Student eligibility checks link directly with verified ERP sync records. |
| **2** | Public student sign-up without ERP roll-number validation | `verify_and_link_student` requires student roll number / ERP ID | Enforces verified student onboarding; prevents unauthenticated public sign-up abuse. |
| **3** | No campus geofence or auto-complete RPC (only stop-level 75m/100m) | `colleges` table now stores `campus_latitude` & `campus_longitude`; added `update_college_campus_geofence` RPC | Enables campus-level geofencing (Y5) and automatic trip completion upon returning to college. |
| **4** | No trip summary RPC | `get_trip_summary` RPC added | Manager (M4) and driver (DR-9) trip completion summaries can now fetch real post-trip metrics directly. |
| **5** | Trips could not be auto-generated; manager had to schedule manually | `generate_daily_trips` RPC added | Automated daily trip scheduling is now supported. |
| **6** | `start_trip` required `p_trip_id`; no bus QR / scan lookup | `start_trip_by_bus(qr_code)` RPC added | Exactly satisfies `flow.md` D1 / DR-3 QR scan & manual bus ID trip initiation. |
| **7** | No client-callable account provisioning RPC for Master Admin / Manager | `provision_account`, `set_account_active_status` RPCs added | Master Admin (A2) and Manager setup flows can now provision and activate/deactivate accounts without service-role key leaks. |
| **8** | Driver device health telemetry was incomplete | `record_tracking_location` now accepts `p_battery_percentage` and `p_network_status` | Feeds live driver device health HUD (DR-6) and manager fleet monitoring (M2 / M3). |
| **9** | No aggregate fleet status query for manager dashboard/map | `get_fleet_status` RPC added | Powers Manager dashboard counts (active, offline, completed) and live fleet map (M2). |

---

## 2. Additional P2 / "Later" Capabilities Implemented Ahead of Schedule

The backend has implemented several advanced features originally slated for post-MVP:

- **Feedback & Complaints (PRD Module 17):** Full submission, categorization, and review pipeline.
- **Bus Maintenance Management (PRD Module 18):** Vehicle defect reporting, service intervals, repair logs, and pre-trip checklists.
- **Document & Licence Expiry Alerts (PRD Module 19):** Expiry tracking for RC, fitness, insurance, permits, and driver licenses with warning thresholds.
- **Trip Playback (PRD Module 11 / 21):** Historical GPS route replay for completed trips.
- **Faculty Granular Permissions & Failover Tracking:** Faculty can take over GPS tracking if a driver phone dies, and return control seamlessly.
- **Dynamic Multi-Tier ETA & 150m Corridor Deviation:** Real-time route deviation detection and predictive ETA.
- **Emergency SOS (Module 15):** Incident creation with 60s anti-spam cooldown and manager broadcast.
- **Push Notification Infrastructure (Module 14):** FCM device token registration and notification dispatch triggers.

---

## 3. Frontend Reconciliation Impact (Phase 6)

With these RPCs in place, **Phase 6 (Backend Reconciliation)** is fully unblocked:
- Every abstract method in `data/repositories/` maps 1:1 to a real Supabase RPC or table query.
- When Phase 3 (Manager) and Phase 4 (Master Admin) mock implementations are complete, swapping mock to remote in `app/providers.dart` will be seamless.
