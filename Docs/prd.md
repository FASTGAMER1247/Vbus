# Product Requirements Document (PRD)
## College Transportation Management Platform

**Status:** Draft v3 (checked against the backend)
**Last updated:** 19 September 2026

> This document explains **what the product is and how it must behave**: who uses it, what each person can do, the rules it follows, and how we know it works.
> It deliberately does **not** cover how it is built or how it looks. Those live in their own files:
> `architecture.md` (system, tech stack, API contract) · `flow.md` (step-by-step user flows) · `design.md` (UI) · `phases.md` (build order) · `decisions.md` (choices and reasons)
>
> **Checked against the real backend (EshwarAditya/BUS_APP) on 19 Sept 2026.** Section 15.4 lists where the backend diverges from this PRD, and `BACKEND_CHANGES.md` has the full change list for the backend team.

**Priority labels used throughout**
- **[MVP]**: must exist in the first working version
- **[Later]**: planned, but built after the MVP

---

## Table of Contents

1. Product Overview
2. Glossary
3. Goals, Non-Goals and Success Measures
4. Users and Roles
5. Product Format
6. Multi-College (Tenant) Requirements
7. Permissions
8. Feature Specifications (Modules 1–26)
9. Notifications Summary
10. Cross-Cutting Business Rules
11. Non-Functional Requirements
12. Edge Cases and Error Situations
13. MVP Definition and Acceptance Criteria
14. Test Scenarios
15. Assumptions, Dependencies and Risks
16. Future Roadmap (Post-MVP)
17. Open Product Questions

---

## 1. Product Overview

### 1.1 What it is
A platform that lets colleges run and monitor their bus transportation. Transport managers control buses, drivers and routes. Drivers run trips using their own phone. Students and faculty see their assigned bus live on a map with an estimated arrival time. The platform company (Master Admin) onboards and manages colleges.

It is more than a "bus tracking app". It is a **multi-college transportation management and intelligence platform** that integrates with each college's existing ERP (such as CampX) where available.

### 1.2 The problem
Today, students and faculty often do not know where their bus is or when it will arrive. Managers have limited visibility into whether buses ran on time, whether drivers followed the route, or how buses are performing. Records (documents, trips, complaints, maintenance) are scattered. Dedicated GPS hardware is expensive for many colleges.

### 1.3 The solution
- The **driver's phone becomes the GPS device**. No extra hardware is needed initially.
- The system knows **who each student is, and which route, bus and stop belong to them** by reading the college ERP. Students do not search for buses. They simply open the app and see their own.
- Managers get a **live fleet view**, automatic **trip reports**, and (later) alerts, maintenance, document expiry and analytics.
- Every college is a **separate tenant**. Its data is never visible to another college.

### 1.4 What the product is NOT
- It is **not a replacement for CampX or any college ERP**. The ERP remains the source of truth for identity, enrollment and fees.
- It is not a dedicated GPS hardware product (in the first version).
- It does not automatically judge or accuse drivers. Problems are shown as alerts to investigate, never as automatic blame.

### 1.5 Product principles
1. **Prove the core first.** The engine (phone GPS → live student view → automatic trip completion) must work reliably before anything else is added.
2. **The system already knows who you are.** Students/faculty should not have to choose or search for their bus.
3. **Trust the data carefully.** GPS points are validated, and missing data is shown neutrally ("Tracking unavailable"), never as misconduct.
4. **One app, many roles.** One product experience whose features depend on the logged-in role.
5. **Separate colleges completely.** Strong data separation is non-negotiable.
6. **Permissions over special cases.** Extra access (e.g. for some faculty) is granted through permissions, not through custom dashboards.
7. **Security and privacy from day one.** The product handles student/faculty details and live location.

---

## 2. Glossary

| Term | Meaning |
|---|---|
| **Platform** | The whole product, run by the platform company |
| **College / Tenant** | One institution using the platform. Its data is fully separate from other colleges |
| **Master Admin** | Platform-level administrator who manages colleges |
| **Manager** | College-level admin / transport manager who runs a college's transport |
| **Driver** | Person who drives a bus and shares its location through their phone |
| **Student / Faculty** | Passengers who track their assigned bus |
| **ERP** | The college's existing system (e.g. CampX) holding identity, enrollment, fees, etc. |
| **Dummy ERP** | A fake ERP built by the team to test integration before a real one is connected |
| **Route** | An ordered path from the college through stops and back |
| **Stop** | A pickup or drop point on a route |
| **Trip** | One run of a bus on a route (e.g. Route 7, morning, 18 Sept) |
| **Trip lifecycle** | The stages a trip passes through, from scheduled to completed |
| **Geofence** | A virtual boundary around the college used to detect the bus returning |
| **ETA** | Estimated time of arrival at a stop or the college |
| **Bus QR** | A QR code on a bus that identifies it when a driver scans it |
| **Transport entitlement** | What transport a person is allowed to see, based on enrollment and assignment |
| **RBAC** | Role-based access control: what each role is allowed to do |
| **Watchdog** | The monitoring that notices when a bus has stopped sending location |
| **Contractor** | External company that supplies buses/drivers under a tender |

---

## 3. Goals, Non-Goals and Success Measures

