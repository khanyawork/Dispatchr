-- Jobs: the core work record connecting a business, client, and
-- technician (README Section 10).
--
-- Row-Level Security is intentionally not enabled here — see
-- 0003_rls_policies.sql.

create table jobs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references businesses(id),
  client_id uuid references profiles(id),
  assigned_technician_id uuid references profiles(id),
  client_name text not null,
  address text not null,
  description text,
  scheduled_date date,
  scheduled_time time,
  status text not null check (status in ('pending', 'in_progress', 'completed')) default 'pending',
  photo_urls text[] not null default '{}',
  -- Extends README's illustrative schema: backs the Technician's "add
  -- free-text completion notes visible to the Owner" capability (README
  -- Section 8.2) and technician_repository.dart's addCompletionNotes.
  technician_notes text,
  created_at timestamptz not null default now()
);

create index idx_jobs_business_id on jobs(business_id);
create index idx_jobs_client_id on jobs(client_id);
create index idx_jobs_assigned_technician_id on jobs(assigned_technician_id);
create index idx_jobs_status on jobs(status);
create index idx_jobs_scheduled_date on jobs(scheduled_date);
