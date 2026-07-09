# Dispatchr — File Manifest & ClickUp Task-Generation Prompt

This is your build checklist: every file you'll create in VS Code, organized by the folder structure from the README, followed by a ready-to-paste prompt for ClickUp's AI task generation.

---

## Part 1 — Full File Manifest

### Skeleton view — the whole folder tree at a glance

This is what your project folder will look like once every file below is created. Build it top-down: create the folders first (empty is fine), then fill in files as you reach each phase in ClickUp. In VS Code, you create a folder by right-clicking in the Explorer panel → **New Folder**, and a file the same way → **New File** — nesting them exactly like this:

```
dispatchr/
├── lib/
│   ├── main.dart
│   │
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── app_providers.dart
│   │
│   ├── core/
│   │   ├── constants.dart
│   │   ├── design_tokens.dart
│   │   ├── utils/
│   │   │   ├── date_formatter.dart
│   │   │   └── validators.dart
│   │   └── extensions/
│   │       └── context_extensions.dart
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── role_selector_widget.dart
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_provider.dart
│   │   │
│   │   ├── client/
│   │   │   ├── client_home_screen.dart
│   │   │   ├── new_request_screen.dart
│   │   │   ├── request_detail_screen.dart
│   │   │   ├── request_history_screen.dart
│   │   │   └── client_repository.dart
│   │   │
│   │   ├── technician/
│   │   │   ├── my_jobs_screen.dart
│   │   │   ├── job_detail_screen.dart
│   │   │   ├── availability_toggle_widget.dart
│   │   │   └── technician_repository.dart
│   │   │
│   │   ├── owner/
│   │   │   ├── dashboard_screen.dart
│   │   │   ├── job_list_screen.dart
│   │   │   ├── create_edit_job_screen.dart
│   │   │   ├── technician_roster_screen.dart
│   │   │   ├── client_list_screen.dart
│   │   │   ├── performance_screen.dart
│   │   │   └── owner_repository.dart
│   │   │
│   │   ├── admin/                          (schema/RLS now — screens deferred)
│   │   │   ├── platform_dashboard_screen.dart
│   │   │   ├── business_list_screen.dart
│   │   │   ├── business_detail_screen.dart
│   │   │   ├── user_management_screen.dart
│   │   │   ├── subscription_billing_screen.dart
│   │   │   ├── audit_log_screen.dart
│   │   │   └── admin_repository.dart
│   │   │
│   │   └── jobs/                           (shared across all roles)
│   │       ├── job_model.dart
│   │       ├── job_status.dart
│   │       ├── job_repository.dart
│   │       └── job_provider.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── status_badge.dart
│   │   │   ├── job_card.dart
│   │   │   ├── primary_button.dart
│   │   │   ├── app_text_field.dart
│   │   │   ├── skeleton_loader.dart
│   │   │   └── empty_state.dart
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── color_tokens.dart
│   │       └── text_styles.dart
│   │
│   └── services/
│       └── supabase/
│           ├── supabase_client.dart
│           ├── storage_service.dart
│           └── realtime_service.dart
│
├── supabase/
│   ├── migrations/
│   │   ├── 0001_init_businesses_profiles.sql
│   │   ├── 0002_jobs_table.sql
│   │   ├── 0003_rls_policies.sql
│   │   └── 0004_admin_audit_log.sql
│   └── seed.sql
│
├── test/
│   ├── features/
│   │   ├── jobs/
│   │   │   └── job_repository_test.dart
│   │   └── auth/
│   │       └── auth_repository_test.dart
│   └── widgets/
│       └── status_badge_test.dart
│
├── .env.example
├── README.md
└── pubspec.yaml
```

**How to read this:** each line ending in `/` is a folder, everything else is a file that lives inside the folder above it (indentation = nesting level). `lib/` is where all your actual app code lives; `supabase/` holds your database setup; `test/` holds your automated tests; the three files at the very bottom sit in the project root, alongside `lib/` and `supabase/` — not inside them.