### 3.1 Goals (first version)
- Prove that a college can operate and track its buses **reliably using only phones**.
- Let every eligible student/faculty member see **their own bus live**, with an ETA.
- Give managers a **live fleet view** and an **automatic summary of every trip**.
- Read student/faculty transport details **from the college ERP** rather than re-entering them.
- Keep each college's data **fully separate**.

### 3.2 Non-Goals (first version)
- Complaints, feedback, maintenance, document-expiry alerts, analytics, contractor portal, subscriptions/billing
- Real CampX integration (a Dummy ERP is used for testing)
- Dedicated GPS hardware
- Onboard passenger counting

### 3.3 How we'll know it works (success measures)
| Measure | What "good" looks like |
|---|---|
| End-to-end trip | One full trip runs from driver start to automatic completion with a correct summary |
| Live view | A student sees the bus moving with only a short delay after each update |
| Tracking continuity | Location keeps flowing with the screen locked and the app in the background |
| Data recovery | After a network gap, missed location points are uploaded and the trip has no large holes |
| Correct access | Wrong-route, wrong-college and wrong-role access are all blocked |
| Automatic completion | The bus returning to the college ends the trip without manual action |

---

## 4. Users and Roles

### 4.1 Master Admin
- **Who:** the platform company's team.
- **Goal:** onboard colleges, control what each college can use, and keep the platform healthy.
- **Can do (summary):** create/edit/activate/deactivate/archive colleges; create manager accounts; set limits; view platform-wide summaries.
- **Cannot do:** see individual colleges' private operational data beyond aggregate figures, unless explicitly permitted for support purposes.

### 4.2 Manager (College Admin / Transport Manager)
- **Who:** the college's transport staff.
- **Goal:** know where every bus is, keep the fleet running, and assign people and vehicles correctly.
- **Can do (summary):** manage buses, drivers, routes, stops, assignments; view live fleet and trips; view trip reports; (later) handle complaints, incidents, maintenance, documents, analytics.
- **Scope:** only their own college.

### 4.3 Driver
- **Who:** bus drivers, who may be external/tender-based rather than college employees.
- **Goal:** start a trip quickly, drive, and finish, with minimal interaction while driving.
- **Can do (summary):** log in, identify the bus (QR or manual), start trip, share location, see phone health (GPS/network/battery), end trip; (later) raise emergencies, report bus issues, give feedback, complete pre-trip inspection.
- **Note:** the driver's phone is the tracking device, so the experience must be simple and low-effort.

### 4.4 Student
- **Who:** enrolled students using college transport.
- **Goal:** know where their bus is and when it will reach their stop.
- **Can do (summary):** see assigned bus/route/stop, live location, ETA; (later) receive notifications, give feedback, raise complaints.

### 4.5 Faculty
- **Who:** college faculty using transport.
- **Goal:** same as students, with optional extra access.
- **Can do (summary):** everything a student can; plus extra abilities only if granted permissions (see section 7.3).

### 4.6 How each user gets an account
| Role | Account source |
|---|---|
| Master Admin | Created by the platform team |
| Manager | Created by a Master Admin (for the specific college) |
| Driver | Created by a Manager (or admin) of the college |
| Student | Identity comes from the college ERP |
| Faculty | Identity comes from the college ERP |

There is **no self-signup** for Master Admin, Manager or Driver.

---

## 5. Product Format

- **One app** serves all roles. The role returned at login decides which features and screens the user sees.
- **Mobile:** all five roles use the app on their phone.
- **Web:** **Manager** and **Master Admin** are additionally available on the web, because their tasks (forms, tables, route building, reports) suit a larger screen.
- The driver experience is intentionally **lightweight and simple**, even though it lives in the same app.

The manager and master admin experiences on mobile and on web should offer the same core capabilities, with the understanding that some heavy tasks (such as building a route) may be more comfortable on web. Which tasks are web-only is an open question (section 17).

---

## 6. Multi-College (Tenant) Requirements

1. Every college is an independent tenant.
2. College A must **never** be able to see College B's: students, faculty, drivers, buses, routes, complaints, analytics, or GPS data.
3. Every piece of data belongs to exactly one college.
4. Every user belongs to one college (except Master Admin, who operates across colleges).
5. A college can be **activated, deactivated, or archived** by a Master Admin. A deactivated college's users cannot use the product.
6. Each college has its own **settings** (campus location, geofence radius, transport-fee policy, and similar).
7. Each college has its own **limits** (users, buses, routes, storage) that a Master Admin can set.
8. The platform's aggregate views (for the Master Admin) show **counts and health**, not private details.

---

## 7. Permissions

### 7.1 Principle
What a person can do is decided by three separate questions:

| Question | Meaning | Decided by |
|---|---|---|
| **Who are you?** | Authentication | College credentials / the college's identity system |
| **What may you do?** | Authorization | Role and permissions (RBAC) |
| **What transport may you see?** | Transport entitlement | Enrollment and route/bus assignment |

All three must pass. The server enforces them on every request. Hiding a button is never the only protection.

