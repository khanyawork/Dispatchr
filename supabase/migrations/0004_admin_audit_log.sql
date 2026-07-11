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
