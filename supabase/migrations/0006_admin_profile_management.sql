-- Lets a platform Administrator reset a locked-out user's access
-- (README Section 8.4 "User management") across any business tenant.
-- Intentionally row-level, not column-restricted, matching the pattern of
-- the Owner-scoped update policies in 0003_rls_policies.sql — the
-- application layer, not RLS, is what limits this screen to the
-- is_active toggle.
create policy "Admins can update any profile"
  on profiles for update
  using (current_user_role() = 'admin');