### 7.2 Role permission overview (first version)
| Capability | Master Admin | Manager | Driver | Student | Faculty |
|---|:-:|:-:|:-:|:-:|:-:|
| Create/edit colleges | ✓ | | | | |
| Create manager accounts | ✓ | | | | |
| Set college settings/limits | ✓ | (own college, limited) | | | |
| Manage buses | | ✓ | | | |
| Manage drivers | | ✓ | | | |
| Manage routes and stops | | ✓ | | | |
| Assign driver → bus → route | | ✓ | | | |
| Assign students/faculty to routes | | ✓ | | | |
| View live fleet (all buses) | | ✓ | | | (only if granted) |
| Start/end a trip | | | ✓ | | |
| Share live location | | | ✓ | | |
| View own assigned bus live | | | | ✓ | ✓ |
| View trip reports | | ✓ | | | (only if granted) |

### 7.3 Faculty special access
Faculty do **not** get a separate "special" dashboard. Instead, individual faculty members can be granted specific permissions, for example:

- View all buses
- View all routes
- View fleet
- View student transport status
- Report incidents
- Manage complaints
- View analytics
- View reports
- Monitor specific routes

Example: one faculty member can view the fleet and routes and report incidents, but cannot manage drivers, buses or students. Another can have a completely different set. **[Later]**

---

## 8. Feature Specifications

Each module lists what the feature does, who uses it, and the rules it follows.

---

### Module 1: Login and Access [MVP]

**Purpose:** let each person in and show them only what their role allows.

- A user logs in with their credentials and the college they belong to.
- Student and faculty credentials are verified against the college's identity system (the ERP or another authorized source).
- After login, the app knows the user's **role** and **college**, and shows the correct experience.
- Sessions can expire and users can log out.
- A user with no valid role or an inactive college cannot enter.

**Rules**
- Master Admin, Manager and Driver accounts are created by admins. No self-signup.
- Wrong credentials give a clear, non-revealing error message.

---

### Module 2: College Management (Master Admin) [MVP]

**Purpose:** onboard and manage colleges on the platform.

**College actions**
- Create a college
- Edit a college
- Activate / deactivate a college
- Archive or delete a college
- View a college profile
- Onboard a college (setup steps)

**College configuration**
- Campus location and **geofence radius** [MVP]
- College-specific settings (such as transport-fee policy) [MVP]
- Limits: users, buses, routes, storage [Later]
- Subscription/plan [Later]

**Manager accounts**
- Create manager accounts for a college
- Assign college administrators
- Remove administrators

**Other (later)**
- Monitor each college's usage
- Support tickets, platform notifications, system configuration [Later]

---

### Module 3: ERP Integration [MVP]

**Purpose:** get identity and transport details from the college's existing system so nobody enters them twice.

**Data the platform uses from the ERP**
- Student identity
- Faculty identity
- Transport enrollment (is this person enrolled for transport?)
- Transport-fee status
- Assigned route
- Assigned stop
- Other relevant college data

**Rules**
- The ERP is the **source of truth** for those facts. The platform reads them and does not replace them.
- The platform must work with **different ERPs**. It is built so that switching from the Dummy ERP to CampX, or another college's ERP, does not change the product's behaviour.
- A college without an ERP can still provide data another way (for example, an API or a data file provided by the college).
- If the ERP is unreachable, the product should keep working with the last known information where sensible, and the problem should be visible to admins.

**Master Admin sees (later):** integration status, last successful sync, sync failures, field mapping for each college.

**Test data:** during development, a **Dummy ERP** provides fake students, faculty, transport enrollment, fee status and route allocation. It behaves like a real third-party system.

---

### Module 4: Bus (Fleet) Management [MVP for basics, Later for the rest]

**Purpose:** every bus has a complete digital profile.

**Basic details [MVP]**
- Bus number
- Registration number
- Model, manufacturer
- Seating capacity
- Fuel type
- Year
- Vehicle identification details
- Assigned contractor
- Assigned driver

**Documents [Later]** (see Module 19)
- RC, insurance, fitness certificate, permit, pollution certificate, other required documents

**Bus statistics [Later]**
- Total kilometres, total trips, average trip duration, operating hours
- Route history, maintenance history, reported problems

**Manager actions [MVP]:** create a bus, edit a bus, view the bus list, view a bus profile, deactivate a bus.

**Bus identity**
- Each bus has a **QR code** that gives it a digital identity. Scanning it identifies the bus (see Modules 8 and 24).

---

### Module 5: Driver Management [MVP for basics, Later for the rest]

**Purpose:** manage the people who drive the buses. Drivers can be external contractors.

**Driver profile [MVP]**
- Name, driver ID, phone number
- Contractor (if any)
- Assigned bus, assigned routes
- Profile photo, emergency contact [Later]

**Licence management [Later]**
- Licence number, category, issue date, expiry date
- Digital copy of the licence
- Expiry notifications
- Verification status

**Driver history [Later]**
- Trips completed, distance travelled, route history
- Reported incidents, bus issues reported
- Trip delays, tracking interruptions

**Manager actions [MVP]:** add a driver, edit a driver, view the driver list, remove/deactivate a driver.

---

### Module 6: Routes and Stops [MVP]

**Purpose:** define where buses go.

**A route is** an ordered path:

College → Stop 1 → Stop 2 → … → Stop N → College

**Manager can create**
- Routes
- Stops (pickup and drop points)
- Stop order (sequence)
- Morning routes and evening routes
- Special routes [Later]

**A route carries**
- Name/number
- Ordered list of stops with locations
- Estimated distance [MVP]
- Expected duration [MVP]
- Assigned bus
- Assigned driver
- Assigned students and faculty