**A quick way to build the skeleton fast:** rather than clicking "New Folder" dozens of times in VS Code, open the integrated terminal (`` Ctrl+` ``) in your project root and run this once — it creates every folder in one shot (files you still create individually as you reach each one in ClickUp):

```bash
mkdir -p lib/app lib/core/utils lib/core/extensions lib/features/auth lib/features/client lib/features/technician lib/features/owner lib/features/admin lib/features/jobs lib/shared/widgets lib/shared/theme lib/services/supabase supabase/migrations test/features/jobs test/features/auth test/widgets
```

---

### Detailed breakdown — what each file does

### `lib/main.dart`

- `main.dart` — app entry point, Supabase initialization, runApp()

### `lib/app/`

- `app.dart` — root `MaterialApp`/`CupertinoApp` widget, theme mode wiring
- `router.dart` — route definitions and role-based route guards
- `app_providers.dart` — top-level Riverpod/Provider setup

### `lib/core/`

- `constants.dart` — app-wide constants (job status strings, role strings, etc.)
- `design_tokens.dart` — raw color/spacing/typography values from README Section 5
- `utils/date_formatter.dart` — shared date/time formatting helpers
- `utils/validators.dart` — form validation logic (email, required fields)
- `extensions/context_extensions.dart` — BuildContext convenience extensions

### `lib/features/auth/`

- `login_screen.dart`
- `signup_screen.dart`
- `role_selector_widget.dart` — used at signup to assign client/technician/owner
- `auth_repository.dart` — Supabase Auth calls (sign up, sign in, sign out, session)
- `auth_provider.dart` — current user/session state

### `lib/features/client/`

- `client_home_screen.dart` — "My Requests" list
- `new_request_screen.dart` — create service request form
- `request_detail_screen.dart` — status, assigned technician, photos, notes
- `request_history_screen.dart` — past/completed requests
- `client_repository.dart` — client-scoped Supabase queries

### `lib/features/technician/`

- `my_jobs_screen.dart` — today's assigned jobs (default view)
- `job_detail_screen.dart` — status control, photo capture, notes
- `availability_toggle_widget.dart`
- `technician_repository.dart` — technician-scoped Supabase queries

### `lib/features/owner/`

- `dashboard_screen.dart` — command center home, today's jobs + alerts
- `job_list_screen.dart` — all jobs, filterable
- `create_edit_job_screen.dart` — job creation/edit form
- `technician_roster_screen.dart` — technician list, availability, performance
- `client_list_screen.dart`
- `performance_screen.dart` — analytics (jobs/week, completion rate)
- `owner_repository.dart` — business-scoped Supabase queries

### `lib/features/admin/` _(build schema/RLS now, screens deferred until Phase 3 per README 8.4)_

- `platform_dashboard_screen.dart`
- `business_list_screen.dart`
- `business_detail_screen.dart`
- `user_management_screen.dart`
- `subscription_billing_screen.dart`
- `audit_log_screen.dart`
- `admin_repository.dart` — cross-tenant Supabase queries (audited)

### `lib/features/jobs/` _(shared across roles)_

- `job_model.dart` — Job data class
- `job_status.dart` — enum: pending / in_progress / completed
- `job_repository.dart` — shared CRUD logic
- `job_provider.dart` — shared job state/streams (Supabase Realtime)

### `lib/shared/widgets/`

- `status_badge.dart` — animated status pill (README 5.3)
- `job_card.dart` — reusable job list item
- `primary_button.dart` — hover/press states per design tokens
- `app_text_field.dart`
- `skeleton_loader.dart` — shimmer loading placeholder
- `empty_state.dart` — reusable empty-state widget

### `lib/shared/theme/`

- `app_theme.dart` — light/dark `ThemeData`, references design tokens
- `color_tokens.dart` — teal/grey/white/red tokens (light + dark values)
- `text_styles.dart` — type scale

### `lib/services/supabase/`

- `supabase_client.dart` — client singleton/init
- `storage_service.dart` — photo upload/download helpers
- `realtime_service.dart` — live job status subscriptions

### `supabase/migrations/`

- `0001_init_businesses_profiles.sql`
- `0002_jobs_table.sql`
- `0003_rls_policies.sql`
- `0004_admin_audit_log.sql`

### `supabase/seed.sql`

- Test account seed data (Section 9 of README)

### `test/`

- `features/jobs/job_repository_test.dart`
- `features/auth/auth_repository_test.dart`
- `widgets/status_badge_test.dart`
- (one test file per repository/critical widget, added as you build)

### Root

- `.env.example`
- `README.md` _(already done)_
- `pubspec.yaml`

---

## Part 2 — Prompt for ClickUp AI Task Generation

Copy everything below into ClickUp's AI task generator as-is.

```
Create a project task structure for "Dispatchr" — a cross-platform Flutter + Supabase field service management app for Android, iOS, Windows, macOS, and Linux. There are four user roles: Client, Technician, Owner, and Administrator.

Organize tasks into these phases as parent tasks/lists, in this order:

1. SETUP — environment setup: install Flutter SDK, install Supabase CLI + Docker, create Supabase project, configure .env, initialize Git repo, set up project folder structure (lib/app, lib/core, lib/features/{auth,client,technician,owner,admin,jobs}, lib/shared/{widgets,theme}, lib/services/supabase, supabase/migrations, test).

2. DESIGN SYSTEM — implement color tokens (teal/grey/white/red) for light and dark mode, build app_theme.dart and color_tokens.dart, implement button hover/press states, implement status badge micro-animations, implement skeleton loading shimmer, verify WCAG AA contrast in both modes.

3. DATABASE — write Supabase SQL migrations for businesses table, profiles table (with role enum: client/technician/owner/admin), jobs table, admin_audit_log table, and Row-Level Security policies scoping each role's data access. Write supabase/seed.sql with test accounts for each role.

4. AUTH MODULE — build login screen, signup screen with role selection, auth_repository.dart (Supabase Auth integration), auth_provider.dart for session state, role-based route guarding.

5. SHARED/CORE MODULES — build shared widgets (job_card, status_badge, primary_button, app_text_field, empty_state, skeleton_loader), core utils (date_formatter, validators), Supabase service layer (supabase_client, storage_service, realtime_service), job_model.dart and job_status.dart shared across roles.

6. CLIENT MODULE — build client_home_screen (my requests list), new_request_screen (create request form), request_detail_screen (status/technician/photos), request_history_screen, client_repository.dart.

7. TECHNICIAN MODULE — build my_jobs_screen (today's jobs default view), job_detail_screen (status control + photo capture + notes), availability_toggle_widget, technician_repository.dart.

8. OWNER MODULE — build dashboard_screen (command center with live job/technician status), job_list_screen (filterable all-jobs view), create_edit_job_screen, technician_roster_screen, client_list_screen, performance_screen (analytics), owner_repository.dart.

9. ADMIN MODULE (schema only for now, screens deferred) — implement admin role RLS policies and admin_audit_log table only; defer platform_dashboard_screen, business_list_screen, business_detail_screen, user_management_screen, subscription_billing_screen, and audit_log_screen to a later milestone.

10. TESTING & QA — write unit tests for each repository, widget tests for shared components, run flutter analyze and dart format, test full role-based flow end to end (client creates request → owner assigns → technician completes → client sees update), verify light/dark mode on every screen.

11. RELEASE PREP — build release APK, configure app icons/splash screens, prepare Play Store / App Store listing assets, write LICENSE file.

For each phase, break it into individual subtasks — one subtask per file or logical unit of work listed above — with a short description of what that file/task does. Tag each subtask with its relevant role (Client / Technician / Owner / Admin / Shared / Infra) as a custom field or tag. Order subtasks within each phase so dependencies come first (e.g., database schema before repository code, repository code before UI screens). Estimate each subtask as a small (half-day to 1-day) unit of work suitable for a solo developer working part-time.
```

---

### Notes before you paste this in

- The prompt deliberately tells ClickUp to **defer the Admin screens** — matching the README's guidance that you only need the Admin role's database/RLS scaffolding in Phase 1, not the actual UI, until you're onboarding a second business.
- If ClickUp's generator lets you attach a file, you can paste the actual README.md alongside this prompt for extra context — it won't hurt and may improve task accuracy.
- Once tasks are generated, sanity-check that ClickUp didn't invent extra scope beyond what's listed — AI task generators sometimes pad with generic SaaS boilerplate tasks (e.g., "set up marketing site") that aren't part of this build.
