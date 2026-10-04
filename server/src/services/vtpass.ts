import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

/**
 * VTpass — biller aggregator for airtime, data, electricity, cable.
 * Confirmed against public docs (vtpass.com/documentation): Basic Auth
 * with your VTpass email:password, POST to /pay with `request_id` +
 * `serviceID` + service-specific fields (`amount`+`phone` for airtime,
 * `billersCode`+`variation_code`+`amount`+`phone` for data/electricity).
 */

function authHeader(): string {
  const email = process.env.VTPASS_EMAIL;
  const password = process.env.VTPASS_PASSWORD;
  if (!email || !password || email.includes("xxxxxxxx")) {
    throw new Error("VTPASS_EMAIL/VTPASS_PASSWORD not set — get free sandbox credentials at https://vtpass.com/#/register.");
  }
  return "Basic " + Buffer.from(`${email}:${password}`).toString("base64");
}

function baseUrl(): string {
  return process.env.VTPASS_ENV === "live" ? "https://vtpass.com/api" : "https://sandbox.vtpass.com/api";
}

export interface VtpassResult {
  success: boolean;
  transactionId: string | null;
  responseDescription: string;
}

/** Airtime top-up — the simplest VTpass product (no billersCode/variation needed). */
export async function payAirtime(params: {
  requestId: string;
  serviceID: string; // 'mtn' | 'glo' | 'airtel' | 'etisalat'
  amount: number;
  phone: string;
}): Promise<VtpassResult> {
  const { data } = await axios.post(
    `${baseUrl()}/pay`,
    { request_id: params.requestId, serviceID: params.serviceID, amount: params.amount, phone: params.phone },
    { headers: { Authorization: authHeader(), "Content-Type": "application/json" } }
  );
  return {
    success: data.code === "000",
    transactionId: data.content?.transactions?.transactionId ?? null,
    responseDescription: data.response_description ?? "Unknown response",
  };
}

/** Data bundles, electricity tokens, cable subscriptions — anything needing a billersCode + variation_code. */
export async function payVariationService(params: {
  requestId: string;
  serviceID: string;
  billersCode: string; // meter number, phone number, smartcard number, etc.
  variationCode: string; // the specific plan/bundle
  amount: number;
  phone: string;
}): Promise<VtpassResult> {
  const { data } = await axios.post(
    `${baseUrl()}/pay`,
    {
      request_id: params.requestId,
      serviceID: params.serviceID,
      billersCode: params.billersCode,
      variation_code: params.variationCode,
      amount: params.amount,
      phone: params.phone,
    },
    { headers: { Authorization: authHeader(), "Content-Type": "application/json" } }
  );
  return {
    success: data.code === "000",
    transactionId: data.content?.transactions?.transactionId ?? null,
    responseDescription: data.response_description ?? "Unknown response",
  };
}