**Rules**
- A route belongs to one college.
- Stops are in a defined order.
- Changing a route (for example, adding a stop) should be visible to the students on it. Notifications for route changes are a **[Later]** feature.

---

### Module 7: Assignments [MVP]

**Purpose:** connect the pieces so everyone knows what they are responsible for.

**Fleet assignment [MVP]**
Driver ↔ Bus ↔ Route. The manager decides which driver drives which bus on which route.

**Passenger assignment**
- Assign a student to a route and a pickup stop
- Change a student's route
- Remove a student's transport
- Assign faculty
- See route capacity and bus capacity
- Example: Route 7 has capacity 50, 46 assigned, 4 available

**Where assignments come from**
- For students and faculty, enrollment, route and stop normally come from the **college ERP** [MVP].
- Manager-side allocation tools are **[Later]**.

---

### Module 8: Trips [MVP]

**Purpose:** a trip is one run of a bus on a route. It is the central unit of the product.

**Starting a trip (driver)**
1. The driver logs in.
2. The driver identifies the bus by scanning its **Bus QR**, or entering the **Bus ID manually**.
3. The system works out the details: driver → bus → route → college → shift.
4. The driver reviews the details and taps **Start Trip**.

**Trip lifecycle**
```
SCHEDULED → STARTED → LEAVING COLLEGE → ON ROUTE → FINAL STOPS
→ RETURNING → APPROACHING COLLEGE → COLLEGE GEOFENCE → COMPLETED
```
A trip is more than "GPS on/off". It moves through defined stages, and the current stage is visible to managers and, where relevant, students.

**Rules**
- A driver can only start a trip for a bus and route assigned to them. If the wrong driver scans a bus, the trip is blocked.
- Only one active trip per bus at a time.
- Trips can be ended manually by the driver, and normally complete automatically on return to college (Module 10).
- (Later) The college's policy can prevent a trip from starting if required documents have expired.
- (Later) A **pre-trip inspection** checklist can be required before starting (Module 16).

---

### Module 9: Live Tracking (Phone GPS) [MVP]

**Purpose:** the driver's phone reports the bus's location while a trip is active.

**What is captured**
- Latitude and longitude
- Speed
- Direction
- Timestamp
- Distance travelled
- GPS accuracy
- Phone battery level
- Network status

**Background tracking**
Tracking should keep working when the app is not on screen or the phone is locked, as far as Android and iOS allow. The driver must grant the required permissions, and these are only requested from drivers.

**9.1 Tracking reliability**
- **Battery:** the driver sees the battery level, a low-battery warning, and a critical-battery warning. Example: "Battery 15%. Transport tracking is active. Please connect charger."
- **GPS:** the driver can see whether GPS is active, weak or unavailable, and the last known location.
- **Network:** the driver can see whether they are online, on a weak connection, or offline, and the last synchronisation time.

**9.2 Offline mode**
If the internet drops, tracking continues on the phone. When the connection returns, the stored points are uploaded automatically, so the trip history has no large gaps.

**9.3 GPS data validation**
The system does not blindly trust every point. It detects and filters:
- Impossible location jumps
- GPS spikes
- Unrealistic speeds
- Incorrect coordinates
- Poor-accuracy points

Bad points are excluded before distance and analytics are calculated.

**9.4 Tracking watchdog**
The system continuously checks that each active bus is still sending location. If updates stop, the manager sees **"Tracking unavailable"** for that bus, together with a note such as "Bus 023 has stopped transmitting location".

The system must **not accuse the driver**. Possible causes include network loss, GPS failure, dead battery, app closed, or phone turned off.

**9.5 Driver device health (manager view)**
For each bus the manager can see: GPS status, network status, battery percentage, last update time (for example "6 seconds ago"), and app status.

---

### Module 10: Geofencing and Automatic Trip Completion [MVP]

**Purpose:** detect that the bus is back at college and finish the trip without manual action.

- Each college has a virtual **geofence** around its campus (location and radius set in college settings).
- When the bus returns inside the geofence, the system detects that the bus has returned to college.
- Then automatically:
  - The trip is marked **Completed**
  - Tracking stops
  - Trip duration is calculated
  - Distance is calculated
  - The route travelled is recorded
  - The manager is notified

**Rules**
- The **geofence decides** when a trip is complete. A time-based return-monitoring window may be used to start watching for the return, but does not itself complete the trip.
- The driver can still end a trip manually if needed.

---

### Module 11: Trip Reports [MVP for basic summary]

**Purpose:** after every trip, produce an automatic summary.

**Report contents**
- Route
- Start time and end time
- Total duration
- Distance travelled
- Stops covered
- Route deviation [Later]
- Average speed
- Delays [Later]
- Tracking interruptions
- Completion status

**Example**
> Route 7 · 7:05 AM → 8:31 AM · 1h 26m · 38.7 km · 18 stops · 0.8 km deviation · Completed

**Later:** historical **trip playback**. The manager selects a trip (for example, Route 7, 18 September, morning) and replays where the bus travelled and where it stopped.

---

### Module 12: Student and Faculty Experience [MVP]

**Purpose:** show each person exactly the transport that belongs to them.

The system already knows: **Person → transport status → route → bus → stop.**

