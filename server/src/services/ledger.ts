import { PoolClient } from "pg";
import { pool } from "../db/pool";

export class InsufficientFundsError extends Error {
  constructor(currency: string, shortBy: number) {
    super(`Insufficient ${currency} balance — short by ${shortBy.toFixed(2)}`);
  }
}

/**
 * Atomic ledger primitives — every write happens inside a single
 * Postgres transaction (balance row lock + ledger insert), so a crash
 * mid-write can never leave a ledger entry with no matching balance
 * change or vice versa. This is the server-side twin of the Flutter
 * app's LedgerService (`lib/state/services/ledger_service.dart`) — same
 * shape, now backed by a real database instead of on-device JSON.
 */

export async function credit(params: {
  userId: string;
  currency: string;
  amount: number;
  title: string;
  subtitle?: string;
  category: string;
  reference?: string;
  meta?: Record<string, unknown>;
}): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await upsertBalance(client, params.userId, params.currency, params.amount);
    await client.query(
      `INSERT INTO ledger_entries (user_id, currency, amount, title, subtitle, category, reference, meta)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [params.userId, params.currency, params.amount, params.title, params.subtitle ?? null, params.category, params.reference ?? null, JSON.stringify(params.meta ?? {})]
    );
    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

export async function debit(params: {
  userId: string;
  currency: string;
  amount: number;
  title: string;
  subtitle?: string;
  category: string;
  meta?: Record<string, unknown>;
}): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { rows } = await client.query<{ amount: string }>(
      `SELECT amount FROM balances WHERE user_id = $1 AND currency = $2 FOR UPDATE`,
      [params.userId, params.currency]
    );
    const have = rows.length ? Number(rows[0].amount) : 0;
    if (have < params.amount - 1e-9) {
      await client.query("ROLLBACK");
      throw new InsufficientFundsError(params.currency, params.amount - have);
    }
    await upsertBalance(client, params.userId, params.currency, -params.amount);
    await client.query(
      `INSERT INTO ledger_entries (user_id, currency, amount, title, subtitle, category, meta)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [params.userId, params.currency, -params.amount, params.title, params.subtitle ?? null, params.category, JSON.stringify(params.meta ?? {})]
    );
    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Debits `fromUserId` and credits `toUserId` inside a single Postgres
 * transaction — the real-money version of the Flutter app's
 * `LedgerService.internalTransferOut` (`lib/state/services/
 * ledger_service.dart:141`), except both sides are now real users
 * instead of an unbacked demo counterparty. Row-locks the sender's
 * balance (via the same `FOR UPDATE` pattern as `debit`) before checking
 * sufficiency, so two concurrent sends from the same user can't both
 * read a stale balance and overdraw it.
 */
export async function transferBetweenUsers(params: {
  fromUserId: string;
  toUserId: string;
  currency: string;
  amount: number;
  title: string;
  subtitle?: string;
  meta?: Record<string, unknown>;
}): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { rows } = await client.query<{ amount: string }>(
      `SELECT amount FROM balances WHERE user_id = $1 AND currency = $2 FOR UPDATE`,
      [params.fromUserId, params.currency]
    );
    const have = rows.length ? Number(rows[0].amount) : 0;
    if (have < params.amount - 1e-9) {
      await client.query("ROLLBACK");
      throw new InsufficientFundsError(params.currency, params.amount - have);
    }

    await upsertBalance(client, params.fromUserId, params.currency, -params.amount);
    await client.query(
      `INSERT INTO ledger_entries (user_id, currency, amount, title, subtitle, category, counterparty, meta)
       VALUES ($1, $2, $3, $4, $5, 'transfer', $6, $7)`,
      [params.fromUserId, params.currency, -params.amount, params.title, params.subtitle ?? null, params.toUserId, JSON.stringify(params.meta ?? {})]
    );

    await upsertBalance(client, params.toUserId, params.currency, params.amount);
    await client.query(
      `INSERT INTO ledger_entries (user_id, currency, amount, title, subtitle, category, counterparty, meta)
       VALUES ($1, $2, $3, $4, $5, 'transfer', $6, $7)`,
      [params.toUserId, params.currency, params.amount, "Received transfer", params.subtitle ?? null, params.fromUserId, JSON.stringify(params.meta ?? {})]
    );

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

async function upsertBalance(client: PoolClient, userId: string, currency: string, delta: number) {
  await client.query(
    `INSERT INTO balances (user_id, currency, amount) VALUES ($1, $2, $3)
     ON CONFLICT (user_id, currency) DO UPDATE SET amount = balances.amount + $3`,
    [userId, currency, delta]
  );
}

export async function getBalances(userId: string): Promise<Record<string, string>> {
  const { rows } = await pool.query<{ currency: string; amount: string }>(`SELECT currency, amount FROM balances WHERE user_id = $1`, [userId]);
  const out: Record<string, string> = {};
  for (const r of rows) out[r.currency] = r.amount;
  return out;
}

export async function getLedger(userId: string, limit = 50) {
  const { rows } = await pool.query(`SELECT * FROM ledger_entries WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2`, [userId, limit]);
  return rows;
}
