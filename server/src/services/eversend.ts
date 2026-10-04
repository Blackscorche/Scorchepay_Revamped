import axios from "axios";
import dotenv from "dotenv";

import { estimateConvert } from "./rates";

dotenv.config();

/**
 * Eversend Platform API — real multi-currency fiat conversion (see the
 * plan's "Core architecture" note: this is what makes a NGN bill able to
 * genuinely draw down a real USD/GHS/EUR/GBP balance). Endpoint and auth
 * shape below are the best-confirmed reading of Eversend's public docs
 * (`POST /v1/conversions`, Bearer client credentials) — Eversend's full
 * reference is behind an interactive doc site that couldn't be fully
 * crawled, so **verify field names against a real sandbox account before
 * relying on this in anything beyond local testing**.
 *
 * Until EVERSEND_CLIENT_ID/SECRET are set, conversions fall back to a
 * live-rate estimate (same free rate source the Flutter app already
 * uses) — inexact vs. a real quoted rate, but real enough to fully
 * exercise the funding waterfall before an Eversend account exists.
 */

function credentials(): { clientId: string; clientSecret: string } | null {
  const clientId = process.env.EVERSEND_CLIENT_ID;
  const clientSecret = process.env.EVERSEND_CLIENT_SECRET;
  if (!clientId || !clientSecret || clientId.includes("xxxxxxxx")) return null;
  return { clientId, clientSecret };
}

const client = axios.create({ baseURL: "https://api.eversend.co/v1" });

/** Converts [amount] of [from] into [to] — real quote+execute via Eversend if configured, else a live-rate estimate. */
export async function convert(params: { from: string; to: string; amount: number }): Promise<{ convertedAmount: number; real: boolean }> {
  const creds = credentials();
  if (!creds) {
    const convertedAmount = await estimateConvert(params.amount, params.from, params.to);
    return { convertedAmount, real: false };
  }

  const { data } = await client.post(
    "/conversions",
    { from: params.from, to: params.to, amount: params.amount },
    { headers: { Authorization: `Bearer ${creds.clientSecret}`, "X-Client-Id": creds.clientId } }
  );
  return { convertedAmount: data.data.amountReceived ?? data.data.to?.amount, real: true };
}
