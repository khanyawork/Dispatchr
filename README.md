# Dispatchr

**Cross-Platform Field Service Operations Platform**

Dispatchr is a cross-platform application built with Flutter and Supabase, targeting Android, iOS, Windows, macOS, and Linux. It provides a single authenticated platform through which business owners, field technicians, and clients coordinate scheduling, job execution, and service records — with the owner/admin layer functioning as an operational command center for the business.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Problem Statement](#2-problem-statement)
3. [Target Users](#3-target-users)
4. [Tech Stack & Architecture Rationale](#4-tech-stack--architecture-rationale)
5. [Design System Specification](#5-design-system-specification)
6. [Quick Start](#6-quick-start)
7. [Project Structure](#7-project-structure)
8. [Role-Based Feature Breakdown](#8-role-based-feature-breakdown)
9. [Test Accounts](#9-test-accounts)
10. [Database Schema](#10-database-schema)
11. [Key Files](#11-key-files)
12. [Feature Roadmap](#12-feature-roadmap)
13. [Contribution Guidelines](#13-contribution-guidelines)
14. [Useful Commands](#14-useful-commands)
15. [Troubleshooting](#15-troubleshooting)
16. [License & Credits](#16-license--credits)

---

## 1. Overview

Small and mid-sized service businesses (plumbing, electrical, cleaning, landscaping, HVAC, general maintenance) typically coordinate operations through an ad hoc mix of phone calls, messaging apps, and paper records. This produces missed or double-booked appointments, no reliable record of completed work, lost proof-of-work documentation, manual invoicing errors, and no operational visibility for the business owner.

Dispatchr addresses this with a unified, role-aware platform:

- **Owners/Administrators** operate from a command center that provides full visibility into scheduling, technician activity, job status, and business performance.
- **Technicians** receive assigned jobs, update status in real time, and capture proof-of-work documentation in the field.
- **Clients** submit service requests, track job status, and (in later phases) manage invoicing and payment — without needing to call the office.

This is designed as a genuine, monetizable SaaS product: a subscription-based operations platform for service businesses, architected from day one to support multiple independent business tenants on shared infrastructure.

---

## 2. Problem Statement

- Missed or double-booked jobs due to lack of a shared scheduling source of truth
- No persistent record of what work was performed, when, or by whom
- Proof-of-work (photos, notes) lost or scattered across personal devices
- Manual, error-prone invoice generation
- No owner-level visibility into field operations during the working day
- No structured channel for clients to request work or track progress

---

## 3. Target Users

| Persona           | Role                                | Scope                                        | Core Needs                                                                                            |
| ----------------- | ----------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Client**        | End customer requesting service     | Their own requests/jobs only                 | Request a job, track status, view invoice/history, communicate with the business                      |
| **Technician**    | Field worker                        | Jobs assigned to them, within their business | View assigned jobs, navigate to job sites, update status, capture before/after photos                 |
| **Owner**         | Business owner/dispatcher           | Full data for their own business tenant      | Assign jobs quickly, view technician availability, avoid double-booking, monitor business performance |
| **Administrator** | Platform operator (you/your studio) | All business tenants on the platform         | Onboard new businesses, manage subscriptions, monitor platform health, support escalations            |

**Owner vs. Administrator, clarified:** these are two different altitudes, not two names for the same role. An **Owner** runs one business inside Dispatchr (e.g., a cleaning company) and only ever sees their own tenant's data. An **Administrator** operates the Dispatchr platform itself — the SaaS provider's side — with visibility across every business tenant, billing, and platform configuration. In Phase 1, while you're the only business using the app, you may hold both roles personally, but the permission model treats them as structurally distinct from day one so Phase 3's multi-tenant SaaS launch doesn't require a rebuild.

---

## 4. Tech Stack & Architecture Rationale

| Layer                 | Technology                                      | Rationale                                                                                                                                                                |
| --------------------- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Client application    | **Flutter (Dart)**                              | Single codebase targeting Android, iOS, Windows, macOS, and Linux                                                                                                        |
| Backend & database    | **Supabase (PostgreSQL)**                       | Relational data model suited to owner→job→technician→client relationships; native Row-Level Security for role- and tenant-based access control; open-source and portable |
| Authentication        | **Supabase Auth**                               | Email/password to start, with role and business-tenant metadata attached to each user                                                                                    |
| File storage          | **Supabase Storage**                            | Job photo uploads, proof-of-work documentation                                                                                                                           |
| State management      | **Riverpod** (or Provider for simpler scope)    | Predictable state across multi-role navigation flows                                                                                                                     |
| Push notifications    | **Firebase Cloud Messaging** (backend-agnostic) | Used purely for push delivery; does not conflict with a Supabase data layer                                                                                              |
| Local dev environment | **Supabase CLI + Docker**                       | Local Postgres instance, migrations, and schema versioning without depending on the hosted environment                                                                   |
| CI                    | **GitHub Actions**                              | Automated lint, test, and build checks on every PR                                                                                                                       |
| Error monitoring      | **Sentry** (recommended, Phase 2+)              | Production error visibility once real client data is involved                                                                                                            |

**Why Supabase over Firebase:** the platform requires enforced separation between business tenants and between roles within a tenant (owner vs. technician vs. client, each seeing a different slice of the same data). PostgreSQL with Row-Level Security policies enforces this at the database layer rather than relying solely on application-level filtering, and the relational model maps directly onto the owner → job → technician → client relationships this platform is built around. It also keeps the stack consistent across your existing Flutter/Supabase work.

---

## 5. Design System Specification

This section is the single source of truth for visual design. All contributors should reference this before building or modifying UI components, to avoid inconsistent styling across screens.

### 5.1 Color Palette

| Token                          | Light Mode | Dark Mode | Usage                                              |
| ------------------------------ | ---------- | --------- | -------------------------------------------------- |
| `--color-primary` (Teal)       | `#0F766E`  | `#2DD4BF` | Primary actions, active states, links              |
| `--color-primary-hover`        | `#0D5F58`  | `#5EEAD4` | Hover/pressed state for primary elements           |
| `--color-surface` (White/Grey) | `#FFFFFF`  | `#121417` | Base background                                    |
| `--color-surface-alt`          | `#F4F5F6`  | `#1B1E22` | Cards, panels, secondary surfaces                  |
| `--color-border` (Grey)        | `#D8DCDE`  | `#2A2E33` | Dividers, input borders                            |
| `--color-text-primary`         | `#1A1D1F`  | `#F2F3F4` | Primary body/heading text                          |
| `--color-text-secondary`       | `#5B6166`  | `#A0A6AB` | Secondary/muted text                               |
| `--color-alert` (Red)          | `#DC2626`  | `#F87171` | Destructive actions, errors, overdue/urgent status |
| `--color-alert-hover`          | `#B91C1C`  | `#FCA5A5` | Hover state for destructive actions                |
| `--color-success`              | `#16A34A`  | `#4ADE80` | Completed status, confirmations                    |

Red is reserved for destructive actions, error states, and urgent/overdue job flags only — it should not be used as a general accent color, to keep its meaning unambiguous across the app.

### 5.2 Light / Dark Mode

- Both modes are first-class, not an afterthought — every screen must be designed and QA'd in both.
- Theme follows system setting by default, with a manual override toggle persisted per user.
- Implement via Flutter `ThemeData`/`ColorScheme`, referencing the tokens above rather than hardcoded hex values in widgets.

### 5.3 Interaction States

- **Button hover/press:** all interactive elements transition to their `-hover` token on hover (desktop/web) or press (mobile), with a `150–200ms` ease-out color transition — no instant color snaps.
- **Micro-animations:** subtle scale (`~1.02x`) or elevation-shadow increase on hover for cards and buttons to reinforce interactivity; keep motion under 250ms so it reads as responsive, not decorative.
- **Status transitions** (Pending → In Progress → Completed): animate the status badge color/label change rather than an abrupt swap, so state changes are visually legible in real time (e.g., on the owner's live dashboard).
- **Loading states:** use skeleton shimmer placeholders (consistent with patterns already used elsewhere in your work) rather than bare spinners, for a livelier feel.

### 5.4 Typography

- Headings: a clean geometric sans-serif for a modern, professional field-ops feel
- Body: a highly legible sans-serif optimized for small mobile screens (technicians will often be reading this outdoors, on-site)
- Maintain a consistent type scale (e.g., 12/14/16/20/24/32) across both platforms rather than ad hoc sizing per screen

### 5.5 Accessibility

- Maintain WCAG AA contrast ratios in both light and dark mode, particularly for red-on-surface alert text
- Hover/animation effects must not be the sole indicator of state — pair with icon or label changes for accessibility

---

## 6. Quick Start

### 6.1 Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (bundled with Flutter)
- Supabase CLI
- Docker Desktop (for local Supabase instance)
- Android Studio (Android builds) and/or Xcode (iOS/macOS builds)
- Git

### 6.2 Clone and Install Dependencies

```bash
git clone https://github.com/<your-org>/dispatchr.git
cd dispatchr
flutter pub get
```

### 6.3 Configure Environment Variables

Create a `.env` file at the project root (never commit this file):

```
SUPABASE_URL=your-project-url
SUPABASE_ANON_KEY=your-anon-key
```

Reference `.env.example` for the full list of required variables.

### 6.4 Apply the Database Schema (new environments only)

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

### 6.5 Run the App

```bash
flutter run
```

### 6.6 Run Quality Checks Before Pushing

```bash
flutter analyze
flutter test
dart format --set-exit-if-changed .
```

---

## 7. Project Structure

```
dispatchr/
├── lib/
│   ├── main.dart
│   ├── app/                # App-level routing, theme, root widget
│   ├── core/                # Shared utilities, constants, design tokens
│   ├── features/
│   │   ├── auth/
│   │   ├── client/          # Client request/tracking screens
│   │   ├── technician/      # Technician job flow screens
│   │   ├── owner/           # Owner business command center screens
│   │   ├── admin/           # Platform administrator screens (cross-tenant)
│   │   └── jobs/            # Shared job models, repositories
│   ├── shared/
│   │   ├── widgets/         # Reusable UI components
│   │   └── theme/           # Color tokens, light/dark ThemeData
│   └── services/
│       └── supabase/        # Supabase client, repositories, RLS-aware queries
├── supabase/
│   ├── migrations/          # SQL schema migrations
│   └── seed.sql              # Test/seed data
├── test/
├── .env.example
└── README.md
```

---

## 8. Role-Based Feature Breakdown

This section is the authoritative reference for what each of the four roles can see and do. If a screen, permission, or workflow isn't listed here for a role, assume that role cannot access it until this section is updated — this avoids accidental data exposure across tenants or roles during development.

Every role sits inside the same `profiles.role` model (`client`, `technician`, `owner`, `admin`) and every query is scoped by Row-Level Security as described in Section 10, so permissions described below are enforced at the database level, not just hidden in the UI.

---

### 8.1 Client

**Who they are:** the end customer requesting a service — a homeowner or business booking a plumber, cleaner, electrician, etc. through the business that has onboarded to Dispatchr.

**Primary goal:** get a job done without phoning the office, and know what's happening at every stage.

**Screens:**

- Sign up / log in
- Home / "My Requests" — active and past requests at a glance
- New Request form
- Request/Job detail view
- Job history & (Phase 2+) invoice list
- Notification center
- Account/profile settings

**Capabilities:**

- Create a new service request: description of the work, preferred date/time window, service address, optional photos of the issue (e.g., a leaking pipe)
- View real-time status of each request: `Pending` → `In Progress` → `Completed`
- See which technician is assigned once the business confirms the job (name and, if the business opts in, a contact method)
- View job history, including past addresses, descriptions, and outcomes
- (Phase 2) View and pay invoices for completed jobs; provide a digital signature on completion
- (Phase 2) Track technician's live location/ETA on the day of the job
- Receive push notifications: request accepted, technician en route, job completed, invoice issued
- Cancel or request to reschedule a pending (not yet in-progress) job
- Rate/review a completed job (Phase 2+, optional for the business to enable)

**Cannot do:**

- See any other client's requests or data
- See technician assignments across the whole business, only their own job
- See internal business notes not explicitly marked client-visible
- Edit job details once a technician has marked the job "In Progress"

**Typical journey:** Client signs up → submits a request with address/description → receives a notification once Owner assigns a technician → tracks status through the day → gets notified on completion → views photos/notes left by the technician → (Phase 2) receives and pays an invoice.

**Empty states to design for:** first-time client with no requests yet; a request submitted but not yet actioned by the business (should read as "received," not "stuck").

---

### 8.2 Technician

**Who they are:** the field worker performing the actual service — plumber, cleaner, electrician, HVAC tech, etc. — employed or contracted by a business using Dispatchr.

**Primary goal:** know exactly where to be, what to do, and log proof of work with minimal friction, often on a small screen outdoors with unreliable signal.

**Screens:**

- Log in
- My Jobs (today, default view) with a date filter for upcoming/past jobs
- Job detail screen (address, client name, description, notes, status control, photo capture)
- Navigation hand-off (opens device's native maps app with the job address)
- Notification center
- Account/profile settings, availability toggle

**Capabilities:**

- View only jobs assigned specifically to them — never another technician's jobs, and never the full business job list
- See job detail: client name, service address, description, scheduling window, any notes left by the Owner
- Update job status along the fixed pipeline: `Pending` → `In Progress` → `Completed` (cannot skip stages, cannot move a job backward without Owner override, to preserve an accurate audit trail)
- Attach one or more before/after photos per job as proof-of-work, uploaded to Supabase Storage and linked to the job record
- Add free-text completion notes visible to the Owner (and optionally the client)
- Get one-tap navigation/directions to the job site
- Toggle their own availability (available/unavailable) so the Owner's assignment view reflects who's free
- Receive push notifications: new job assigned, job time approaching, schedule change/cancellation
- (Phase 2) Capture client signature on job completion
- (Phase 2) See their own performance summary: jobs completed this week, average completion time

**Cannot do:**

- View or edit jobs assigned to other technicians
- View overall business performance, revenue, or other technicians' activity
- Create, delete, or reassign jobs
- Access client contact information beyond what's needed to complete the job
- See data from other business tenants

**Typical journey:** Technician logs in each morning → sees today's job list → taps a job → navigates to the address → marks "In Progress" on arrival → completes the work → attaches photos and notes → marks "Completed" → job disappears from active list, appears in their completed history.

**Empty states to design for:** no jobs assigned today (should read as a genuine day off, not an error); a job with no address or client name (should never happen, but the UI should fail safely rather than crash).

---

### 8.3 Owner (Business Command Center)

**Who they are:** the person running a single business on Dispatchr — the dispatcher/decision-maker for one tenant (e.g., a cleaning company with three technicians). This is the role your original "operational command center" concept maps to.

**Primary goal:** full visibility and control over their business's day-to-day operations, without needing to be physically present or call around to find out what's happening.

**Screens:**

- Log in
- Dashboard/command center home — today's jobs at a glance, technician status, alerts (overdue/unassigned jobs in red per Section 5)
- Job List — all jobs for the business, filterable by date range, technician, status, client
- Create/Edit Job form
- Job detail screen (full access — can override status, reassign, add internal notes)
- Technician roster — list of technicians, availability, current job, performance summary
- Client list — clients who have requested or received service
- Business performance view: jobs per week, completion rate, average job duration, technician load
- (Phase 2) Invoice list and generation
- (Phase 3) Business settings (branding, service types, working hours)
- Notification center
- Account/profile settings

**Capabilities:**

- Create, edit, and delete jobs; assign or reassign any job to any technician in their business
- View every job across the business, with filters by date, technician, status, and client
- Monitor technician status and job progression in near-real time (leveraging Supabase Realtime subscriptions on the `jobs` table)
- Manage technician accounts: invite, deactivate, view individual performance
- Manage client records associated with their business
- Override job status manually (e.g., correct a technician's mistaken entry) — logged for audit purposes
- View and respond to incoming client requests, converting them into scheduled jobs
- Access business-level analytics: jobs completed per week/month, completion rate, technician workload distribution, busiest days
- (Phase 2) Generate and send invoices from completed jobs; view payment status
- (Phase 3) Configure business-level settings: service catalog, working hours, branding shown to clients

**Cannot do:**

- View or manage data belonging to any other business tenant
- Access platform-level settings (billing between the business and Dispatchr itself, platform feature flags) — that's Administrator territory
- Impersonate the Administrator role

**Typical journey:** Owner opens the dashboard each morning → reviews today's jobs and any client requests received overnight → assigns unassigned jobs to available technicians → monitors status changes as the day progresses → follows up on anything flagged red (overdue/unassigned) → reviews weekly performance on a Friday → (Phase 2) sends outstanding invoices.

**Empty states to design for:** a new business with zero technicians/jobs yet (onboarding-flow prompt rather than a blank dashboard); a day with no jobs scheduled.

---

### 8.4 Administrator (Platform Command Center)

**Who they are:** the operator of the Dispatchr platform itself — you or your studio's team, sitting above every individual business tenant. This role only makes sense once Dispatchr moves toward Phase 3's multi-tenant SaaS model, but the permission structure exists from Phase 1 so it doesn't require retrofitting later.

**Primary goal:** keep the platform healthy, onboard and support business tenants, and monitor cross-tenant metrics — without needing to see the operational minutiae of any single business's day-to-day jobs.

**Screens:**

- Log in (separate, more tightly secured auth flow recommended — consider requiring 2FA for this role in Phase 3)
- Platform dashboard — total active businesses, total users by role, platform-wide job volume, system health
- Business (tenant) list — every business on the platform, subscription status, sign-up date
- Business detail view — a read-oriented view into a specific tenant for support purposes (with clear audit logging any time an Administrator views tenant data)
- User management — search/manage users across all tenants (e.g., resetting a locked-out Owner's access)
- Subscription & billing overview — plan tier per business, payment status, churn indicators
- Support/escalation queue (Phase 3+)
- Platform settings — feature flags, global service categories, terms of service versioning
- Audit log viewer

**Capabilities:**

- View aggregate, cross-tenant metrics: total businesses, total jobs processed platform-wide, growth trends
- Onboard new business tenants, provision their initial Owner account
- Suspend, reactivate, or offboard a business tenant (e.g., for non-payment)
- Access individual tenant data **only** in a clearly audited support context — every access is logged with timestamp and reason, never silent
- Manage platform-level configuration not exposed to individual Owners
- View subscription/billing status across all tenants
- Reset access for locked-out users across any tenant

**Cannot do (by design, even though technically privileged):**

- Silently browse a business's day-to-day job data without an audit trail — the goal is operational oversight and support, not surveillance
- Act as a technician or client within any tenant

**Typical journey:** Administrator reviews the platform dashboard each week → checks for new sign-ups requiring onboarding assistance → responds to a support ticket from an Owner locked out of their account → reviews churn/subscription health → occasionally opens a specific tenant's data (logged) to diagnose a reported bug.

**Note on scope for now:** you do not need to build this role's UI in Phase 1 — the MVP only needs Client, Technician, and Owner. Build the `admin` role and its RLS policies into the schema from the start (see Section 10) so Phase 3 doesn't require a data-model migration, but defer the actual admin screens until you're onboarding a second real business.

---

### 8.5 Permissions Matrix (Quick Reference)

| Capability                           | Client |  Technician   |       Owner       |         Administrator          |
| ------------------------------------ | :----: | :-----------: | :---------------: | :----------------------------: |
| Create own service request           |   ✅   |      ❌       |        ❌         |               ❌               |
| View own request/job status          |   ✅   |       —       |         —         |               —                |
| View jobs assigned to them           |   —    |      ✅       |         —         |               —                |
| View all jobs in one business        |   ❌   |      ❌       |        ✅         |          ✅ (audited)          |
| Create/edit/delete jobs              |   ❌   |      ❌       |        ✅         |               ❌               |
| Update job status                    |   ❌   | ✅ (own jobs) |   ✅ (override)   |               ❌               |
| Attach proof-of-work photos          |   ❌   |      ✅       |     View only     |           View only            |
| Manage technician accounts           |   ❌   |      ❌       | ✅ (own business) |      ✅ (all businesses)       |
| View business analytics              |   ❌   |      ❌       | ✅ (own business) | ✅ (all businesses, aggregate) |
| Manage business subscription/billing |   ❌   |      ❌       |     View own      |         ✅ Manage all          |
| Onboard a new business tenant        |   ❌   |      ❌       |        ❌         |               ✅               |
| View data across multiple businesses |   ❌   |      ❌       |        ❌         |          ✅ (audited)          |

---

## 9. Test Accounts

> Seeded via `supabase/seed.sql` for local/staging environments only. Do not use these credentials in production.

| Role       | Email                 | Password       | Name           | Notes                                          |
| ---------- | --------------------- | -------------- | -------------- | ---------------------------------------------- |
| Admin      | admin@dispatchr.test  | Test@Admin123  | Thandiwe Admin | Full command-center access, all business data  |
| Owner      | owner@dispatchr.test  | Test@Owner123  | Sipho Owner    | Single-business scope, job creation/assignment |
| Technician | tech1@dispatchr.test  | Test@Tech123   | Lindiwe Tech   | Assigned 3 seeded jobs (mixed statuses)        |
| Technician | tech2@dispatchr.test  | Test@Tech123   | Mpho Tech      | No jobs assigned — tests empty state           |
| Client     | client@dispatchr.test | Test@Client123 | Naledi Client  | Two seeded requests, one completed             |

---

## 10. Database Schema

```sql
-- businesses
create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- profiles (extends auth.users)
create table profiles (
  id uuid primary key references auth.users(id),
  business_id uuid references businesses(id),
  full_name text,
  role text check (role in ('admin','owner','technician','client')),
  created_at timestamptz default now()
);

-- jobs
create table jobs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid references businesses(id),
  client_id uuid references profiles(id),
  assigned_technician_id uuid references profiles(id),
  client_name text not null,
  address text not null,
  description text,
  scheduled_date date,
  scheduled_time time,
  status text check (status in ('pending','in_progress','completed')) default 'pending',
  photo_urls text[] default '{}',
  created_at timestamptz default now()
);

-- Row-Level Security (illustrative — expand per role)
alter table jobs enable row level security;

create policy "Technicians see only their jobs"
  on jobs for select
  using (assigned_technician_id = auth.uid());

create policy "Owners see all jobs in their business"
  on jobs for select
  using (
    business_id in (
      select business_id from profiles where id = auth.uid() and role = 'owner'
    )
  );

create policy "Admins may read across businesses"
  on jobs for select
  using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- admin_audit_log: records every cross-tenant access by an Administrator (Section 8.4)
create table admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references profiles(id) not null,
  business_id uuid references businesses(id) not null,
  reason text,
  accessed_at timestamptz default now()
);
```

This structure supports multiple business tenants from the outset via `business_id`, even though early testing may only use one.

---

## 11. Key Files

| File                                         | Purpose                                                        |
| -------------------------------------------- | -------------------------------------------------------------- |
| `lib/main.dart`                              | App entry point, Supabase initialization                       |
| `lib/shared/theme/app_theme.dart`            | Light/dark `ThemeData`, color tokens from Section 5            |
| `lib/services/supabase/supabase_client.dart` | Supabase client singleton                                      |
| `lib/features/jobs/job_repository.dart`      | Shared job CRUD logic used by owner and technician flows       |
| `supabase/migrations/`                       | Versioned schema changes — never edit the live schema manually |
| `.env.example`                               | Template for required environment variables                    |

---

## 12. Feature Roadmap

### Phase 1 — MVP

User accounts (Owner/Technician/Client roles), job creation and assignment, role-scoped job lists, status updates, photo attachments, job detail screen.

### Phase 2 — Growth

Push notifications, calendar/week view, PDF invoice generation, client signature capture, map view of daily jobs.

### Phase 3 — SaaS Scale

Multi-tenant business support, Stripe payments, recurring jobs, owner analytics dashboard, client-facing portal.

---

## 13. Contribution Guidelines

- Branch naming: `feature/<short-description>`, `fix/<short-description>`
- One feature or fix per PR — keep diffs reviewable
- All new UI must use the design tokens in Section 5 — no hardcoded colors
- Write or update tests for any changed logic in `lib/features/**`

### PR Checklist

- [ ] `flutter analyze` passes with no warnings
- [ ] `flutter test` passes
- [ ] `dart format` applied
- [ ] New/changed UI respects light and dark mode
- [ ] No hardcoded color values outside `app_theme.dart`
- [ ] RLS policies updated if schema/access logic changed
- [ ] Screenshots or screen recording attached for UI changes
- [ ] No secrets or `.env` values committed

---

## 14. Useful Commands

```bash
flutter pub get                 # Install dependencies
flutter run                     # Run on connected device/emulator
flutter build apk                # Build Android release
flutter build ios                # Build iOS release
flutter build windows             # Build Windows desktop
flutter analyze                 # Static analysis
flutter test                    # Run test suite
dart format .                   # Format codebase
supabase start                  # Start local Supabase stack
supabase db push                # Apply migrations
supabase db reset                # Reset local DB to latest schema + seed
```

---

## 15. Troubleshooting

| Issue                            | Likely Cause                                          | Fix                                                                                      |
| -------------------------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `flutter doctor` shows errors    | Missing SDK components                                | Follow the specific fix instructions `flutter doctor` prints per line                    |
| Supabase client fails to connect | Missing/incorrect `.env` values                       | Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` match your project settings               |
| RLS blocks expected data         | Policy missing or role/business_id not set on profile | Check `profiles.role` and `profiles.business_id` for the logged-in user                  |
| Local Supabase won't start       | Docker not running                                    | Start Docker Desktop, then `supabase start`                                              |
| Photos not uploading             | Storage bucket policy or missing permission           | Verify Storage bucket exists and RLS/storage policy allows the technician role to insert |
| Theme not switching              | Hardcoded colors outside token system                 | Search for raw hex values and replace with theme tokens per Section 5                    |

---

## 16. License & Credits

License: TBD — add your chosen license (e.g., MIT, proprietary) before public release.

Built and maintained as part of an independent software studio's product portfolio, targeting South African SMEs with a roadmap toward international markets.
