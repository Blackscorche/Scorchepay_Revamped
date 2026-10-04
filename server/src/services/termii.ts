import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const client = axios.create({ baseURL: "https://v3.api.termii.com", timeout: 8000 });

/** Sends verification through the configured SMS provider; never logs codes. */
export async function sendOtpSms(phone: string, code: string): Promise<void> {
  const apiKey = process.env.TERMII_API_KEY;
  if (!apiKey || apiKey.includes("xxxxxxxx")) {
    throw new Error("SMS provider is not configured");
  }

  await client.post("/api/sms/send", {
    api_key: apiKey,
    to: phone,
    from: process.env.TERMII_SENDER_ID ?? "ScorchePay",
    sms: `Your ScorchePay verification code is ${code}. It expires in 10 minutes.`,
    type: "plain",
    channel: "generic",
  });
}
