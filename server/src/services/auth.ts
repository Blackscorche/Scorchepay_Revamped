import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { randomInt, randomBytes } from "crypto";
import dotenv from "dotenv";

import { pool } from "../db/pool";

dotenv.config();

function jwtSecret(): string {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.includes("xxxxxxxx")) {
    throw new Error("JWT_SECRET is not set — add a long random string to .env.");
  }
  return secret;
}

const ACCESS_TOKEN_TTL = "15m";
const REFRESH_TOKEN_TTL_DAYS = 30;
const OTP_TTL_MINUTES = 10;

export async function hashPin(pin: string): Promise<string> {
  return bcrypt.hash(pin, 10);
}

export async function verifyPin(pin: string, hash: string): Promise<boolean> {
  return bcrypt.compare(pin, hash);
}

export function signAccessToken(userId: string): string {
  return jwt.sign({ sub: userId }, jwtSecret(), { expiresIn: ACCESS_TOKEN_TTL });
}

export function verifyAccessToken(token: string): { sub: string } {
  return jwt.verify(token, jwtSecret()) as { sub: string };
}

export async function issueRefreshToken(userId: string): Promise<string> {
  const token = randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000);
  await pool.query(`INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES ($1, $2, $3)`, [token, userId, expiresAt]);
  return token;
}

/** Returns the associated userId, or null if the token is unknown/expired — never throws for a bad token, callers 401 on null. */
export async function consumeRefreshToken(token: string): Promise<string | null> {
  const { rows } = await pool.query(`DELETE FROM refresh_tokens WHERE token=$1 AND expires_at>now() RETURNING user_id`, [token]);
  return rows[0]?.user_id ?? null;
}

export async function revokeRefreshToken(token: string): Promise<void> {
  await pool.query(`DELETE FROM refresh_tokens WHERE token = $1`, [token]);
}

export function generateOtpCode(): string {
  return randomInt(100000, 999999).toString();
}

export async function storeOtp(phone: string, code: string, purpose: string): Promise<void> {
  const expiresAt = new Date(Date.now() + OTP_TTL_MINUTES * 60 * 1000);
  await pool.query(`INSERT INTO otp_codes (phone, code, purpose, expires_at) VALUES ($1, $2, $3, $4)`, [phone, code, purpose, expiresAt]);
}

/** One-time use: marks the matching row consumed and returns true, or returns false without side effects if no valid row matches. */
export async function verifyOtp(phone: string, code: string, purpose: string): Promise<boolean> {
  const { rows } = await pool.query(
    `UPDATE otp_codes SET consumed_at=now() WHERE id=(SELECT id FROM otp_codes WHERE phone=$1 AND code=$2 AND purpose=$3 AND consumed_at IS NULL AND expires_at>now() ORDER BY created_at DESC LIMIT 1) AND consumed_at IS NULL RETURNING id`,
    [phone,code,purpose]);
  return rows.length === 1;
}
