-- ScorchePay backend schema. Mirrors the entities described in
-- SCORCHEPAY_FULL_SPEC.md §26 — the ledger is the single source of
-- truth; balances are a materialized view of it maintained atomically
-- alongside each ledger write, not a separately trusted number.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  paystack_customer_code TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS balances (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  currency TEXT NOT NULL,
  amount NUMERIC(18, 2) NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, currency)
);

CREATE TABLE IF NOT EXISTS ledger_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  currency TEXT NOT NULL,
  -- Signed: positive = credit, negative = debit. Numeric, never float,
  -- per the spec's explicit warning against float precision on money.
  amount NUMERIC(18, 2) NOT NULL,
  title TEXT NOT NULL,
  subtitle TEXT,
  category TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'completed',
  reference TEXT UNIQUE, -- Paystack transaction reference, when applicable
  meta JSONB NOT NULL DEFAULT '{}'::jsonb
);

-- One row per Paystack transaction we've initialized or received a
-- webhook for — the idempotency guard that stops a webhook retry (or a
-- client re-verifying the same reference) from double-crediting a
-- wallet. `status` starts 'pending' and only ever moves to 'success' or
-- 'failed' once, enforced by the unique reference + the service layer's
-- "already processed" check before crediting anything.
CREATE TABLE IF NOT EXISTS payment_transactions (
  reference TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(18, 2) NOT NULL,
  currency TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending', -- pending | success | failed
  channel TEXT, -- card | bank_transfer | dedicated_nuban
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  verified_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS virtual_accounts (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  account_number TEXT NOT NULL,
  bank_name TEXT NOT NULL,
  paystack_account_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ledger_user ON ledger_entries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_user ON payment_transactions(user_id);
