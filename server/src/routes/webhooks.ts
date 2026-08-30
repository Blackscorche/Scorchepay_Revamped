import { Router } from "express";
import { pool } from "../db/pool";
import { verifyWebhookSignature } from "../services/paystack";
import { credit } from "../services/ledger";

export const webhooksRouter = Router();

/**
 * Real Paystack webhook handler — this route is mounted with
 * `express.raw()` (see index.ts) specifically so `req.body` here is the
 * untouched byte buffer the signature was computed over. Never trust an
 * inbound "payment received" event without verifying this signature
 * first (spec §26 / walkthrough §8 step 4) — anyone who finds this URL
 * could otherwise POST a fake success event and get credited for free.
 */
webhooksRouter.post("/paystack", async (req, res) => {
  const signature = req.header("x-paystack-signature");
  const rawBody = req.body as Buffer;

  if (!verifyWebhookSignature(rawBody, signature)) {
    console.warn("Rejected webhook with invalid signature");
    return res.status(401).json({ error: "Invalid signature" });
  }

  const event = JSON.parse(rawBody.toString("utf-8"));

  try {
    if (event.event === "charge.success") {
      const reference: string = event.data.reference;
      const { rows } = await pool.query(`SELECT * FROM payment_transactions WHERE reference = $1`, [reference]);

      // Idempotency guard: a webhook can legitimately be delivered more
      // than once (Paystack retries on anything but a 2xx), and the
      // client's own /verify call may have already processed it first.
      if (!rows.length || rows[0].status === "success") {
        return res.sendStatus(200);
      }

      const amountNaira = event.data.amount / 100;
      const currency = event.data.currency;
      const channel = event.data.channel;

      await pool.query(`UPDATE payment_transactions SET status = 'success', channel = $2, verified_at = now() WHERE reference = $1`, [reference, channel]);
      await credit({
        userId: rows[0].user_id,
        currency,
        amount: amountNaira,
        title: "Wallet top-up",
        subtitle: `Paystack · ${channel}`,
        category: "deposit",
        reference,
      });
    }

    if (event.event === "dedicatedaccount.credit" || event.event === "transfer.received") {
      // Inbound bank-transfer-to-virtual-account credit — same idempotent
      // credit path, keyed by Paystack's own reference for this event.
      const reference: string = event.data.reference ?? event.data.id?.toString();
      const amountNaira = event.data.amount / 100;
      const userLookup = await pool.query(`SELECT user_id FROM virtual_accounts WHERE account_number = $1`, [event.data.account_number ?? event.data.recipient?.details?.account_number]);
      if (userLookup.rows.length && reference) {
        const already = await pool.query(`SELECT 1 FROM payment_transactions WHERE reference = $1`, [reference]);
        if (!already.rows.length) {
          await pool.query(`INSERT INTO payment_transactions (reference, user_id, amount, currency, status, channel, verified_at) VALUES ($1, $2, $3, $4, 'success', 'dedicated_nuban', now())`, [
            reference,
            userLookup.rows[0].user_id,
            amountNaira,
            "NGN",
          ]);
          await credit({
            userId: userLookup.rows[0].user_id,
            currency: "NGN",
            amount: amountNaira,
            title: "Bank transfer received",
            subtitle: "Dedicated virtual account",
            category: "deposit",
            reference,
          });
        }
      }
    }
  } catch (err) {
    console.error("Webhook processing failed:", err);
    // Still 200 — Paystack will otherwise retry indefinitely on an event
    // we've already logged and will need to investigate manually rather
    // than auto-retry into.
  }

  res.sendStatus(200);
});
