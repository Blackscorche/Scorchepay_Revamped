import { Router } from "express";
import { pool } from "../db/pool";
import { getBalances, getLedger } from "../services/ledger";

export const walletRouter = Router();

walletRouter.get('/snapshot', async (req,res,next) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
    const balances = await client.query(`SELECT currency,amount::text FROM balances WHERE user_id=$1 AND currency='NGN'`,[req.userId]);
    const ledger = await client.query(`SELECT id,created_at,currency,amount::text,title,status,meta FROM ledger_entries WHERE user_id=$1 AND currency='NGN' ORDER BY created_at DESC LIMIT 50`,[req.userId]);
    const operations = await client.query('SELECT result FROM money_operations WHERE user_id=$1 ORDER BY created_at DESC LIMIT 20',[req.userId]);
    await client.query('COMMIT');
    res.json({balances:Object.fromEntries(balances.rows.map(r=>[r.currency,r.amount])),ledger:ledger.rows,operations:operations.rows.map(r=>r.result)});
  } catch(error) { await client.query('ROLLBACK'); next(error); }
  finally { client.release(); }
});

// No :userId param — this router is mounted behind requireAuth, so the
// wallet in question is always the caller's own (req.userId). A userId
// in the URL would let one authenticated user read another's balance
// just by changing the path.
walletRouter.get("/balance", async (req, res, next) => {
  try {
    res.json(await getBalances(req.userId!));
  } catch (err) {
    next(err);
  }
});

walletRouter.get("/ledger", async (req, res, next) => {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    if (!Number.isInteger(limit) || limit < 1 || limit > 100) return res.status(400).json({error:"Invalid limit"});
    res.json(await getLedger(req.userId!, limit));
  } catch (err) {
    next(err);
  }
});
