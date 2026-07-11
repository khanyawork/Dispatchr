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
