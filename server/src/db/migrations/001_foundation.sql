-- Expanding precision cannot recover historically rounded crypto quantities.
-- Crypto settlement remains disabled until custody balances are reconciled.
ALTER TABLE balances ALTER COLUMN amount TYPE NUMERIC(38,18);
ALTER TABLE ledger_entries ALTER COLUMN amount TYPE NUMERIC(38,18);

CREATE TABLE IF NOT EXISTS money_operations (
  id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id),
  fingerprint TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('completed', 'failed')),
  result JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, id)
);
CREATE TABLE IF NOT EXISTS money_holds (
  user_id UUID NOT NULL REFERENCES users(id),
  operation_id UUID NOT NULL,
  currency TEXT NOT NULL CHECK (currency = 'NGN'),
  amount_minor NUMERIC(38,0) NOT NULL CHECK (amount_minor > 0),
  status TEXT NOT NULL CHECK (status IN ('reserved','captured','released')),
  PRIMARY KEY(user_id, operation_id),
  FOREIGN KEY(user_id, operation_id) REFERENCES money_operations(user_id, id) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE IF NOT EXISTS journal_postings (
  operation_user_id UUID NOT NULL,
  operation_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES users(id),
  currency TEXT NOT NULL CHECK(currency = 'NGN'),
  amount_minor NUMERIC(38,0) NOT NULL CHECK(amount_minor <> 0),
  PRIMARY KEY(operation_user_id, operation_id, user_id),
  FOREIGN KEY(operation_user_id, operation_id) REFERENCES money_operations(user_id, id) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE IF NOT EXISTS auth_attempts (
  bucket TEXT PRIMARY KEY,
  attempts INTEGER NOT NULL,
  resets_at TIMESTAMPTZ NOT NULL
);

-- Enforce the double-entry invariant at commit, including future callers.
CREATE OR REPLACE FUNCTION validate_money_journal() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE op_user UUID; op_id UUID; entry_count INTEGER; total NUMERIC;
BEGIN
  IF TG_TABLE_NAME = 'money_operations' THEN op_user := NEW.user_id; op_id := NEW.id;
  ELSE op_user := NEW.operation_user_id; op_id := NEW.operation_id; END IF;
  IF EXISTS(SELECT 1 FROM money_operations WHERE user_id=op_user AND id=op_id AND status='completed') THEN
    SELECT count(*),sum(amount_minor) INTO entry_count,total FROM journal_postings WHERE operation_user_id=op_user AND operation_id=op_id;
    IF entry_count <> 2 OR total <> 0 THEN RAISE EXCEPTION 'Unbalanced money operation'; END IF;
    IF NOT EXISTS(SELECT 1 FROM money_holds WHERE user_id=op_user AND operation_id=op_id AND status='captured') THEN RAISE EXCEPTION 'Missing captured reservation'; END IF;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS validate_operation_journal ON money_operations;
CREATE CONSTRAINT TRIGGER validate_operation_journal AFTER INSERT ON money_operations DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_money_journal();
DROP TRIGGER IF EXISTS validate_posting_journal ON journal_postings;
CREATE CONSTRAINT TRIGGER validate_posting_journal AFTER INSERT ON journal_postings DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION validate_money_journal();
