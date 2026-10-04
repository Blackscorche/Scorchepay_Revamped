import { Router } from 'express';
import { pool } from '../db/pool';
import { executeTransfer, OperationConflict } from '../services/operations';
import { operationKey, parseNgn, username } from '../domain/money';
import { verifyPin } from '../services/auth';
import { allowAttempt } from '../middleware/authSafety';
export const transfersRouter = Router();

transfersRouter.get('/recipient', async (req,res,next) => {
  try {
    let name: string;
    try { name = username(req.query.username); } catch(error) { return res.status(400).json({error:(error as Error).message}); }
    if (!(await allowAttempt('recipient', req.userId!, 60, 60))) return res.status(429).json({error:'Please wait before searching again'});
    const {rows} = await pool.query(`SELECT username,display_name FROM users WHERE lower(regexp_replace(username,'^@',''))=$1 AND phone_verified=true`,[name]);
    if (rows.length !== 1) return res.status(404).json({error:'Recipient not found'});
    res.json(rows[0]);
  } catch(error) { next(error); }
});
transfersRouter.get('/operations/:id', async (req,res,next) => {
  try {
    let id: string;
    try { id = operationKey(req.params.id); } catch { return res.status(400).json({error:'Invalid operation ID'}); }
    const {rows} = await pool.query('SELECT result FROM money_operations WHERE user_id=$1 AND id=$2',[req.userId,id]);
    // Not found is not proof of failure: a request may still be in flight.
    res.json(rows[0]?.result ?? {id,status:'unknown'});
  } catch(error) { next(error); }
});
transfersRouter.post('/send', async (req,res,next) => {
  try {
    const {toUsername,currency,amount,note,pin} = req.body;
    let id: string;
    try {
      id = operationKey(req.get('Idempotency-Key'));
      username(toUsername); parseNgn(amount);
      if (currency !== 'NGN') throw new Error('Only NGN transfers are enabled');
      if (note != null && (typeof note !== 'string' || note.length > 200)) throw new Error('Note must be at most 200 characters');
      if (typeof pin !== 'string' || !/^\d{4}$/.test(pin)) throw new Error('Enter your four-digit PIN');
    } catch(error) { return res.status(400).json({error:(error as Error).message}); }
    if (!(await allowAttempt('transaction-pin',req.userId!))) return res.status(429).json({error:'Too many PIN attempts. Try again in 15 minutes.'});
    const {rows} = await pool.query('SELECT pin_hash FROM users WHERE id=$1',[req.userId]);
    if (!rows[0]?.pin_hash || !(await verifyPin(pin,rows[0].pin_hash))) return res.status(403).json({error:'Incorrect PIN'});
    res.json(await executeTransfer({userId:req.userId!,id,toUsername,currency,amount,note}));
  } catch(error) {
    if (error instanceof OperationConflict) return res.status(409).json({error:error.message});
    next(error);
  }
});
