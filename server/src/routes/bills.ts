import { Router } from "express";
import { v4 as uuid } from "uuid";
import { pool } from "../db/pool";
import { planPayment, isPlanSufficient, debitLegs, refundLegs } from "../services/smartPay";
import { payAirtime } from "../services/vtpass";

export const billsRouter = Router();

/**
 * Real airtime top-up, funded through the Smart Pay waterfall — the
 * server-side twin of the Flutter app's Smart Pay bill-payment flow. Only
 * airtime is wired to VTpass so far (the simplest of its products, and
 * the one whose request shape is fully confirmed against public docs);
 * data/electricity/cable need VTpass's variation-code lookup endpoints
 * too and are natural next additions using the same
 * `payVariationService` helper already in `services/vtpass.ts`.
 */
billsRouter.post("/airtime", async (req, res, next) => {
  try {
    const { network, phone, amount, fixedSourceCurrency } = req.body;
    if (!network || !phone || !amount) {
      return res.status(400).json({ error: "network, phone, and amount are required" });
    }
    const userId = req.userId!;

    const plan = await planPayment({
      userId,
      nativeCurrency: "NGN",
      nativeAmount: amount,
      fixedSourceCurrency,
    });
    if (!isPlanSufficient(plan)) {
      return res.status(422).json({ error: `You are short by ${plan.shortBy.toFixed(2)} NGN`, plan });
    }

    const { rows } = await pool.query(
      `INSERT INTO biller_transactions (user_id, biller, service_id, amount, currency, funding_legs)
       VALUES ($1, $2, $3, $4, 'NGN', $5) RETURNING id`,
      [userId, "Airtime", network, amount, JSON.stringify(plan.legs)]
    );
    const transactionId = rows[0].id;

    await debitLegs(userId, plan, `Smart Pay · ${network} airtime`);

    try {
      const requestId = `scp_${uuid()}`;
      const result = await payAirtime({ requestId, serviceID: network, amount, phone });

      if (!result.success) {
        // Provider rejected after funds were already moved — refund every
        // leg, same as SmartPayEngine.payBill's provider-failure path.
        await refundLegs(userId, plan.legs, `${network} airtime`);
        await pool.query(`UPDATE biller_transactions SET status = 'failed' WHERE id = $1`, [transactionId]);
        return res.status(502).json({ error: result.responseDescription || "Airtime purchase failed" });
      }

      await pool.query(`UPDATE biller_transactions SET status = 'success', vtpass_transaction_id = $2 WHERE id = $1`, [transactionId, result.transactionId]);
      res.json({ status: "success", transactionId: result.transactionId, plan });
    } catch (providerErr) {
      await refundLegs(userId, plan.legs, `${network} airtime`);
      await pool.query(`UPDATE biller_transactions SET status = 'failed' WHERE id = $1`, [transactionId]);
      throw providerErr;
    }
  } catch (err) {
    next(err);
  }
});
