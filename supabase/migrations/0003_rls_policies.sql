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
