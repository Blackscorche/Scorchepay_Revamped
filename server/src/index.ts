import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import { usersRouter } from "./routes/users";
import { paymentsRouter } from "./routes/payments";
import { webhooksRouter } from "./routes/webhooks";
import { walletRouter } from "./routes/wallet";
import { errorHandler } from "./middleware/errorHandler";
import { pool } from "./db/pool";

dotenv.config();

const app = express();

// The webhook route needs the raw request body to verify Paystack's
// signature — it must be mounted with express.raw() *before* the
// general express.json() parser below, or the signature will never
// match (JSON.parse + re-stringify doesn't reproduce the exact bytes
// Paystack signed).
app.use("/api/webhooks", express.raw({ type: "application/json" }), webhooksRouter);

app.use(cors());
app.use(express.json());

app.get("/health", async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    res.json({ ok: true, db: "connected" });
  } catch {
    res.status(500).json({ ok: false, db: "unreachable" });
  }
});

app.use("/api/users", usersRouter);
app.use("/api/payments", paymentsRouter);
app.use("/api/wallet", walletRouter);

app.use(errorHandler);

const port = process.env.PORT ? Number(process.env.PORT) : 4000;
app.listen(port, () => {
  console.log(`ScorchePay server listening on http://localhost:${port}`);
});
