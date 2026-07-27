# Dispatchr — Milestone 2 ClickUp Task-Generation Prompt

Milestone 1 (full UI skeleton — all screens, repositories, theme, and DB migrations for all four roles) is **complete**. The app currently runs on mock "preview mode" data. Milestone 2 turns it into a working, live, release-ready product.

Copy everything in the code block below into ClickUp's AI task generator as-is.

```
Create a project task structure for Milestone 2 of "Dispatchr" — a cross-platform Flutter + Supabase field service management app (Android, iOS, Windows, macOS, Linux) with four roles: Client, Technician, Owner, Administrator. Milestone 1 (full UI skeleton, all screens, repositories, theme, and DB migrations) is COMPLETE. The app currently runs on mock "preview mode" data. Milestone 2 turns it into a working, live, release-ready product.

Organize tasks into these phases as parent tasks/lists, in this order:

1. LIVE BACKEND INTEGRATION — replace each role's preview/mock repository with real Supabase queries (client_repository, technician_repository, owner_repository, admin_repository, job_repository); confirm supabase_client initialization and .env (SUPABASE_URL / SUPABASE_ANON_KEY) loading on all platforms; gate the login-screen preview bypass buttons to debug builds only; run the seed.sql test accounts and confirm each role logs in against the live database.

2. REALTIME & DATA SYNC — wire realtime_service to Supabase channels; make the owner dashboard tiles update live on job/technician status change; make the technician my_jobs list refresh live on new assignment; make the client request_detail status update live; handle reconnect and subscription cleanup on dispose.

3. PHOTO & STORAGE — implement storage_service upload via image_picker to Supabase Storage; attach request photos on the client new_request flow; capture proof-of-work photos on the technician job_detail flow; display uploaded photos in request_detail and job_detail; enforce storage bucket RLS and file-size/type limits.

4. NOTIFICATIONS — add push/local notifications for job assigned (technician), status change and completion (client), and new request received (owner); wire notification permissions and tap-to-open-job deep links.

5. ADMIN ACTIVATION — wire admin_repository to live data and activate the previously-deferred admin screens: platform_dashboard, business_list, business_detail, user_management, subscription_billing, audit_log; confirm admin_audit_log rows are written on privileged actions.

6. SECURITY & RBAC HARDENING — verify Row-Level Security end to end for every role; test that each role cannot read or mutate another business's or role's data; test session refresh, token expiry, and sign-out; confirm route guards block unauthorized navigation.

7. TESTING & QA — write repository unit tests against a test Supabase instance; add widget tests for remaining shared components; write one integration test covering the full cross-role flow (client creates request → owner assigns → technician completes with photo → client sees live update); run flutter analyze and dart format clean; verify light/dark mode and loading/empty/error states on every screen.

8. PERFORMANCE & POLISH — add pagination/lazy-loading to long job and client lists; add offline/no-connection handling and retry; replace placeholder analytics on performance_screen with real aggregate queries; audit and remove remaining TODO/mock/stub code.

9. RELEASE PREP — configure app icons and splash screens per platform; produce signed release builds (APK/AAB, iOS, desktop); prepare Play Store / App Store listing assets; add LICENSE and version bump; set up basic CI to run analyze + tests on push.

For each phase, break it into individual subtasks — one subtask per file, screen, or logical unit of work above — with a short description of what it does. Tag each subtask with its role (Client / Technician / Owner / Admin / Shared / Infra). Order subtasks so dependencies come first (backend repo wiring before realtime, storage before photo UI, security before release). Estimate each as a small (half-day to 1-day) unit suitable for a solo developer working part-time. Do not add scope beyond what is listed.
```

---

### Notes before you paste this in

- Milestone 2 assumes the Milestone 1 skeleton is in place. If ClickUp starts generating "create screen" tasks, remind it those screens already exist and it should only wire them to live data.
- The admin screens were deferred in Milestone 1 but their files now exist — Phase 5 activates them against live data.
- Sanity-check that ClickUp didn't pad with generic SaaS boilerplate (marketing site, pricing page, etc.) that isn't part of this build.
