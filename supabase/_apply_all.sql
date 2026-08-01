-- ============================================================
-- Dispatchr — full schema + seed, dependency-ordered for a
-- single paste into the Supabase SQL Editor.
--
-- NOTE: this is the 7 migrations + seed.sql, REORDERED so the
-- admin_audit_log table (0004) is created before 0003's policies
-- that reference it. Applying the files in raw 0001..0007 order
-- would fail. Run this whole file once, top to bottom.
--
-- Safe to re-run: seed uses ON CONFLICT DO NOTHING. The CREATE
-- TABLE/POLICY statements are NOT idempotent — if you need to
-- start over, drop the tables first (see the guide).
-- ============================================================


-- ============================================================
-- 0001_init_businesses_profiles.sql
-- ============================================================
-- businesses (README Section 10)
create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users(id),
  created_at timestamptz default now()
);

-- profiles (extends auth.users) (README Section 10)
create table profiles (
  id uuid primary key references auth.users(id),
  business_id uuid references businesses(id),
  full_name text,
  role text check (role in ('admin','owner','technician','client')),
  created_at timestamptz default now()
);

alter table businesses enable row level security;
alter table profiles enable row level security;


-- ============================================================
-- 0002_jobs_table.sql
-- ============================================================
-- jobs (README Section 10)
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
  -- Notes the Owner leaves when assigning/scheduling the job, read-only
  -- for the assigned technician (README Section 8.2).
  owner_notes text,
  -- Free-text notes the technician adds, typically on completion, visible
  -- to the Owner and optionally the client (README Section 8.2).
  completion_notes text,
  created_at timestamptz default now()
);

alter table jobs enable row level security;


-- ============================================================
-- 0004_admin_audit_log.sql
-- ============================================================
-- admin_audit_log: records every cross-tenant access by an Administrator
-- (README Section 8.4 — "every access is logged with timestamp and
-- reason, never silent")
create table admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid references profiles(id) not null,
  business_id uuid references businesses(id) not null,
  reason text,
  accessed_at timestamptz default now()
);

alter table admin_audit_log enable row level security;


-- ============================================================
-- 0003_rls_policies.sql
-- ============================================================
-- Row-Level Security policies, expanding README Section 10's illustrative
-- example to cover every role/table per the Permissions Matrix in
-- Section 8.5.

-- Helper functions run as SECURITY DEFINER so a policy on `profiles` can
-- read the caller's own row without recursively re-triggering RLS on
-- `profiles` (a well-known Postgres/Supabase RLS pitfall).
create or replace function public.current_user_role()
returns text
language sql
security definer
stable
as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.current_user_business_id()
returns uuid
language sql
security definer
stable
as $$
  select business_id from public.profiles where id = auth.uid();
$$;

-- profiles ------------------------------------------------------------

create policy "Users can view their own profile"
  on profiles for select
  using (id = auth.uid());

