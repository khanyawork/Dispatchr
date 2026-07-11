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
