import { Router } from "express";
import { getBalances, getLedger } from "../services/ledger";

export const walletRouter = Router();

walletRouter.get("/:userId/balance", async (req, res, next) => {
  try {
    res.json(await getBalances(req.params.userId));
  } catch (err) {
    next(err);
  }
});

walletRouter.get("/:userId/ledger", async (req, res, next) => {
  try {
    const limit = req.query.limit ? Number(req.query.limit) : 50;
    res.json(await getLedger(req.params.userId, limit));
  } catch (err) {
    next(err);
  }
});
