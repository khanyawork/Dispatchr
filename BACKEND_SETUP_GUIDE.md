# Dispatchr — Backend Setup Guide (Milestone 2, Phase 1)

This gets your live Supabase backend running so the app talks to real data instead of preview mode. Your code is already written to query live Supabase — this is provisioning, not coding. Work through it top to bottom; it takes about 20–30 minutes.

**Your project**
- Project: Dispatchr @ Khanya Digital Studio
- URL: `https://maumjydwqwfgupfgffyp.supabase.co`
- Project ID: `maumjydwqwfgupfgffyp`
- Git: `khanyawork/Dispatchr` (already connected as `origin`)

**What "done" looks like:** you launch the app, tap **Log In** (not a Preview button), sign in as `owner@dispatchr.test`, and see Sipho's business with 4 real jobs loaded from Supabase.

---

## Step 1 — Get your anon key and finish the `.env`

I already set `SUPABASE_URL` in `.env` for you. You just need the key.

1. Open your project in the Supabase dashboard.
2. Go to **Project Settings → API**.
3. Under **Project API keys**, copy the **`anon` / `public`** key (a long string starting with `eyJ...`). This key is safe to ship in a client app — it only works within your Row-Level Security rules.
4. Open `C:\dev\DispatchR\.env` and replace `PASTE_YOUR_ANON_PUBLIC_KEY_HERE` with it.

Your `.env` should end up looking like:

```
SUPABASE_URL=https://maumjydwqwfgupfgffyp.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6...
```

`.env` is gitignored, so your key never gets committed. Do not paste the **`service_role`** key here — that one bypasses RLS and must never live in a client app.

---

## Step 2 — Apply the database schema + seed data

I built you a single file that creates every table, all Row-Level Security policies, and the test accounts in one pass: **`supabase/_apply_all.sql`**.

> Why one combined file? Your migrations are numbered so that `0003_rls_policies.sql` creates policies on the `admin_audit_log` table before `0004` creates that table. Applied in raw order they fail. `_apply_all.sql` reorders them correctly (0001 → 0002 → 0004 → 0003 → 0005 → 0006 → 0007 → seed). See "Fixing the migration order" at the bottom if you want to repair the numbered files for CLI use later.

1. In the dashboard, open the **SQL Editor** (left sidebar) → **New query**.
2. Open `C:\dev\DispatchR\supabase\_apply_all.sql`, copy the whole file, paste it into the editor.
3. Click **Run**. You should see "Success. No rows returned."
4. Verify: go to **Table Editor**. You should see `businesses`, `profiles`, `jobs`, `admin_audit_log`. Open `jobs` — there should be 4 rows; open `profiles` — 5 rows.

**If you need to start over** (e.g. you ran it twice and hit "already exists" errors), run this once to wipe the schema, then re-run `_apply_all.sql`:

```sql
drop table if exists jobs cascade;
drop table if exists admin_audit_log cascade;
drop table if exists profiles cascade;
drop table if exists businesses cascade;
drop function if exists public.current_user_role cascade;
drop function if exists public.current_user_business_id cascade;
-- also clear the seeded auth users so the seed can re-insert them:
delete from auth.users where email like '%@dispatchr.test';
```

---

## Step 3 — Let the seed accounts (and real signups) log in

The seed accounts are created with confirmed emails, so they work immediately. But **new signups from the app** will get stuck waiting for a confirmation email you haven't configured. For development, turn confirmation off:

1. **Authentication → Sign In / Providers → Email** (or **Authentication → Providers → Email**).
2. Turn **Confirm email** OFF.
3. Save.

Re-enable this before you go to production and wire up an email provider.

---

## Step 4 — Create the photo storage bucket

Your `storage_service.dart` uploads job/request photos to a bucket named exactly **`job-photos`**. Create it now so photos work later (Phase 3):

1. **Storage → New bucket**.
2. Name: `job-photos` (exact — the code hardcodes this).
3. Toggle **Public bucket** ON (the app uses public URLs for photos). You can tighten this in Phase 3.
4. Create.

If you'd rather keep it private later, you'll add storage RLS policies then — not needed for this milestone.

---

## Step 5 — Enable Realtime on the jobs table (for Phase 2)

