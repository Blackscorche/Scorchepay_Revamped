import { Router } from "express";
import { v4 as uuid } from "uuid";
import { pool } from "../db/pool";
import { initializeTransaction, verifyTransaction, createDedicatedVirtualAccount } from "../services/paystack";
import { credit } from "../services/ledger";

export const paymentsRouter = Router();

/** Step 1 of a card/bank-transfer top-up: get a real Paystack checkout URL. */
paymentsRouter.post("/initialize", async (req, res, next) => {
  try {
    const { email, amountNaira } = req.body;
    if (!email || !amountNaira) {
      return res.status(400).json({ error: "email and amountNaira are required" });
    }
    const userId = req.userId!;

    const reference = `scp_${uuid()}`;
    await pool.query(`INSERT INTO payment_transactions (reference, user_id, amount, currency, status) VALUES ($1, $2, $3, $4, 'pending')`, [
      reference,
      userId,
      amountNaira,
      "NGN",
    ]);

    const result = await initializeTransaction({ email, amountNaira, reference });
    res.json(result);
  } catch (err) {
    next(err);
  }
});

/**
 * Step 2 (belt-and-braces alongside the webhook) — the Flutter app calls
 * this right after the user returns from Paystack's checkout. Verifying
 * server-side, and only crediting once per reference, is what makes it
 * safe even if the webhook is slow or the client calls this twice.
 */
paymentsRouter.get("/verify/:reference", async (req, res, next) => {
  try {
    const { reference } = req.params;
    const { rows } = await pool.query(`SELECT * FROM payment_transactions WHERE reference = $1`, [reference]);
    if (!rows.length) return res.status(404).json({ error: "Unknown reference" });
    const txn = rows[0];
    if (txn.user_id !== req.userId) return res.status(404).json({ error: "Unknown reference" });

    if (txn.status === "success") {
      return res.json({ status: "success", alreadyProcessed: true });
    }

    const verified = await verifyTransaction(reference);
    if (verified.status !== "success") {
      await pool.query(`UPDATE payment_transactions SET status = 'failed' WHERE reference = $1`, [reference]);
      return res.json({ status: verified.status });
    }

    await pool.query(`UPDATE payment_transactions SET status = 'success', channel = $2, verified_at = now() WHERE reference = $1`, [reference, verified.channel]);
    await credit({
      userId: txn.user_id,
      currency: verified.currency,
      amount: verified.amountNaira,
      title: "Wallet top-up",
      subtitle: `Paystack · ${verified.channel ?? "card"}`,
      category: "deposit",
      reference,
    });

    res.json({ status: "success", amount: verified.amountNaira, currency: verified.currency });
  } catch (err) {
    next(err);
  }
});

/** Creates the user's dedicated virtual account (spec §9's bank-transfer funding rail). */
paymentsRouter.post("/virtual-account", async (req, res, next) => {
  try {
    const userId = req.userId!;
    const { rows } = await pool.query(`SELECT paystack_customer_code FROM users WHERE id = $1`, [userId]);
    if (!rows.length) return res.status(404).json({ error: "User not found" });

    const existing = await pool.query(`SELECT * FROM virtual_accounts WHERE user_id = $1`, [userId]);
    if (existing.rows.length) return res.json(existing.rows[0]);

    const account = await createDedicatedVirtualAccount({ customerCode: rows[0].paystack_customer_code });
    const inserted = await pool.query(
      `INSERT INTO virtual_accounts (user_id, account_number, bank_name, paystack_account_id) VALUES ($1, $2, $3, $4) RETURNING *`,
      [userId, account.accountNumber, account.bankName, account.accountId]
    );
    res.status(201).json(inserted.rows[0]);
  } catch (err) {
    next(err);
  }
});
