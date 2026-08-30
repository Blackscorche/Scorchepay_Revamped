import axios from "axios";
import crypto from "crypto";
import dotenv from "dotenv";

dotenv.config();

// Checked lazily (on first real Paystack call) rather than at import
// time, so the server can still boot and serve /health and non-payment
// routes before a real test key has been added to .env.
function secretKey(): string {
  const key = process.env.PAYSTACK_SECRET_KEY;
  if (!key || key.includes("xxxxxxxx")) {
    throw new Error("PAYSTACK_SECRET_KEY is not set — copy .env.example to .env and add your free test key from the Paystack dashboard.");
  }
  return key;
}

const client = axios.create({ baseURL: "https://api.paystack.co" });
client.interceptors.request.use((config) => {
  config.headers.Authorization = `Bearer ${secretKey()}`;
  config.headers["Content-Type"] = "application/json";
  return config;
});

export interface InitializeResult {
  authorizationUrl: string;
  accessCode: string;
  reference: string;
}

/**
 * Starts a real Paystack transaction (card / bank / USSD, whatever the
 * checkout page offers) for `amountNaira` naira. The returned
 * `authorizationUrl` is what the Flutter app opens (in-app browser or
 * WebView) for the user to actually pay.
 */
export async function initializeTransaction(params: {
  email: string;
  amountNaira: number;
  reference: string;
  currency?: string;
}): Promise<InitializeResult> {
  const { data } = await client.post("/transaction/initialize", {
    email: params.email,
    amount: Math.round(params.amountNaira * 100), // Paystack expects kobo
    reference: params.reference,
    currency: params.currency ?? "NGN",
  });
  return {
    authorizationUrl: data.data.authorization_url,
    accessCode: data.data.access_code,
    reference: data.data.reference,
  };
}

export interface VerifyResult {
  status: "success" | "failed" | "abandoned" | string;
  amountNaira: number;
  currency: string;
  channel: string | null;
  reference: string;
}

/** Server-side verification — never trust a client's "payment done" claim alone. */
export async function verifyTransaction(reference: string): Promise<VerifyResult> {
  const { data } = await client.get(`/transaction/verify/${encodeURIComponent(reference)}`);
  const d = data.data;
  return {
    status: d.status,
    amountNaira: d.amount / 100,
    currency: d.currency,
    channel: d.channel ?? null,
    reference: d.reference,
  };
}

/**
 * Verifies the `x-paystack-signature` header against the raw request
 * body (HMAC-SHA512 with the account's secret key) — exactly the
 * shared-secret pattern flagged in the spec. `rawBody` must be the
 * untouched request bytes, not a re-serialized JSON object, or the
 * signature will never match.
 */
export function verifyWebhookSignature(rawBody: Buffer, signatureHeader: string | undefined): boolean {
  if (!signatureHeader) return false;
  const expected = crypto.createHmac("sha512", secretKey()).update(rawBody).digest("hex");
  // Constant-time compare so this can't be timing-attacked.
  const a = Buffer.from(expected);
  const b = Buffer.from(signatureHeader);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export interface CustomerResult {
  customerCode: string;
}

export async function createCustomer(params: { email: string; firstName: string; lastName: string; phone?: string }): Promise<CustomerResult> {
  const { data } = await client.post("/customer", {
    email: params.email,
    first_name: params.firstName,
    last_name: params.lastName,
    phone: params.phone,
  });
  return { customerCode: data.data.customer_code };
}

export interface DedicatedAccountResult {
  accountNumber: string;
  bankName: string;
  accountId: string;
}

/**
 * Creates a dedicated virtual account (the "fund via bank transfer"
 * rail from the spec — money sent to this NUBAN from any bank lands
 * automatically via a webhook). In Paystack **test mode** this only
 * works with `preferredBank: 'test-bank'`; real banks (Wema, Titan)
 * require your business to be KYB-verified on a live Paystack account.
 */
export async function createDedicatedVirtualAccount(params: { customerCode: string; preferredBank?: string }): Promise<DedicatedAccountResult> {
  const { data } = await client.post("/dedicated_account", {
    customer: params.customerCode,
    preferred_bank: params.preferredBank ?? "test-bank",
  });
  return {
    accountNumber: data.data.account_number,
    bankName: data.data.bank.name,
    accountId: data.data.id,
  };
}
