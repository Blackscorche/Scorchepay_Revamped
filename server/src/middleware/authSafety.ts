import { RequestHandler } from 'express';
import { createHash } from 'crypto';
import { pool } from '../db/pool';

/** Persistent attempt budgets apply across server processes/restarts. */
export async function allowAttempt(scope: string, subject: string, limit = 8, seconds = 900): Promise<boolean> {
  const bucket = createHash('sha256').update(`${scope}:${subject}`).digest('hex');
  const {rows} = await pool.query(`INSERT INTO auth_attempts(bucket,attempts,resets_at) VALUES($1,1,now()+$2*interval '1 second')
    ON CONFLICT(bucket) DO UPDATE SET attempts=CASE WHEN auth_attempts.resets_at<=now() THEN 1 ELSE auth_attempts.attempts+1 END,
    resets_at=CASE WHEN auth_attempts.resets_at<=now() THEN now()+$2*interval '1 second' ELSE auth_attempts.resets_at END RETURNING attempts`,[bucket,seconds]);
  return rows[0].attempts <= limit;
}
export const requireVerified: RequestHandler = async (req,res,next) => {
  try {
    const {rows} = await pool.query('SELECT phone_verified FROM users WHERE id=$1',[req.userId]);
    if (!rows[0]?.phone_verified) return res.status(403).json({error:'Verify your phone before using your wallet'});
    next();
  } catch(error) { next(error); }
};