**Transport eligibility**
```
Transport enrolled?  →  Fee status valid?  →  Route assigned?  →  Bus assigned  →  Tracking access
```
- If the person is enrolled and fees are valid, they get tracking access.
- If they are not enrolled, or transport fees are pending, they do **not** get bus tracking access, according to the **college's configured policy**.
- This prevents anyone from simply entering another route and tracking its bus.

**What they see [MVP]**
- Assigned bus
- Assigned route
- Pickup point (stop)
- Live bus location on a map
- ETA
- List of stops
- Transport status
- Trip information (started, on route, completed)

**What they see [Later]**
- Bus information details
- Notifications
- Feedback and complaints

**Faculty:** see the same as students. Extra access depends on granted permissions (section 7.3).

---

### Module 13: Manager Dashboard and Live Fleet [MVP for core]

**Purpose:** the operational centre of a college's transport.

**Overview [MVP]**
- Active buses, inactive buses
- Active trips, completed trips
- Buses currently offline

**Overview [Later]**
- Delayed buses
- Reported problems, pending complaints
- Maintenance alerts, driver alerts
- Route deviations

**Live fleet map [MVP]**
An interactive map showing all of the college's buses with:
- Current location
- Bus number
- Route
- Driver
- Speed and direction
- Trip status
- Last location update
- GPS health, network status, battery status

---

### Module 14: Notifications [Later]

**Purpose:** tell people what they need to know at the right time. See section 9 for the full list.

- Students/faculty: bus approaching, delayed, route changed, cancelled, trip started, trip completed, emergency
- Drivers: new assignment, route change, manager message, maintenance warning, document expiry
- Managers: bus offline, GPS unavailable, driver issue, bus issue, route deviation, bus returned, trip completed, document expiry, maintenance due, emergency

**Exception [MVP]:** the manager being told a trip has completed, and the "Tracking unavailable" indication, are part of the core.

---

### Module 15: Emergency and Incident Management [Later]

**Purpose:** let a driver raise an emergency quickly and make sure the manager knows immediately.

- The driver has an **Emergency** action with categories: accident, medical emergency, bus breakdown, fire, security issue, road obstruction, other.
- The manager instantly receives: bus, driver, route, current location, time, and incident type.
- Predefined emergency contacts can be notified, according to the college's configuration.

---

### Module 16: Bus Issue Reporting and Pre-Trip Inspection [Later]

**Bus issue reporting**
- The driver can report: AC problem, tyre issue, engine problem, brake issue, GPS issue, lights, cleanliness, seating problem, mechanical problem, other.
- The manager receives it and moves it through: **Reported → Under Review → Assigned → In Progress → Resolved**.

**Pre-trip inspection**
Before starting, the driver goes through a checklist: brakes, lights, tyres, mirrors, doors, first-aid kit, fire extinguisher, GPS, documents. If something is wrong, the driver reports the issue and the manager is notified.

---

### Module 17: Feedback and Complaints [Later]

**Student/faculty can report:** bus issue, driver issue, route issue, delay, cleanliness, behaviour, pickup issue, other feedback.

**Manager can:** view, categorise, assign, respond, resolve, and track complaint history.

**Driver feedback (two-way)**
Drivers can also give feedback about: the bus, route, road conditions, traffic, stops, students, schedule and operational problems.

---

### Module 18: Maintenance Management [Later]

Each bus has: maintenance history, service dates, kilometre-based service, next service, repair history, parts replaced, reported issues and maintenance status.

Example: "Bus 023: 4,812 km since last service. Service due in 188 km."

---

### Module 19: Document Expiry [Later]

**Documents tracked:** RC, insurance, fitness certificate, permit, pollution certificate, driver licence.

**The system alerts automatically:** for example "Insurance expires in 30 days", then "7 days remaining", then "Expired".

**Policy:** depending on the college's configuration, an expired document can restrict trip assignment or trip start until it is resolved.

---

### Module 20: Analytics [Later]

- **Route analytics:** average duration, average distance, delays, route deviations, stop-level delays, historical performance
- **Bus analytics:** total distance, trips, operating hours, maintenance, issues, downtime
- **Driver analytics:** trips, distance, delays, incidents, tracking reliability
- **College analytics:** total trips, total distance, active fleet, average delays, complaints, incidents, bus utilisation
- **Platform analytics (Master Admin):** colleges onboarded and active, total users, buses, trips, distance, usage, integration health, uptime, storage. These stay aggregate and do not expose private college data.

---

### Module 21: Intelligent Features [Later]

Once enough history exists:
- **ETA prediction** using history, time of day, route, previous trips and stop delays, not just distance divided by speed
- **Delay prediction**, for example "Route 7 is often delayed between Stop 5 and Stop 8"
- **Route deviation detection**, when a bus moves significantly away from the planned route
- **Unexpected stop detection**, when a bus stays stationary unusually long
- **Stop-level intelligence**, for example Stop 6 usually at 7:42 AM but today 7:55 AM, so 13 minutes late

All of these are **alerts to investigate**, never automatic accusations.

---

### Module 22: Scheduling and Special Transport [Later]

- Schedules for morning trips, evening trips, special trips, exam schedules, weekend schedules, holiday schedules and event transportation
- **Special/event transport** for exams, fests, hackathons, sports events, industrial visits and other college events, which can run without disturbing normal routes

