# agency
automation and web creation agency - open for upscaling
FieldFlow — Service Business Scheduler & Job Tracker
Requirements Document & Beginner Build Roadmap (Flutter)

---

 1. Problem Statement

Small service businesses (plumbers, electricians, cleaners, landscapers, HVAC techs, handymen) usually run their day-to-day operations through a mix of phone calls, WhatsApp messages, and paper notebooks. This causes:

- Missed or double-booked jobs
- No record of what work was done, when, or by whom
- Lost photos/proof of work
- Manual, error-prone invoicing
- No visibility for the business owner into what their team is doing during the day

FieldFlow solves this with a simple mobile app where:
- Office/owner creates and assigns jobs
- Technicians see their schedule, mark jobs complete, and attach photos
- Owner gets a simple overview of the day and can generate an invoice from a completed job

This is a real, sellable product — you could eventually charge small businesses a monthly subscription for it.

---

## 2. Target Users (Personas)

| Persona | Role | Needs |
|---|---|---|
| **Sarah** | Owner/dispatcher of a 3-person cleaning company | Wants to assign jobs fast, see who's free, avoid double-booking |
| **Mike** | Field technician (plumber) | Wants to see his jobs for the day, get directions, mark done, snap before/after photos |
| **Client (future phase)** | Homeowner booking a service | Wants to request a job and see status |

For your MVP, focus only on **Sarah and Mike** (owner + technician). Add the client-facing side later.

---

## 3. Feature Scope

### Phase 1 — MVP (build this first, ~2–3 months part-time as a beginner)
- User accounts: Owner and Technician roles (simple login)
- Owner can create a job (client name, address, description, date/time, assigned technician)
- Owner can view all jobs in a list, filterable by day
- Technician can see only their assigned jobs
- Technician can mark a job "In Progress" → "Completed"
- Technician can attach 1+ photos to a job
- Basic job detail screen (address, notes, status, photos)

### Phase 2 — Growth features
- Push notifications ("New job assigned", "Job starting soon")
- Calendar/week view instead of just a list
- Simple invoice generator (PDF) from a completed job
- Client signature capture on completion
- Map view of today's jobs

### Phase 3 — Long-term / monetizable features
- Multi-business support (each business is its own workspace — this is what makes it a real SaaS product)
- Payments (Stripe) so clients can pay invoices in-app
- Recurring jobs (weekly cleaning, etc.)
- Analytics dashboard for the owner (jobs per week, revenue, technician performance)
- Client-facing companion app or web portal

**Why this order matters:** Phase 1 alone is a fully functional, demoable app. Everything after that is you *extending* something that already works — which is the best way to keep learning without getting overwhelmed.

---

## 4. Functional Requirements (Phase 1 / MVP)

| ID | Requirement |
|---|---|
| FR1 | User can sign up / log in as either "Owner" or "Technician" |
| FR2 | Owner can create a new job with: client name, address, description, date, time, assigned technician |
| FR3 | Owner can view a list of all jobs, sortable/filterable by date and status |
| FR4 | Owner can edit or delete a job |
| FR5 | Technician can view only jobs assigned to them |
| FR6 | Technician can update job status: Pending → In Progress → Completed |
| FR7 | Technician can attach photos to a job |
| FR8 | Job data persists in a cloud database (not just on-device) so both users see the same live data |
| FR9 | App works on both Android and iOS from one codebase |

## 5. Non-Functional Requirements

- **Usability:** Simple enough that a non-technical small business owner can use it without training
- **Performance:** Job list should load in under 2 seconds on average mobile data
- **Reliability:** Data should not be lost if the app closes mid-entry (use proper form state handling)
- **Security:** Only logged-in users can see their business's data; technicians can't see other technicians' jobs
- **Scalability (design for later):** Data model should support multiple businesses even though Phase 1 only needs one

---

## 6. Recommended Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | **Flutter** (Dart) | One codebase → Android + iOS, huge learning resources, what you want to learn |
| Backend/Database | **Firebase** (Firestore + Authentication + Storage) | No server code needed as a beginner; generous free tier; integrates directly with Flutter |
| Auth | Firebase Authentication (email/password to start) | Simple, well-documented, secure |
| Photo storage | Firebase Storage | Pairs naturally with Firestore |
| State management | **Provider** (start here) → later `Riverpod` if you want | Provider is the gentlest learning curve for a beginner |
| Notifications (Phase 2) | Firebase Cloud Messaging | Free, integrates with Firebase you already use |

You will **not** need to write backend server code for Phase 1 and 2. That's intentional — it removes an entire skillset from your beginner path so you can focus on Flutter.

---

## 7. Data Model (Firestore Collections)

```
businesses (collection)
  └── businessId
        name
        ownerId

users (collection)
  └── userId
        name
        role: "owner" | "technician"
        businessId

jobs (collection)
  └── jobId
        businessId
        clientName
        address
        description
        scheduledDate
        scheduledTime
        assignedTechnicianId
        status: "pending" | "in_progress" | "completed"
        photoUrls: [array of strings]
        createdAt
```

