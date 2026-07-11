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