---

### Module 23: Bus Capacity and Occupancy [Later]

- Bus capacity, number of assigned students, actual passengers, occupancy percentage
- Helps the college notice mismatches, for example a route with 18 students using a 60-seat bus, so it can make its own decisions

---

### Module 24: QR-Based Operations [MVP for bus identification, Later for the rest]

- **Bus QR [MVP]:** scanning identifies the vehicle when starting a trip
- **Driver identity [MVP]:** driver login confirms who is driving
- **Maintenance [Later]:** scanning a bus opens its maintenance profile
- **Inspection [Later]:** scanning a bus opens its inspection checklist

---

### Module 25: Audit Logs [Later]

Records who did what and when, for example:
- Who changed a route
- Who assigned a bus or changed a driver
- Who granted special access
- Who changed student allocation
- Who resolved a complaint
- Who edited documents

Example: "Admin Ahmed changed Bus 023 to Route 7 on 18 Sept 2026 at 6:42 AM."

---

### Module 26: Contractors and Subscriptions [Later]

**Contractor / tender system**
- Contractor profile: company, contract details, contract duration, buses, drivers, documents, performance
- Contractor analytics: trips, complaints, incidents, delays, vehicle issues, driver issues
- May eventually become a separate contractor portal

**Subscriptions**
Colleges may be offered plans with different limits and features, for example:
- Basic: limited buses, basic tracking, student experience
- Professional: analytics, maintenance, complaints, advanced management
- Enterprise: custom integrations, advanced analytics, special permissions, dedicated support

The Master Admin manages plans and limits.

---

## 9. Notifications Summary [Later, except where noted]

| Audience | Notification |
|---|---|
| **Students / Faculty** | Bus approaching · Bus delayed · Route changed · Bus cancelled · Trip started · Trip completed · Emergency |
| **Drivers** | New assignment · Route change · Manager message · Maintenance warning · Document expiry |
| **Managers** | Bus offline · GPS unavailable · Driver issue · Bus issue · Route deviation · Bus returned · Trip completed · Document expiry · Maintenance due · Emergency |

In the MVP, the essential manager-facing signals are **trip completed / bus returned** and **tracking unavailable**. The rest arrive after the MVP.

---

## 10. Cross-Cutting Business Rules