create policy "Owners can view profiles in their business"
  on profiles for select
  using (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

create policy "Admins can view all profiles"
  on profiles for select
  using (current_user_role() = 'admin');

-- Needed at sign-up: a new user creates their own profile row
-- (README Section 8.1/8.3 sign-up flow).
create policy "Users can create their own profile"
  on profiles for insert
  with check (id = auth.uid());

create policy "Users can update their own profile"
  on profiles for update
  using (id = auth.uid());

create policy "Owners can update profiles in their business"
  on profiles for update
  using (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

-- businesses ------------------------------------------------------------

create policy "Business members can view their business"
  on businesses for select
  using (
    owner_id = auth.uid()
    or id = current_user_business_id()
  );

create policy "Admins can view all businesses"
  on businesses for select
  using (current_user_role() = 'admin');

-- Needed at sign-up: an Owner creates their business
-- (README Section 8.3 sign-up flow).
create policy "Users can create a business they own"
  on businesses for insert
  with check (owner_id = auth.uid());

create policy "Owners can update their own business"
  on businesses for update
  using (owner_id = auth.uid());

-- Section 8.5's Permissions Matrix: Admins "Manage all" business
-- subscription/billing (subscription_billing_screen.dart's plan_tier /
-- billing_status updates), vs. an Owner's "View own" only.
create policy "Admins can update any business"
  on businesses for update
  using (current_user_role() = 'admin');

-- jobs ------------------------------------------------------------------

create policy "Clients see only their own requests"
  on jobs for select
  using (client_id = auth.uid());

create policy "Technicians see only their assigned jobs"
  on jobs for select
  using (assigned_technician_id = auth.uid());

create policy "Owners see all jobs in their business"
  on jobs for select
  using (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

create policy "Admins may read across businesses"
  on jobs for select
  using (current_user_role() = 'admin');

-- A client can submit their own request. Phase 1 has no business-picker
-- flow yet (README Section 3), so this only checks the client is
-- requesting for themselves — tighten to also verify business
-- membership once Phase 3's business-linking flow exists.
create policy "Clients can create their own requests"
  on jobs for insert
  with check (client_id = auth.uid());

create policy "Owners can create jobs in their business"
  on jobs for insert
  with check (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

-- Technicians update status/photos/completion_notes on their own jobs
-- (README Section 8.2). Column-level enforcement (e.g. blocking a
-- technician from editing `client_name`) is left to the application
-- layer for now.
create policy "Technicians can update their assigned jobs"
  on jobs for update
  using (assigned_technician_id = auth.uid());

-- Owners can edit/reassign/override any job in their business
-- (README Section 8.3).
create policy "Owners can update jobs in their business"
  on jobs for update
  using (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

create policy "Owners can delete jobs in their business"
  on jobs for delete
  using (
    current_user_role() = 'owner'
    and business_id = current_user_business_id()
  );

-- admin_audit_log ---------------------------------------------------------

create policy "Admins can view the audit log"
  on admin_audit_log for select
  using (current_user_role() = 'admin');

create policy "Admins can record their own audit entries"
  on admin_audit_log for insert
  with check (
    admin_id = auth.uid()
    and current_user_role() = 'admin'
  );


-- ============================================================
-- 0005_profile_status.sql
-- ============================================================
-- Availability (README Section 8.2's toggle) and active/deactivated
-- status (README Section 8.3 "invite, deactivate") for technician
-- accounts.
alter table profiles add column is_available boolean not null default true;
alter table profiles add column is_active boolean not null default true;

-- Lets an Owner browse technicians who registered but haven't been linked
-- to a business yet (README Section 8.3 "invite" — Phase 1 has no
-- email-invite flow, so an already-registered, unassigned technician is
-- added to the roster instead; see technician_roster_screen.dart).
create policy "Owners can view unassigned technicians"
  on profiles for select
  using (
    business_id is null
    and role = 'technician'
    and current_user_role() = 'owner'
  );

create policy "Owners can claim unassigned technicians"
  on profiles for update
  using (
    business_id is null
    and role = 'technician'
    and current_user_role() = 'owner'
  )
  with check (business_id = current_user_business_id());


-- ============================================================
-- 0006_admin_profile_management.sql
-- ============================================================
-- Lets a platform Administrator reset a locked-out user's access
-- (README Section 8.4 "User management") across any business tenant.
-- Intentionally row-level, not column-restricted, matching the pattern of
-- the Owner-scoped update policies in 0003_rls_policies.sql — the
-- application layer, not RLS, is what limits this screen to the
-- is_active toggle.
create policy "Admins can update any profile"
  on profiles for update
  using (current_user_role() = 'admin');


-- ============================================================
-- 0007_business_billing.sql
-- ============================================================
-- Manually-tracked billing fields (README Section 8.4 "Subscription &
-- billing overview") until real Stripe integration lands in Phase 3
-- (README Section 12 roadmap). No payment processor exists yet — an
-- Administrator sets these by hand via subscription_billing_screen.dart.
alter table businesses
  add column plan_tier text not null default 'trial'
    check (plan_tier in ('trial', 'starter', 'pro', 'enterprise')),
  add column billing_status text not null default 'active'
    check (billing_status in ('active', 'past_due', 'canceled'));


-- ============================================================
-- seed.sql
-- ============================================================
-- Test account seed data (README Section 9). Local/staging environments
-- only — never run this against production, since these are well-known,
-- throwaway credentials.
--
-- Auth accounts are inserted directly into `auth.users`/`auth.identities`
-- (the shape GoTrue expects for a confirmed email/password account) rather
-- than going through the signup API, so `supabase db reset` can seed
-- everything in one pass without the app running.

-- crypt()/gen_salt() below need pgcrypto — enabled by default on Supabase
-- projects, but declared explicitly so this seed doesn't depend on that.
create extension if not exists pgcrypto;

do $$
declare
  v_business_id uuid := '66666666-6666-6666-6666-666666666601';
  v_admin_id uuid := '11111111-1111-1111-1111-111111111101';
  v_owner_id uuid := '22222222-2222-2222-2222-222222222201';
  v_tech1_id uuid := '33333333-3333-3333-3333-333333333301';
  v_tech2_id uuid := '33333333-3333-3333-3333-333333333302';
  v_client_id uuid := '44444444-4444-4444-4444-444444444401';
begin
  -- auth.users: email_confirmed_at is set so each account can sign in
  -- immediately, without a confirmation email round-trip.
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, email_change,
    email_change_token_new, recovery_token
  ) values
    ('00000000-0000-0000-0000-000000000000', v_admin_id, 'authenticated', 'authenticated', 'admin@dispatchr.test', crypt('Test@Admin123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_owner_id, 'authenticated', 'authenticated', 'owner@dispatchr.test', crypt('Test@Owner123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_tech1_id, 'authenticated', 'authenticated', 'tech1@dispatchr.test', crypt('Test@Tech123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_tech2_id, 'authenticated', 'authenticated', 'tech2@dispatchr.test', crypt('Test@Tech123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
    ('00000000-0000-0000-0000-000000000000', v_client_id, 'authenticated', 'authenticated', 'client@dispatchr.test', crypt('Test@Client123', gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '')
  on conflict (id) do nothing;

  -- auth.identities: required alongside auth.users for GoTrue's email
  -- provider to recognize the account at sign-in.
  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values
    (gen_random_uuid(), v_admin_id, v_admin_id::text, jsonb_build_object('sub', v_admin_id::text, 'email', 'admin@dispatchr.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_owner_id, v_owner_id::text, jsonb_build_object('sub', v_owner_id::text, 'email', 'owner@dispatchr.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_tech1_id, v_tech1_id::text, jsonb_build_object('sub', v_tech1_id::text, 'email', 'tech1@dispatchr.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_tech2_id, v_tech2_id::text, jsonb_build_object('sub', v_tech2_id::text, 'email', 'tech2@dispatchr.test'), 'email', now(), now(), now()),
    (gen_random_uuid(), v_client_id, v_client_id::text, jsonb_build_object('sub', v_client_id::text, 'email', 'client@dispatchr.test'), 'email', now(), now(), now())
  on conflict (provider_id, provider) do nothing;

  -- businesses: Sipho Owner's single business (README Section 9 —
  -- "Single-business scope, job creation/assignment").
  insert into businesses (id, name, owner_id) values
    (v_business_id, 'Sipho''s Field Services', v_owner_id)
  on conflict (id) do nothing;

  -- profiles: extends auth.users with role + business_id (README Section
  -- 10). Admin is platform-level, not tenant-scoped, so business_id stays
  -- null; likewise the client, per new_request_screen.dart's Phase 1
  -- single-tenant fallback (it attaches an unlinked client's request to
  -- whichever business exists rather than requiring business_id upfront).
  insert into profiles (id, business_id, full_name, role, is_available, is_active) values
    (v_admin_id, null, 'Thandiwe Admin', 'admin', true, true),
    (v_owner_id, v_business_id, 'Sipho Owner', 'owner', true, true),
    (v_tech1_id, v_business_id, 'Lindiwe Tech', 'technician', true, true),
    (v_tech2_id, v_business_id, 'Mpho Tech', 'technician', true, true),
    (v_client_id, null, 'Naledi Client', 'client', true, true)
  on conflict (id) do nothing;

  -- jobs: Lindiwe Tech (tech1) gets 3 assigned jobs across mixed statuses;
  -- Mpho Tech (tech2) gets none, to exercise the "no jobs assigned" empty
  -- state (README Section 8.2). Naledi Client has 2 requests of her own,
  -- one still unactioned and one completed (Section 8.1 / Section 9).
  insert into jobs (
    id, business_id, client_id, assigned_technician_id, client_name,
    address, description, scheduled_date, scheduled_time, status,
    owner_notes, completion_notes
  ) values
    -- Naledi's own request, not yet actioned by the business (Section 8.1
    -- empty-state callout: should read as "received," not "stuck").
    ('77777777-7777-7777-7777-777777777701', v_business_id, v_client_id, null,
     'Naledi Client', '12 Vilakazi Street, Soweto', 'Leaking kitchen tap',
     null, null, 'pending', null, null),

    -- Naledi's completed request, assigned to and finished by Lindiwe.
    ('77777777-7777-7777-7777-777777777702', v_business_id, v_client_id, v_tech1_id,
     'Naledi Client', '12 Vilakazi Street, Soweto', 'Blocked drain in bathroom',
     current_date - 3, '09:00:00', 'completed',
     'Client says the blockage started after a storm.',
     'Cleared the blockage and tested drainage — no further issues.'),

    -- Owner-created job (walk-in, no client account), in progress.
    ('77777777-7777-7777-7777-777777777703', v_business_id, null, v_tech1_id,
     'Zanele Mokoena', '45 Bree Street, Johannesburg', 'Geyser not heating',
     current_date, '13:00:00', 'in_progress',
     'Client will be home after 12pm.', null),

    -- Owner-created job (walk-in, no client account), still pending.
    ('77777777-7777-7777-7777-777777777704', v_business_id, null, v_tech1_id,
     'Ben Nkosi', '8 Long Street, Cape Town', 'Electrical socket sparking',
     current_date + 1, '10:30:00', 'pending',
     'Urgent — advise client to avoid using the socket until then.', null)
  on conflict (id) do nothing;
end $$;