This structure already supports multiple businesses (Phase 3) even though you'll only use one in Phase 1 — no need to redesign later.

---

## 8. Core Screens (MVP)

1. **Login / Sign Up screen**
2. **Owner: Job List screen** (all jobs, filter by date/status)
3. **Owner: Create/Edit Job screen** (form)
4. **Technician: My Jobs screen** (only their jobs, today by default)
5. **Job Detail screen** (shared by both roles — shows info, status, photos; technician can update status/add photos)

That's it — 5 screens gets you a real, working app.

---

## 9. Step-by-Step Roadmap (Absolute Beginner → Working App)

You said you're a total beginner, so this roadmap starts from zero. Don't skip the Dart basics — trying to learn Flutter without Dart fundamentals is where most beginners get stuck and quit.

### **Stage 0 — Setup (Week 1)**
- Install Flutter SDK + Android Studio (or VS Code with Flutter extension)
- Run `flutter doctor` until everything is green
- Create and run the default "counter app" that comes with `flutter create` — this confirms your environment works
- **Goal:** see a real app running on an emulator or your phone

### **Stage 1 — Learn Dart Basics (Weeks 2–3)**
Dart is the language Flutter uses. Learn:
- Variables, types, `null` safety
- Functions
- Classes and objects (this matters a lot in Flutter)
- Lists, Maps
- `async`/`await` and Futures (you'll need this constantly for Firebase)

**Resource:** [dart.dev/language](https://dart.dev/language) — go through it top to bottom, typing out every example yourself.

### **Stage 2 — Learn Flutter Fundamentals (Weeks 4–6)**
- Widgets: everything in Flutter is a widget
- `StatelessWidget` vs `StatefulWidget`
- Layout widgets: `Column`, `Row`, `Container`, `Padding`, `Expanded`
- Navigation between screens (`Navigator.push`)
- Forms and text input (`TextField`, `Form`, validation)
- Lists (`ListView.builder`) — you'll use this for the job list

**Resource:** Official [Flutter "Write your first app" codelab](https://docs.flutter.dev/get-started/codelab), then build 2–3 tiny throwaway apps (to-do list, simple notes app) before touching your real project. This throwaway practice is not wasted time — it's what makes Stage 3 possible.

### **Stage 3 — Build the UI Shell of FieldFlow (Weeks 7–8)**
Build all 5 screens with **fake/hardcoded data** first — no Firebase yet.
- Login screen (UI only, no real auth yet)
- Job list screen showing a hardcoded list of 3–4 fake jobs
- Job detail screen
- Create job form (doesn't save anywhere yet)
- **Goal:** the app looks and navigates like the real thing, even though nothing is "real" yet

This step matters because it separates "learning UI" from "learning Firebase" — doing both at once is what overwhelms beginners.

### **Stage 4 — Connect Firebase (Weeks 9–11)**
- Create a Firebase project, connect it to your Flutter app (`flutterfire configure`)
- Add Firebase Authentication → replace your fake login with real email/password auth
- Add Firestore → replace hardcoded job list with real data read from Firestore
- Implement create job → saves to Firestore
- Implement job status update → updates Firestore
- **Resource:** [firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)

### **Stage 5 — Roles & Photos (Weeks 12–13)**
- Implement Owner vs Technician role logic (query jobs differently based on role)
- Add photo picker (`image_picker` package) + upload to Firebase Storage
- Display photos on job detail screen

### **Stage 6 — Polish & Test (Week 14)**
- Handle loading states and errors (e.g., no internet)
- Test the full flow: owner creates job → technician sees it → completes it → owner sees it updated
- Ask a friend who owns/runs a small business to try it and give feedback

### **Stage 7 — Ship an MVP (Week 15+)**
- Build a release APK (`flutter build apk`) to test on a real device
- If happy with it, this is your MVP — a real, working, demoable product

### **After MVP — Long-Term Path**
Once Phase 1 works, move into Phase 2 features (notifications, calendar view, invoicing) one at a time, the same way: build it with fake data first, then wire it to Firebase. This "fake data → real data" pattern is something you'll reuse for the rest of your development career, not just this project.

---

## 10. Milestones Summary

| Milestone | What "done" looks like |
|---|---|
| M1 | Flutter installed, sample app running |
| M2 | Comfortable with Dart basics |
| M3 | 5 screens built with fake data, navigation works |
| M4 | Firebase Auth + Firestore connected, real login and real job list |
| M5 | Photos working, roles working |
| M6 | Full MVP tested end-to-end on a real phone |
| M7 | First real small business trials it |

---

## 11. Suggested Learning Resources

- [dart.dev/language](https://dart.dev/language) — Dart basics
- [docs.flutter.dev](https://docs.flutter.dev) — official Flutter docs (best source, better than most courses)
- [firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup) — connecting Firebase
- FlutterFire packages: `firebase_auth`, `cloud_firestore`, `firebase_storage`, `image_picker`, `provider`

---

### Final Note
Resist the urge to build Phase 2/3 features before Phase 1 works end-to-end. A small, fully working app (5 screens, real data, real login) is far more valuable — for learning and f
