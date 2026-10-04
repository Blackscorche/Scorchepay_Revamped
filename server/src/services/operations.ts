import { createHash } from 'crypto';
import { pool } from '../db/pool';
import { parseNgn, username, operationKey } from '../domain/money';

export class OperationConflict extends Error {}
export interface TransferInput { userId: string; id: string; toUsername: string; currency: string; amount: string; note?: string }

/** One commit owns the operation result, reservation, balanced journal,
 * wallet projection and receipt. The same key returns the original result.
 * A failed/rolled-back attempt cannot leave an uncaptured reservation. */
export async function executeTransfer(input: TransferInput) {
  const id = operationKey(input.id);
  const recipientName = username(input.toUsername);
  if (input.currency !== 'NGN') throw new Error('Only NGN transfers are enabled');
  const amount = parseNgn(input.amount);
  if (input.note != null && (typeof input.note !== 'string' || input.note.length > 200)) throw new Error('Note must be at most 200 characters');
  const fingerprint = createHash('sha256').update(JSON.stringify([recipientName, input.currency, amount.decimal, input.note ?? ''])).digest('hex');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`SELECT pg_advisory_xact_lock(hashtextextended($1, 0))`, [`${input.userId}:${id}`]);
    const prior = await client.query('SELECT fingerprint, result FROM money_operations WHERE user_id=$1 AND id=$2', [input.userId, id]);
    if (prior.rows.length) {
      if (prior.rows[0].fingerprint !== fingerprint) throw new OperationConflict('This operation ID was already used for different details');
      await client.query('COMMIT');
      return prior.rows[0].result;
    }
    const recipient = await client.query(`SELECT id, display_name, username FROM users WHERE lower(regexp_replace(username, '^@', ''))=$1 AND phone_verified=true`, [recipientName]);
    let reason: string | undefined;
    if (recipient.rows.length !== 1) reason = 'Recipient not found or not verified';
    else if (recipient.rows[0].id === input.userId) reason = 'Cannot send money to yourself';
    if (!reason) {
      // Acquire both accounts in the same order, including first-use rows.
      const users = [input.userId, recipient.rows[0].id].sort();
      for (const user of users) {
        await client.query(`INSERT INTO balances(user_id,currency,amount) VALUES($1,'NGN',0) ON CONFLICT DO NOTHING`, [user]);
        await client.query(`SELECT amount FROM balances WHERE user_id=$1 AND currency='NGN' FOR UPDATE`, [user]);
      }
      const funds = await client.query(`SELECT amount >= $2::numeric AS enough FROM balances WHERE user_id=$1 AND currency='NGN'`, [input.userId, amount.decimal]);
      if (!funds.rows[0].enough) reason = 'Insufficient NGN balance';
    }
    const result = { id, status: reason ? 'failed' : 'completed', currency: 'NGN', amount: amount.decimal,
      recipient: recipient.rows[0]?.display_name ?? recipientName, ...(reason ? { error: reason } : {}) };
    await client.query(`INSERT INTO money_operations(user_id,id,fingerprint,status,result) VALUES($1,$2,$3,$4,$5)`, [input.userId,id,fingerprint,result.status,JSON.stringify(result)]);
    if (!reason) {
      const recipientId = recipient.rows[0].id;
      await client.query(`INSERT INTO money_holds(user_id,operation_id,currency,amount_minor,status) VALUES($1,$2,'NGN',$3,'reserved')`, [input.userId,id,amount.minor.toString()]);
      await client.query(`UPDATE balances SET amount=amount-$2::numeric WHERE user_id=$1 AND currency='NGN'`, [input.userId,amount.decimal]);
      await client.query(`UPDATE balances SET amount=amount+$2::numeric WHERE user_id=$1 AND currency='NGN'`, [recipientId,amount.decimal]);
      await client.query(`INSERT INTO journal_postings(operation_user_id,operation_id,user_id,currency,amount_minor) VALUES($1,$2,$1,'NGN',-$4::numeric),($1,$2,$3,'NGN',$4::numeric)`, [input.userId,id,recipientId,amount.minor.toString()]);
      for (const [user, other, signed, title] of [
        [input.userId,recipientId,`-${amount.decimal}`,`Sent to ${recipient.rows[0].display_name}`],
        [recipientId,input.userId,amount.decimal,'Received transfer'],
      ]) {
        await client.query(`INSERT INTO ledger_entries(user_id,currency,amount,title,subtitle,category,counterparty,reference,meta) VALUES($1,'NGN',$2,$3,$4,'transfer',$5,$6,$7)`,
          [user,signed,title,input.note ?? null,other,`${input.userId}:${id}:${user}`,JSON.stringify({operationId:id})]);
      }
      await client.query(`UPDATE money_holds SET status='captured' WHERE user_id=$1 AND operation_id=$2 AND status='reserved'`,[input.userId,id]);
    }
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally { client.release(); }
}
