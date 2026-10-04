import axios from "axios";
import dotenv from "dotenv";

import { estimateConvert } from "./rates";

dotenv.config();

/**
 * Quidax — SEC-provisionally-licensed Nigerian crypto exchange (Aug 2024
 * ARIP license), integrated here purely as a crypto→fiat conversion
 * primitive for the funding waterfall (see the plan's "Core architecture"
 * note) — not the full buy/sell/swap trading UI, which is its own later
 * phase. Confirmed from public docs: Bearer auth with the account's API
 * secret key, instant orders created at
 * `POST /users/{user_id}/instant_orders`. The exact request body fields
 * below (`bid`/`ask`/`type`/`volume`) are Quidax's documented instant-order
 * shape but **weren't confirmed against a live sandbox response** (their
 * interactive doc site couldn't be fully crawled) — verify against a real
 * test account before relying on this beyond local testing.
 *
 * Until QUIDAX_SECRET_KEY is set, conversions fall back to a live CoinGecko-
 * priced estimate, so the funding waterfall's crypto leg is fully
 * testable before a Quidax account exists.
 */

function secretKey(): string | null {
  const key = process.env.QUIDAX_SECRET_KEY;
  if (!key || key.includes("xxxxxxxx")) return null;
  return key;
}

const client = axios.create({ baseURL: "https://app.quidax.io/api/v1" });

/**
 * Sells [amount] of [cryptoCurrency] at market for [fiatCurrency] — the
 * only direction the funding waterfall needs (crypto funds a fiat
 * payment). `quidaxUserId` is the user's own Quidax sub-account id, which
 * doesn't exist yet (Quidax sub-account provisioning is part of the full
 * crypto trading phase, not this conversion primitive) — falls back to
 * the estimate whenever it's absent, same as a missing key.
 */
export async function sellAtMarket(params: {
  quidaxUserId?: string | null;
  cryptoCurrency: string;
  fiatCurrency: string;
  amount: number;
}): Promise<{ convertedAmount: number; real: boolean }> {
  const key = secretKey();
  if (!key || !params.quidaxUserId) {
    const convertedAmount = await estimateConvert(params.amount, params.cryptoCurrency, params.fiatCurrency);
    return { convertedAmount, real: false };
  }

  const { data } = await client.post(
    `/users/${params.quidaxUserId}/instant_orders`,
    {
      bid: params.fiatCurrency.toLowerCase(),
      ask: params.cryptoCurrency.toLowerCase(),
      type: "sell",
      volume: params.amount,
    },
    { headers: { Authorization: `Bearer ${key}` } }
  );
  return { convertedAmount: Number(data.data.total?.amount ?? data.data.received_amount), real: true };
}
