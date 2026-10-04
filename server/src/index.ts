import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import { requireVerified } from "./middleware/authSafety";
import { authRouter } from "./routes/auth";
import { walletRouter } from "./routes/wallet";
import { transfersRouter } from "./routes/transfers";
import { errorHandler } from "./middleware/errorHandler";
import { requireAuth } from "./middleware/requireAuth";
import { pool } from "./db/pool";

dotenv.config();

const app = express();

// Do not acknowledge unimplemented provider reconciliation as successful.
app.use("/api/webhooks", (_req,res) => { res.status(503).json({error:"Provider reconciliation is not enabled yet"}); });

app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") ?? false }));
app.use(express.json({limit:"32kb"}));

app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ ok: true, db: "connected" });
  } catch {
    res.status(500).json({ ok: false, db: "unreachable" });
  }
});

app.use("/api/auth", authRouter);
// Legacy provider routes are intentionally unavailable until their contract,
// reconciliation and idempotency release gates have passed.
const providerUnavailable: express.RequestHandler = (_req,res) => { res.status(503).json({error:'This payment rail is not enabled yet'}); };
app.use("/api/payments", requireAuth, requireVerified, providerUnavailable);
app.use("/api/wallet", requireAuth, requireVerified, walletRouter);
app.use("/api/transfers", requireAuth, requireVerified, transfersRouter);
app.use("/api/bills", requireAuth, requireVerified, providerUnavailable);

app.use(errorHandler);

const port = process.env.PORT ? Number(process.env.PORT) : 4000;
app.listen(port, () => {
  console.log(`ScorchePay server listening on http://localhost:${port}`);
});
