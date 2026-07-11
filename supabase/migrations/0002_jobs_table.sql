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