Your dashboards subscribe to live changes via `.stream()`. Supabase only streams tables that are in its realtime publication — and the app streams **four** tables (`jobs`, `profiles`, `businesses`, `admin_audit_log`), not just `jobs`. Miss any and that screen throws "Could not load ..." (e.g. the owner's technician roster streams `profiles`).

Run this whole block in the SQL Editor:

```sql
-- add every streamed table to the realtime publication
alter publication supabase_realtime add table jobs;
alter publication supabase_realtime add table profiles;
alter publication supabase_realtime add table businesses;
alter publication supabase_realtime add table admin_audit_log;

-- REPLICA IDENTITY FULL lets realtime evaluate RLS on updates/deletes,
-- so those events actually reach the app (recommended for RLS'd tables)
alter table jobs replica identity full;
alter table profiles replica identity full;
alter table businesses replica identity full;
alter table admin_audit_log replica identity full;
```

(If a line says the table is "already a member," that one's fine — keep going.)

---

## Step 6 — Run the app against the live backend

1. Open a terminal in `C:\dev\DispatchR`.
2. `flutter pub get`
3. `flutter run` (pick a device — Windows desktop or an emulator).
4. On the login screen, **ignore the Preview buttons** and use real **Log In** with a seed account below.
5. You should land in the role's real UI with live data. The owner account is the best first test — it has the fullest dataset.

**Seed test accounts** (development only — never reuse these in production):

| Role       | Email                  | Password        | What you'll see                          |
|------------|------------------------|-----------------|------------------------------------------|
| Owner      | owner@dispatchr.test   | Test@Owner123   | Sipho's business, 4 jobs, 2 technicians  |
| Technician | tech1@dispatchr.test   | Test@Tech123    | Lindiwe — 3 assigned jobs, mixed status  |
| Technician | tech2@dispatchr.test   | Test@Tech123    | Mpho — no jobs (empty-state test)        |
| Client     | client@dispatchr.test  | Test@Client123  | Naledi — 2 requests (1 pending, 1 done)  |
| Admin      | admin@dispatchr.test   | Test@Admin123   | Platform-level, cross-business access    |

---

## Step 7 — Confirm it's real, not preview

Quick sanity checks that you're actually hitting Supabase:

- Log in as the owner, then in the dashboard change or complete a job. Refresh the **Table Editor** `jobs` row in the dashboard — the change should be there.
- Log in as `tech2@dispatchr.test` — you should see the "no jobs assigned" empty state (proves per-technician RLS filtering is live, not mock data).
- Log in as the client and confirm you only see Naledi's 2 requests, not all 4 jobs (proves the client RLS policy works).

If all three behave, your backend is wired and RLS is enforcing correctly.

---

## Step 8 — Commit your progress

Git is already connected to `khanyawork/Dispatchr`. Your `.env` is gitignored, so it's safe to commit everything else:

```
git add supabase/_apply_all.sql BACKEND_SETUP_GUIDE.md
git commit -m "Add combined schema/seed SQL and backend setup guide"
git push
```

---

## Troubleshooting

**App still shows preview / no data after logging in.** The anon key in `.env` is wrong or still the placeholder. `main.dart` silently falls back to preview-only if the key is missing/invalid. Re-copy the `anon` `public` key, restart the app fully (stop and `flutter run` again — hot reload won't re-read `.env`).

**"Invalid login credentials".** The seed didn't run, or you disabled email confirm after seeding a real signup. Re-check Step 2 (jobs/profiles tables populated) and Step 3.

**Login works but every list is empty for the owner too.** RLS is on but the helper functions didn't get created. Re-run `_apply_all.sql` — the `current_user_role()` / `current_user_business_id()` functions in the 0003 section are what every policy depends on.

**"permission denied for table ..." errors.** You're likely querying before the profile row exists. Every account needs a matching `profiles` row (the seed creates them; real signups create them in `auth_repository.signUp`).

**Realtime updates don't push.** Confirm Step 5 ran (`jobs` in `supabase_realtime` publication).

---

## Migration order — FIXED

The numbered migrations now apply cleanly in order (`supabase db push` / `db reset` will work). The `admin_audit_log` policy block was moved out of `0003_rls_policies.sql` and into `0004_admin_audit_log.sql`, right after that table is created. So:

- `0003` now only defines the helper functions and the profiles/businesses/jobs policies.
- `0004` now creates the `admin_audit_log` table **and** its two policies.

`_apply_all.sql` still works too — it's independent of this change and remains the fastest way to provision a fresh project in one paste.
