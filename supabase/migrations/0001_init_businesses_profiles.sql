-- Businesses (tenants) and profiles (role-scoped user records extending
-- auth.users), per README Section 10.
--
-- Row-Level Security is intentionally not enabled here — see
-- 0003_rls_policies.sql, which enables it alongside the policies for all
-- three core tables in one place.

create table businesses (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users(id),
  -- Extends README's illustrative schema: backs the Administrator's
  -- "suspend, reactivate, or offboard a business tenant" capability
  -- (README Section 8.4) and admin_repository.dart's
  -- suspendBusiness/reactivateBusiness.
  status text not null default 'active' check (status in ('active', 'suspended')),
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  business_id uuid references businesses(id),
  full_name text,
  role text not null check (role in ('admin', 'owner', 'technician', 'client')),
  -- Extends README's illustrative schema: backs the Technician's "toggle
  -- their own availability" capability (README Section 8.2) and
  -- technician_repository.dart's getAvailability/setAvailability.
  is_available boolean not null default true,
  created_at timestamptz not null default now()
);

create index idx_businesses_owner_id on businesses(owner_id);
create index idx_profiles_business_id on profiles(business_id);
create index idx_profiles_role on profiles(role);
