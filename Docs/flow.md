# User Flows
## College Transportation Management Platform

**Status:** Draft v2 (checked against the backend)
**Last updated:** 19 September 2026

> This document describes **how each person moves through the product, step by step**, including what happens when things go wrong.
> It is the main input for building screens: each step in a flow usually becomes a screen or a state.
> Related files: `prd.md` (what the product does) · `design.md` (how it looks) · `architecture.md` (how it's built)
>
> **Checked against the real backend on 19 Sept 2026.** Flows marked ⚠ below don't work end-to-end against the backend as it stands today — see the note under that flow and Part 11 for the full list.

**Labels:** **[MVP]** = first version · **[Later]** = after the MVP

---

## How to Read This Document

Every flow follows the same pattern:

- **Actor:** who is doing it
- **Trigger:** what starts it
- **Before:** what must already be true
- **Steps:** the normal path
- **Branches:** what can happen differently
- **End state:** how it finishes

Diagram notation:
```
[ Screen or state ]     → a place the user sees
( Decision? )           → a yes/no point
  ↓                     → the next step
```

---

## Flow Index

| # | Flow | Actor | Priority |
|---|---|---|---|
| C1 | Open app and log in | All roles | MVP |
| C2 | Role routing after login | All roles | MVP |
| C3 | Session expiry and logout | All roles | MVP |
| S1 | Student/faculty home and eligibility | Student, Faculty | MVP |
| S2 | Track my bus live | Student, Faculty | MVP |
| S3 | View my route and stops | Student, Faculty | MVP |
| S4 | Bus not started / tracking unavailable | Student, Faculty | MVP |
| D1 | Start a trip | Driver | MVP |
| D2 | During a trip | Driver | MVP |
| D3 | Offline during a trip | Driver | MVP |
| D4 | End a trip | Driver | MVP |
| D5 | Blocked from starting a trip | Driver | MVP |
| M1 | Set up buses, drivers, routes and assignments | Manager | MVP |
| M2 | Monitor the live fleet | Manager | MVP |
| M3 | Respond to "Tracking unavailable" | Manager | MVP |
| M4 | Review a trip summary | Manager | MVP |
| M5 | End a stuck trip | Manager | MVP |
| A1 | Create and configure a college | Master Admin | MVP |
| A2 | Create a manager account | Master Admin | MVP |
| A3 | Activate, deactivate or archive a college | Master Admin | MVP |
| Y1 | Trip lifecycle | System | MVP |
| Y2 | Location updates | System | MVP |
| Y3 | Offline sync | System | MVP |
| Y4 | Tracking watchdog | System | MVP |
| Y5 | Geofence and automatic completion | System | MVP |
| Y6 | Eligibility check with the ERP | System | MVP |
| E2E | Full MVP journey | Everyone | MVP |
| L1–L8 | Later flows (notifications, emergency, issues, complaints, etc.) | Various | Later |

---

# PART 1: COMMON FLOWS

## C1. Open the app and log in [MVP]

**Actor:** any user
**Trigger:** opens the app
**Before:** has an account (admin-created, or from the college ERP)

```
[ App opens ]
     ↓
( Already logged in with a valid session? )
     ├─ Yes → go to C2 (role routing)
     └─ No
          ↓
   [ Login screen ]
          ↓
   User picks/enters college, enters credentials
          ↓
   ( Credentials valid? )
     ├─ No  → [ Clear, non-revealing error ] → try again
     └─ Yes
          ↓
   ( College active? )
     ├─ No  → [ "This college's access is unavailable" ]
     └─ Yes → C2
```

**Branches**
- Wrong password: a general error that does not say which part was wrong.
- No internet: a clear message that a connection is needed to log in.
- Deactivated college: user cannot enter.

---

## C2. Role routing after login [MVP]

**Trigger:** successful login
**Steps:** the system returns the user's **role** and **college**, and the app opens that role's home.

```
              [ Logged in ]
                    ↓
          ( What is the role? )
   ┌────────┬───────┼─────────┬──────────────┐
   ▼        ▼       ▼         ▼              ▼
Student  Faculty  Driver   Manager     Master Admin
 home     home     home      home          home
  (S1)    (S1)     (D1)      (M2)          (A1)
```

**Rules**
- A user only ever sees their own role's screens.
- Faculty with extra permissions see the additional features they were granted **[Later]**.
- If the role is missing or unrecognised, the user sees an error and is logged out.

---

## C3. Session expiry and logout [MVP]

```
[ User is using the app ]
        ↓
( Session expired? )
   ├─ No → continue
   └─ Yes → [ "Please log in again" ] → C1

[ User taps Log out ]
        ↓
( Driver with an active trip? )
   ├─ Yes → [ Warning: "A trip is active. Logging out will stop tracking." ]
   │            ├─ Cancel → stay
   │            └─ Confirm → tracking stops, logs out
   └─ No → logs out → C1
```

---

# PART 2: STUDENT AND FACULTY FLOWS

## S1. Home and eligibility [MVP]

**Actor:** student or faculty
**Trigger:** lands on home after login
**Before:** logged in

The system already knows the person's transport status, route, bus and stop. The user does not search for anything.

```
[ Home loads ]
      ↓
( Enrolled for transport? )
   ├─ No  → [ "You are not enrolled for college transport" ]   (end)
   └─ Yes
        ↓
( Transport fees valid? )
   ├─ No  → [ Message based on the college's policy ]          (end or limited view)
   └─ Yes
        ↓
( Route and bus assigned? )
   ├─ No  → [ "Your route is not assigned yet. Contact transport office." ]   (end)
   └─ Yes
        ↓
[ Home: my bus, my route, my stop, trip status ]
        ↓
( Has the bus started its trip? )
   ├─ Yes → S2 (live tracking)
   └─ No  → S4 (not started yet)
```

**What the home shows [MVP]:** assigned bus, assigned route, pickup point, transport status, trip status.

**Branches**
- If the ERP cannot be reached, the app uses the last known eligibility if available. Otherwise it shows a "cannot check right now" message with a retry option.

---

## S2. Track my bus live [MVP]

**Actor:** student or faculty
**Trigger:** opens the live view, or taps the bus card on home
**Before:** eligible, and the bus has an active trip

```
[ Live view opens ]
      ↓
[ Map with: my bus location, my route, my pickup stop ]
      ↓
[ ETA to my stop ]
      ↓
Bus location updates on the map as new points arrive
      ↓
( Bus reaches / passes my stop? )
   ├─ No  → keep updating
   └─ Yes → [ "Bus has reached your stop" / updated status ]
      ↓
( Trip completed? )
   ├─ No  → keep updating
   └─ Yes → [ "Trip completed" ]
```

**Rules**
- The user can only see their own assigned bus. There is no bus search and no way to pick another route.
- The map updates without the user refreshing.
- The current trip stage (started, on route, returning, completed) is visible.

**Branches**
- Location stops arriving → S4.
- Internet lost on the student's phone → the map shows the last known position with "Last updated: …" and reconnects automatically.

---

## S3. View my route and stops [MVP]

```
[ Home ] → tap "Route" 
      ↓
[ Route map + ordered list of stops ]
      ↓
[ My stop is highlighted ]
      ↓
Tap a stop → [ Stop details: name, expected time if available ]
```

**Later:** per-stop delay information ("usually 7:42, today 7:55") **[Later]**.

---

## S4. Bus not started, or tracking unavailable [MVP]

**Trigger:** the student opens live view when there is nothing to show

```
[ Live view opens ]
      ↓
( Bus has an active trip? )
   ├─ No  → [ "Your bus has not started yet" + route info ]
   └─ Yes
        ↓
( Receiving location recently? )
   ├─ Yes → S2
   └─ No  → [ "Tracking unavailable. Last known location shown." ]
```

**Rules**
- The wording is neutral. It never blames the driver.
- If tracking returns, the view updates automatically.
- If the last trip has just finished, the user sees "Trip completed".

---

# PART 3: DRIVER FLOWS

## D1. Start a trip [MVP] ⚠

**Actor:** driver
**Trigger:** opens the app to begin a shift
**Before:** logged in; a bus and route are assigned to this driver; **a trip for this driver already exists with status `scheduled`** — the backend has no way for the driver's own action to create one

> **Backend gap:** `start_trip` only accepts a trip ID (`p_trip_id`). There's no bus-lookup RPC, so "scan Bus QR" can't resolve to a trip yet. Until the backend adds a bus-code lookup, this flow has to become "pick today's scheduled trip" (manual Bus ID / trip selection) instead of QR-first.

```
[ Driver home ]
      ↓
( First trip: location permissions granted? )
   ├─ No  → [ Permission guide: location, background location,
   │           battery settings ] → user grants → continue
   └─ Yes
      ↓
[ Identify the bus ]
   ├─ Scan Bus QR
   └─ or enter Bus ID manually
      ↓
( Bus found and in the driver's college? )
   ├─ No  → D5
   └─ Yes
      ↓
( Bus assigned to this driver? )
   ├─ No  → D5
   └─ Yes
      ↓
( Bus already has an active trip? )
   ├─ Yes → D5
   └─ No
      ↓
[ Trip confirmation ]
     Driver → Bus → Route → College → Shift
      ↓
Driver taps START TRIP
      ↓
[ Active trip screen ]  → D2
```

**Rules**
- Background location permission is only asked here, from drivers, when a trip is about to start.
- If permissions are refused, the driver is told the trip cannot track and how to fix it.
- **[Later]** A pre-trip inspection checklist appears before START TRIP (L4).
- **[Later]** If the bus or driver has an expired required document, the start may be blocked depending on college policy.

---

## D2. During a trip [MVP]

**Actor:** driver
**Trigger:** trip has started

```
[ Active trip screen ]
      ↓
Phone sends location continuously
      ↓
Screen shows:
   • Trip stage
   • GPS status (active / weak / unavailable)
   • Network status (online / weak / offline)
   • Battery level
   • Last sync time
      ↓
( Battery low? )
   ├─ Yes → [ Warning: "Battery 15%. Tracking is active. Please connect charger." ]
   └─ No
      ↓
( Battery critical? )
   ├─ Yes → [ Critical warning ]
( GPS weak / lost? )
   ├─ Yes → [ GPS warning, last known location ]
( Network lost? )
   ├─ Yes → D3
      ↓
Trip continues until D4
```

**Rules**
- The screen is intentionally simple. The driver should not need to interact while driving.
- Tracking continues with the screen locked and the app in the background.
- Warnings are clear and short.

**Trip stages the driver moves through (mostly automatic)**
`Started → Leaving college → On route → Final stops → Returning → Approaching college → College geofence → Completed`

---

## D3. Offline during a trip [MVP]

```
[ Network lost during trip ]
      ↓
[ Driver sees "Offline. Tracking continues." ]
      ↓
Phone keeps recording location and stores it on the phone
      ↓
( Network returns? )
   ├─ No  → keep storing
   └─ Yes → stored points upload automatically
              ↓
        [ "Synced" ] → normal tracking resumes
```

**Rules**
- The driver does not need to do anything.
- No location points are lost.
- The manager may see "Tracking unavailable" during the gap, and the full path fills in after sync.

---

## D4. End a trip [MVP]

**Path A: automatic (normal)**
```
Bus returns to college
      ↓
System detects the geofence (Y5)
      ↓
Trip completes automatically
      ↓
[ Driver sees "Trip completed" + short summary ]
      ↓
Tracking stops → [ Driver home ]
```

**Path B: manual**
```
Driver taps END TRIP
      ↓
[ Confirm: "End this trip?" ]
      ├─ Cancel → stay in trip
      └─ Confirm
            ↓
      ( Bus inside the college geofence? )
         ├─ Yes → trip completes normally
         └─ No  → [ "Ending the trip outside the college" — trip marked ended manually ]
            ↓
      Tracking stops → [ Driver home ]
```

---

## D5. Blocked from starting a trip [MVP]

| Reason | What the driver sees |
|---|---|
| Bus not found | "This bus could not be found. Check the code or Bus ID." |
| Bus belongs to another college | "This bus is not available." |
| Bus not assigned to this driver | "This bus is not assigned to you. Contact your manager." |
| Bus already has an active trip | "This bus already has a trip in progress." |
| Location permission not granted | "Location access is needed to start a trip." + how to enable |
| **[Later]** Expired required document | "Trip cannot start: a required document has expired." |

The driver can try again, enter the Bus ID manually, or go back.

---

# PART 4: MANAGER FLOWS

## M1. Set up buses, drivers, routes and assignments [MVP]

**Actor:** manager
**Before:** logged in; the college exists (created by Master Admin)

```
[ Manager home ]
      ↓
Suggested setup order:

  1. ADD BUSES
     [ Bus list ] → Add bus → [ Bus form ] → Save → bus appears in list
                              (bus gets its QR)
       ↓
  2. ADD DRIVERS
     [ Driver list ] → Add driver → [ Driver form ] → Save
       ↓
  3. CREATE ROUTES
     [ Route list ] → Add route → [ Route builder ]
          • name
          • add stops in order (with locations)
          • morning / evening
          • estimated distance and duration
       → Save
       ↓
  4. ASSIGN
     [ Assignment screen ]
          Driver ↔ Bus ↔ Route
       → Save
       ↓
  5. CREATE TODAY'S TRIP  ⚠ not yet automatic
     [ Trip list ] → Add trip → pick bus/route/driver/shift → Save
       ↓
  Ready for the driver to start a trip
```

> **Backend gap:** there's no scheduled job that turns route/assignment data into a daily trip. Until one exists, a manager (or master admin) has to create each day's `scheduled` trip by hand before a driver can start it.

**Other setup actions [MVP]**
- Edit or deactivate a bus or driver
- Edit a route or reorder its stops

**Rules**
- Only one active assignment per bus at a time.
- Editing a route does not disturb a trip already in progress.
- **[Later]** Assign students/faculty to routes and stops manually (the ERP normally supplies this).

---

## M2. Monitor the live fleet [MVP]

```
[ Manager home / dashboard ]
      ↓
Summary: active buses · inactive buses · active trips · completed trips · offline buses
      ↓
Tap "Live fleet"
      ↓
[ Map of all college buses ]
      ↓
Tap a bus → [ Bus details panel ]
      • Bus number, route, driver
      • Trip stage
      • Speed and direction
      • Last update time
      • GPS status · network status · battery
      ↓
Options: view trip · view route
```

**Rules**
- Only the manager's own college's buses appear.
- Buses with no recent updates show "Tracking unavailable".
- **[Later]** Delayed buses, route deviations and other alerts appear on the dashboard.

---

## M3. Respond to "Tracking unavailable" [MVP]

```
[ Bus stops sending location ]
      ↓
Watchdog notices (Y4)
      ↓
[ Manager sees: "Bus 023 has stopped transmitting location" ]
      ↓
Manager opens the bus → sees last known location and phone health
      ↓
Possible causes shown neutrally:
   network loss · GPS failure · battery dead · app closed · phone off
      ↓
Manager may contact the driver (outside the app)
      ↓
( Tracking resumes? )
   ├─ Yes → status returns to normal; gap filled after sync
   └─ No  → manager may end the trip manually (M5)
```

**Rule:** the message never assumes misconduct.

---

## M4. Review a trip summary [MVP]

```
[ Trip completes ]
      ↓
Manager is notified
      ↓
[ Trip list ] → tap a trip
      ↓
[ Trip summary ]
      • Route
      • Start and end time
      • Duration
      • Distance
      • Stops covered
      • Average speed
      • Tracking interruptions
      • Completion status
```

**[Later]** Route deviation, delays, and **trip playback** (replay where the bus travelled and stopped).

---

## M5. End a stuck trip [MVP]

```
[ Trip still active but bus is not sending / never reached the geofence ]
      ↓
Manager opens the trip
      ↓
Taps "End trip"
      ↓
[ Confirm ]
      ↓
Trip is marked ended by manager (recorded who and when)
      ↓
Bus becomes available for a new trip
```

Also used when a driver is removed or deactivated in the middle of a trip.

---

# PART 5: MASTER ADMIN FLOWS

## A1. Create and configure a college [MVP]

```
[ Master Admin home ]
      ↓
[ College list ] → Add college
      ↓
[ College form ]
      • Name and basic profile
      • Campus location
      • Geofence radius
      • Transport-fee policy
      • (Later) limits and plan
      ↓
Save
      ↓
[ College profile ]
      ↓
Next: A2 (create a manager)
```

The geofence settings are essential, because trip completion depends on them.

---

## A2. Create a manager account [MVP]

```
[ College profile ] → Managers → Add manager
      ↓
[ Manager form: name, contact, login details ]
      ↓
Save
      ↓
Manager can now log in (C1) and start M1
```

Other actions: remove an administrator, reset access.

---

## A3. Activate, deactivate or archive a college [MVP]

```
[ College profile ]
      ↓
Choose: Deactivate · Archive · Reactivate
      ↓
[ Confirm, with a clear explanation of the effect ]
      ↓
Deactivated: users of that college cannot log in
Archived:    kept for records, not active
```

**[Later]** Platform-wide summaries, college usage, integration status, support tickets.

---

# PART 6: SYSTEM FLOWS (what happens behind the screens)

These are not things a user does, but the UI needs to know what state each one produces.

## Y1. Trip lifecycle [MVP]

```
SCHEDULED
    ↓  driver starts trip
STARTED
    ↓  bus leaves college
LEAVING COLLEGE
    ↓
ON ROUTE
    ↓
FINAL STOPS
    ↓
RETURNING
    ↓
APPROACHING COLLEGE
    ↓  bus enters geofence
COLLEGE GEOFENCE
    ↓
COMPLETED
```

Alternate endings: **Ended manually (driver)** · **Ended manually (manager)**.

**What each stage means for the UI**
| Stage | Student sees | Manager sees | Driver sees |
|---|---|---|---|
| Scheduled | Bus not started yet | Upcoming trip | Ready to start |
| Started / Leaving | Trip started | Active trip | Active trip |
| On route / Final stops | Live bus and ETA | Live on map | Active trip |
| Returning / Approaching | Bus heading back | Live on map | Active trip |
| Completed | Trip completed | Trip summary available | Trip completed |

---

## Y2. Location updates [MVP]

```
Driver phone captures a location point
   (position, speed, direction, time, accuracy, battery, network)
        ↓
( Network available? )
   ├─ Yes → send to the system
   └─ No  → store on the phone (Y3)
        ↓
System validates the point
   ( Impossible jump / spike / wrong coordinates / poor accuracy? )
        ├─ Yes → point is discarded (not used for distance or display)
        └─ No  → point is saved
        ↓
Live bus position updates for:
   • the students/faculty on that route
   • the manager's live fleet
```

---

## Y3. Offline sync [MVP]

```
Network lost
   ↓
Points are stored on the phone in order
   ↓
Network returns
   ↓
Stored points upload in order
   ↓
System adds them to the trip history
   ↓
Distance and path are recalculated using the complete data
```

The live view for students and managers moves on to the latest position once caught up.

---

## Y4. Tracking watchdog [MVP]

```
System expects regular updates from every active bus
   ↓
( Updates received recently? )
   ├─ Yes → status: normal
   └─ No  (gap grows)
          ↓
   Status: "Tracking unavailable"
          ↓
   Manager is alerted
          ↓
   ( Updates resume? )
      ├─ Yes → status normal; gap filled once data syncs
      └─ No  → stays "Tracking unavailable" until the trip is ended
```

Students see the same neutral "Tracking unavailable" with the last known location.

---

## Y5. Geofence and automatic completion [MVP] ⚠

> **Backend gap:** the backend only has **stop-level** geofences (75m entry / 100m exit, for arrival/dwell detection). Colleges have no campus location or radius, and `complete_trip` is a manual call. Until campus geofencing is added, this flow's automatic ending has to be simulated by the driver or manager ending the trip manually (D4 Path B / M5).

```
Bus is on the return leg
   ↓
System checks each new location against the college geofence
   ↓
( Inside the geofence? )
   ├─ No  → keep monitoring
   └─ Yes
        ↓
   "Bus has returned to college"
        ↓
   Trip → COMPLETED
        ↓
   • Tracking stops
   • Duration calculated
   • Distance calculated
   • Route recorded
   • Manager notified
   • Driver and students see "Trip completed"
```

The geofence decides completion. A timed return-monitoring window only starts the watch and does not complete the trip.

---

## Y6. Eligibility check with the ERP [MVP] ⚠

> **Backend gap:** there's no ERP connection today. `is_student_tracking_eligible()` checks the backend's own `student_bus_fees` table instead, and students currently self-register with no ERP/roll-number verification. This flow works as drawn, just with "the college ERP" read as "the backend's fee table" until Module 3 is built.

```
Student/faculty logs in or opens home
   ↓
System asks the college ERP (through the integration):
   • Who is this person?
   • Enrolled for transport?
   • Fee status?
   • Assigned route and stop?
   ↓
( ERP reachable? )
   ├─ No  → use last known information if available,
   │        else show "cannot check right now"
   └─ Yes
        ↓
   ( All checks pass? )
       ├─ Yes → tracking access granted for that route and bus
       └─ No  → clear message about what is missing
```

---

# PART 7: END-TO-END MVP JOURNEY [MVP]

This is the full story that proves the product works. Everyone's flows connect here.

```
1. MASTER ADMIN
   Creates the college and sets campus location + geofence            (A1)
   Creates the manager account                                        (A2)
        ↓
2. MANAGER
   Adds a bus, a driver and a route with stops                        (M1)
   Assigns driver ↔ bus ↔ route                                       (M1)
        ↓
3. DUMMY ERP
   Holds a student: transport active, fees paid, Route 7, Stop 4
        ↓
4. STUDENT (before the trip)
   Logs in → eligibility confirmed → home shows Route 7, Bus, Stop 4  (C1, S1)
   Sees "Your bus has not started yet"                                (S4)
        ↓
5. DRIVER
   Logs in → scans Bus QR → confirms → START TRIP                     (D1)
        ↓
6. SYSTEM
   Phone sends location → validated → saved → broadcast               (Y2)
        ↓
7. STUDENT (during the trip)
   Opens live view → sees the bus moving + ETA                        (S2)
        ↓
8. MANAGER (during the trip)
   Watches the bus on the live fleet map                              (M2)
        ↓
9. BUS RETURNS
   Enters the college geofence                                        (Y5)
        ↓
10. SYSTEM
   Trip completes automatically; duration and distance calculated
        ↓
11. EVERYONE
   Driver: "Trip completed"      Student: "Trip completed"
   Manager: trip summary          (D4, S2, M4)
```

**If this journey works on real phones, the core is proven.**

---

# PART 8: ERROR AND EDGE FLOWS

| Situation | Who is affected | Expected flow |
|---|---|---|
| Wrong password | Any user | Non-revealing error, retry |
| No internet at login | Any user | "A connection is needed to log in" |
| College deactivated | Any user of that college | Login blocked with a clear message |
| Not enrolled in transport | Student/faculty | S1 message, no tracking |
| Fees pending | Student/faculty | Behaviour per college policy, clear message |
| Route not assigned | Student/faculty | "Route not assigned yet. Contact the transport office." |
| ERP unreachable | Student/faculty | Last known eligibility, else retry message |
| Bus not started | Student/faculty | "Your bus has not started yet" (S4) |
| Bus stops sending location | Student, manager | "Tracking unavailable" + last known location (Y4) |
| Student's phone offline | Student | Last known position + "Last updated…", auto-reconnect |
| Driver scans wrong bus | Driver | Blocked (D5) |
| Bus already on a trip | Driver | Blocked (D5) |
| Location permission refused | Driver | Cannot start, instructions to enable |
| Battery low / critical | Driver | Warnings (D2) |
| GPS weak or lost | Driver, manager | GPS warning; manager sees status |
| Network lost mid-trip | Driver | Keeps recording, uploads later (D3) |
| App force-closed mid-trip | Driver, manager | Interruption detected; "Tracking unavailable" |
| Phone dies mid-trip | Driver, manager | "Tracking unavailable"; manager may end the trip (M5) |
| Bus never reaches the geofence | Manager, driver | Trip stays active until ended manually |
| Driver removed mid-trip | Manager | Manager ends or reassigns (M5) |
| Bad GPS point | System | Discarded before display and distance |
| Manager opens another college's data | Manager | Blocked |
| Student opens another route's bus | Student | Blocked |

---

# PART 9: LATER FLOWS [Later]

Brief outlines. They will be detailed when these features are scheduled.

**L1. Notifications**
```
Event happens (bus approaching, delayed, cancelled, trip started/completed,
route changed, emergency, bus offline, document expiry...)
   ↓
Right audience is notified (student / driver / manager)
   ↓
User taps the notification → opens the relevant screen
```

**L2. Emergency (driver)**
```
Driver taps EMERGENCY → picks category
(accident · medical · breakdown · fire · security · road obstruction · other)
   ↓
Manager instantly receives: bus, driver, route, location, time, type
   ↓
(Optional) predefined emergency contacts notified per college configuration
   ↓
Manager follows up and closes the incident
```

**L3. Bus issue reporting (driver → manager)**
```
Driver reports issue (AC, tyre, engine, brakes, GPS, lights, cleanliness,
seating, mechanical, other)
   ↓
Manager: Reported → Under Review → Assigned → In Progress → Resolved
```

**L4. Pre-trip inspection (driver)**
```
Driver scans bus → checklist (brakes, lights, tyres, mirrors, doors,
first-aid, fire extinguisher, GPS, documents)
   ↓
( Any problem? )
   ├─ Yes → report issue → manager notified
   └─ No  → START TRIP
```

**L5. Complaint or feedback (student/faculty, driver)**
```
User picks a category → writes feedback → submits
   ↓
Manager: view → categorise → assign → respond → resolve
   ↓
User can follow the status
```

**L6. Document expiry**
```
Documents have expiry dates
   ↓
30 days before → alert · 7 days before → alert · expired → alert
   ↓
( College policy: block trips when expired? )
   ├─ Yes → trip start blocked until resolved
   └─ No  → alerts only
```

**L7. Trip playback (manager)**
```
Manager selects a trip → replay controls
   ↓
Bus moves along the recorded path; stops are visible
```

**L8. Faculty with special access**
```
Faculty logs in → normal faculty home
   ↓
Extra sections appear only for granted permissions
(e.g. fleet, routes, reports, incident reporting)
```

---

# PART 11: BACKEND REALITY NOTES

Checked against the real backend on 19 Sept 2026. Full detail and fixes are in `BACKEND_CHANGES.md`.

| Flow | Works today? | Note |
|---|---|---|
| D1 Start a trip | ⚠ Partial | No bus-lookup RPC — QR can't resolve to a trip; a `scheduled` trip must already exist |
| M1 Set up buses, drivers, routes, assignments | ⚠ Partial | Steps 1–4 work as drawn; step 5 (creating the day's trip) has to be done by hand, added here as a new step |
| Y5 Geofence and automatic completion | ⚠ Not yet | Only stop-level geofences exist; no campus geofence or auto-`complete_trip` |
| Y6 Eligibility check with the ERP | ⚠ Stand-in | Reads the backend's own fee table, not a real ERP; student sign-up isn't ERP-verified |
| A1/A2 Create a college / manager account | ⚠ Not yet | No app-callable way to provision Master Admin, Manager, or Driver accounts (client is blocked from the service-role key) |

**Already working, better than this doc assumes:** M3 (tracking unavailable) has full watchdog support; D3 (offline) has idempotent batch upload; and the backend also supports flows this document marks **[Later]** — faculty failover (L8-adjacent), SOS/emergency (L2), and notifications (L1, pending FCM setup) are already implemented and could be pulled forward.

---

# PART 10: OPEN FLOW QUESTIONS

- [ ] What exactly does a student see when fees are pending: a full block, or a warning with limited view?
- [ ] Can a manager end a trip only when it looks stuck, or at any time?
- [ ] After a driver's phone dies and is replaced, can the driver resume the same trip or must it be ended and restarted?
- [ ] Are morning and evening trips separate trips that the driver starts twice, or one scheduled pair?
- [ ] Should a student's ETA be to **their stop** only, or also to the college?
- [ ] For a driver logging out during an active trip: block it entirely, or warn and allow?
- [ ] How does a driver switch to a different bus mid-day?
- [ ] Until account provisioning exists, who creates Manager and Driver logins, and how (direct database access, a temporary admin script)?