1. **Eligibility.** A student/faculty member gets tracking access only if they are enrolled for transport, their transport-fee status is valid (per the college's policy), and they have an assigned route and bus.
2. **Own route only.** Passengers can only see the bus for their own assigned route.
3. **College separation.** Every user only sees their own college's data. Master Admin sees only aggregate platform information.
4. **Server-enforced roles.** Roles and college access are checked on the server for every request. Hiding a screen is never the only protection.
5. **One active trip per bus.**
6. **Driver-bus-route match.** A driver can only start a trip for a bus and route assigned to them.
7. **Trip completion by geofence.** Return to the college geofence decides when a trip completes.
8. **Neutral wording for missing data.** If location stops, the system says "Tracking unavailable". It never assumes misconduct.
9. **Alerts, not accusations.** Deviation, unexpected-stop and delay detections are prompts for a manager to investigate.
10. **Driver-only background permission.** Background location permission is only requested from drivers, when they start a trip.
11. **No self-signup** for Master Admin, Manager or Driver.
12. **ERP is the source of truth** for student/faculty identity, enrollment, fees, route and stop. The platform does not override it.
13. **College policy decides** what happens when fees are pending, whether expired documents block trips, and who is notified in emergencies.
14. **Bad GPS points are filtered** before distance and analytics are calculated.
15. **Changes are recorded** so that it can be known who changed what and when (audit log, later).

---

## 11. Non-Functional Requirements (Product Level)

**Reliability**
- The core trip flow (start, track, complete) must work on real phones in real conditions.
- Location must not be lost when the network drops. It must be uploaded later.
- Tracking should continue with the screen locked and the app in the background, as far as the phone's operating system allows.

**Timeliness**
- Students and managers should see location updates with only a short delay, and should not need to refresh constantly to see where the bus is.

**Battery and data use**
- Tracking should be gentle enough that a driver's phone lasts through a normal trip when on a charger, and warns the driver clearly when the battery is low.

**Security and privacy**
- The product handles student/faculty details and live location, so security is designed in from the start.
- Principles: role-based access, tenant isolation, least-privilege permissions, encrypted communication, secure authentication, secure document storage, audit logs, session management, API authorisation, and data-retention policies.
- Live location is only visible to people who are entitled to see it (their own bus for passengers; the college's fleet for managers).

**Usability**
- The driver experience must be simple and quick, since drivers should not be using their phone while driving.
- Students should see their bus without any searching.

**Scalability (direction)**
- The product is designed for many colleges, each with its own users, buses and routes.

**Integrations**
- Switching ERPs must not change how the product behaves for users.

---

## 12. Edge Cases and Error Situations

| Situation | Expected behaviour |
|---|---|
| Internet lost during a trip | Tracking continues on the phone; points uploaded when the network returns |
| GPS signal weak or lost | Driver sees GPS status; manager sees "Tracking unavailable" if updates stop |
| Phone battery very low | Driver sees a warning; a critical warning appears near empty |
| Phone dies or turns off | Manager sees "Tracking unavailable"; trip is not assumed to be misconduct |
| Driver force-closes the app | Interruption detected; manager sees tracking unavailable |
| Driver scans the wrong bus | Blocked; clear message |
| Bus already has an active trip | Second trip cannot start |
| Student not enrolled in transport | No tracking access; clear message |
| Student's fees pending | Tracking access depends on the college's policy; clear message |
| Student tries another route's bus | Blocked |
| Manager tries another college's data | Blocked |
| No active trip for the student's bus | Student sees that the bus has not started yet |
| Bus never reaches geofence | Trip stays active; driver/manager can end it manually |
| ERP unreachable | Product continues with last known data where sensible; admins can see the issue |
| GPS produces an impossible jump | Point is filtered out before distance is calculated |
| College deactivated | Its users can no longer use the product |
| Driver removed or deactivated mid-trip | Manager must be able to handle the trip (reassign or end it) |

---

## 13. MVP Definition and Acceptance Criteria

### 13.1 What the MVP includes
**Master Admin**
- Create a college, create a manager, manage a college (including geofence settings)

**Manager**
- Create buses, create routes, add drivers
- Assign driver → bus → route
- See the live fleet and trip status
- See the trip summary after each trip

**Driver**
- Log in, identify the bus (QR or manual), start a trip
- Background GPS during the trip
- See GPS/network/battery status
- End a trip (or have it complete automatically)

**Behaviour behind the scenes**
- Live location, trip management, storage of GPS points
- Offline collection and later upload
- Geofence detection and automatic completion
- Tracking-unavailable detection

**Student / Faculty**
- Log in, transport eligibility check, assigned route, live bus, ETA

**ERP**
- A Dummy ERP supplying student identity, transport enrollment, fee status, route and stop

### 13.2 The proof
The MVP answers one question: **"Can a college actually use a phone to operate and track its buses reliably?"**

It is complete when the following works end to end on real phones:

1. The Dummy ERP contains a student with an active transport enrollment, valid fees, a route and a stop.
2. The student logs in and their eligibility is confirmed.
3. A driver logs in, scans the bus QR, and starts the trip.
4. The phone sends its location to the system.
5. The student opens the app and sees the bus live with an ETA.
6. The bus returns to the college and the geofence detects it.
7. The trip completes automatically.
8. The manager sees the trip summary (route, start/end time, duration, distance).

### 13.3 Acceptance criteria by area
| Area | The product is acceptable when |
|---|---|
| Login | Each role lands in the correct experience for their college |
| Setup | A manager can create a bus, a route, a driver and assign them together |
| Trip start | A driver can start a trip only for their own assigned bus/route |
| Tracking | Location keeps updating with the screen locked and the app in the background |
| Offline | After a 5-minute network loss, missed points are uploaded and the trip has no large gap |
| Live view | An eligible student sees their own bus move on the map with an ETA |
| Access control | Wrong route, wrong college and wrong role are all blocked |
| Completion | The trip completes automatically at the geofence |
| Reporting | The manager sees a correct summary after the trip |
| Alerts | A bus that stops sending location shows as "Tracking unavailable" for the manager |

---

## 14. Test Scenarios

The product must pass these on real phones, not only in simulation.

1. Screen locked: does location keep sending?
2. App in the background: does location keep sending?
3. Battery saver on: what happens, and is the driver informed?
4. Internet off for 5 minutes: is data recovered when it returns?
5. GPS turned off: is the manager alerted?
6. Phone dies: is the trip state handled sensibly?
7. Driver force-closes the app: is the interruption detected?
8. Connection returns: do queued points sync automatically?
9. Bus enters the college geofence: does the trip complete?
10. Wrong driver scans a bus: is it blocked?
11. Student on Route 7 tries to view Route 12: is it blocked?
12. Manager from College A tries to view College B: is it blocked?
13. Student with pending fees: is behaviour consistent with the college's policy?
14. Two drivers try to start the same bus: is the second blocked?
15. Student opens the app before the trip starts: is the message clear?

---

## 15. Assumptions, Dependencies and Risks

### 15.1 Assumptions
- Drivers have a smartphone with GPS and mobile internet.
- Drivers are willing to keep the app running and grant location permissions.
- Colleges can provide student/faculty transport data through their ERP, an API, or provided data.
- Colleges will define their own policies (fees pending, document expiry, emergency contacts).

### 15.2 Dependencies
- A working ERP (real or dummy) that supplies identity and transport data.
- The team agreeing on how data is exchanged between the parts of the system (documented in `architecture.md`).

### 15.3 Risks
| Risk | Why it matters | Mitigation direction |
|---|---|---|
| Background location is limited by the phone's operating system and battery-saving features | The core value depends on continuous tracking | Test on real phones early; guide drivers through permissions; show battery/GPS status |
| Drivers' phones die, lose signal or close the app | Gaps in tracking | Offline storage, warnings, neutral "Tracking unavailable" messaging |
| Real ERP access is delayed or differs between colleges | Blocks eligibility checks | Keep the ERP connection replaceable; use a Dummy ERP now |
| Scope grows too fast | The core never becomes reliable | Stay disciplined about the MVP |
| Privacy of live location and student data | Trust and legal responsibility | Strict access rules and tenant separation from day one |
| Inaccurate GPS data | Wrong distances, ETAs and reports | Validate and filter GPS points |

### 15.4 Backend Reality Check (as of 19 Sept 2026)

The backend repo (Supabase/Postgres + TypeScript, `EshwarAditya/BUS_APP`) was reviewed directly against this PRD. Two things are true at once: some MVP requirements below **aren't built yet**, and several **[Later]** features are **already built**. Full detail and suggested fixes are in `BACKEND_CHANGES.md`; this is the short version.

**Gaps that block the MVP as written**

| PRD requirement | Backend reality |
|---|---|
| Module 3, ERP Integration — read identity/fees/route from the college ERP | No ERP connection exists. Fees live in the backend's own `student_bus_fees` table, and eligibility (`is_student_tracking_eligible()`) checks that table, not an ERP |
| Module 1 — student/faculty identity comes from the ERP | Public sign-up creates a `student` profile with no ERP or roll-number verification |
| Module 10, Geofencing and Automatic Trip Completion | Only **stop-level** geofencing (75m entry / 100m exit) exists. There is no campus location/radius on a college and no auto-completion when a bus returns |
| Module 8, starting a trip by scanning the **Bus QR** | `start_trip` takes only a trip ID (`p_trip_id`). Buses have no QR/scan code field |
| Module 8, "the driver starts a trip" | A trip must already exist as `scheduled` before a driver can start it. Only a Transport Admin (or Master Admin) can create that scheduled trip — there's no daily auto-generation job |
| Module 2, Manager/Master Admin account creation from the app | No RPC or Edge Function does this. The client is deliberately blocked from the service-role key needed to create Supabase Auth users |

**[Later] features that are already fully built (`IMPLEMENTED` per the backend's own feature matrix)**

| PRD module / feature | Backend status |
|---|---|
| Faculty special access → **faculty failover tracking** (not yet a named PRD module) | Implemented: a permitted faculty member can take over tracking if a driver's phone fails, and the driver can resume |
| Module 14, Notifications | Implemented, `REQUIRES DEPLOYMENT CONFIGURATION` — code and device registration are done; needs FCM service-account credentials in production |
| Emergency handling (flow `L2`, not yet a named PRD module) | Implemented: SOS/incident creation, status updates, notes, audit log, 60s anti-spam cooldown |
| Module 20, Analytics | Implemented: fleet/route operational analytics, punctuality and dwell statistics |
| Module 21, Intelligent Features | Partially implemented: dynamic multi-tier ETA and route-deviation detection (150m corridor) are done; delay prediction and stop-level historical intelligence are not |
| Module 19, Document Expiry (storage part) | Implemented: private, tenant-isolated storage for bus documents and driver photos, with expiry dates recorded. Expiry *reminders* are not built yet |
| Module 5, driver verification status | Implemented: `pending` / `verified` / `rejected` / `suspended` field exists on the driver profile |
| Module 9, offline GPS queuing | Implemented: idempotent batch upload, up to 200 points, deduplicated |

Given this, the team has a real choice: either build the six gaps above before the MVP demo, or narrow the MVP definition (Section 13) to match what the backend already does well, and treat ERP/QR/geofence as fast-follow. Either way, `BACKEND_CHANGES.md` is the list to work from.

---

## 16. Future Roadmap (Post-MVP)

Built as additional modules around the same core once the MVP is proven:

- Notifications for students, drivers and managers
- Emergency and incident management
- Bus issue reporting and pre-trip inspection
- Student feedback and complaints; driver feedback
- Maintenance management
- Document expiry alerts (RC, insurance, fitness, permit, pollution, driver licence)
- Analytics (route, bus, driver, college, platform)
- Smarter ETA, delay prediction, route deviation and unexpected-stop alerts
- Stop-level intelligence
- Historical trip playback
- Student/faculty allocation tools; bus capacity and occupancy
- Trip scheduling; special and event transport
- Faculty special permissions
- Contractor / tender portal
- Audit logs
- Subscription plans and limits
- Additional ERP integrations beyond CampX

---

## 17. Open Product Questions

- [ ] **Fees pending:** by default, should tracking be blocked, or should the student only be warned?
- [ ] **Platforms for first release:** Android only, or Android and iOS?
- [ ] **Manager/Master Admin on mobile vs web:** which tasks must work on mobile, and which can be web-only?
- [ ] **Master Admin visibility:** should Master Admin ever be allowed to view a college's private details for support, and under what rules?
- [ ] **Driver accounts:** are they created by the college manager, by the contractor, or both?
- [ ] **Return monitoring window:** should the 30-minute return-monitoring period be fixed or configurable per college?
- [ ] **Data retention:** how long are GPS points and trip history kept?
- [ ] **Manual trip end:** who can end a trip that never reached the geofence (driver, manager, or both)?
- [ ] **Multiple shifts:** how are morning and evening trips for the same bus and route represented in the MVP?
- [ ] **ERP vs. native fee table:** does the real ERP get connected before the MVP demo, or does the backend's own `student_bus_fees` table stand in as the source of truth for now? (see Section 15.4)
- [ ] **Bus identification without QR:** until `start_trip_by_bus(code)` exists, does the driver flow use manual Bus ID entry only, or does the team build QR into the backend first?
- [ ] **Trip creation cadence:** who creates each day's scheduled trips until an automated job exists — the manager, every day, by hand?
