# FieldFlow — File Manifest & ClickUp Task-Generation Prompt

This is your build checklist: every file you'll create in VS Code, organized by the folder structure from the README, followed by a ready-to-paste prompt for ClickUp's AI task generation.

---

## Part 1 — Full File Manifest

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
