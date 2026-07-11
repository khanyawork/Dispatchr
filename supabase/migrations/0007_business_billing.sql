-- Manually-tracked billing fields (README Section 8.4 "Subscription &
-- billing overview") until real Stripe integration lands in Phase 3
-- (README Section 12 roadmap). No payment processor exists yet — an
-- Administrator sets these by hand via subscription_billing_screen.dart.
alter table businesses
  add column plan_tier text not null default 'trial'
    check (plan_tier in ('trial', 'starter', 'pro', 'enterprise')),
  add column billing_status text not null default 'active'
    check (billing_status in ('active', 'past_due', 'canceled'));
