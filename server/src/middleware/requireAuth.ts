import { RequestHandler } from "express";
import { verifyAccessToken } from "../services/auth";

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId?: string;
    }
  }
}

/**
 * Every route in this app acts on behalf of whoever holds a valid access
 * token — no route should trust a client-supplied userId for the acting
 * user (only for looking up a counterparty, e.g. a transfer recipient).
 * Rejects with 401 before the route handler runs on a missing, malformed,
 * or expired/invalid token.
 */
export const requireAuth: RequestHandler = (req, res, next) => {
  const header = req.header("authorization");
  if (!header?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing or malformed Authorization header" });
  }
  try {
    const payload = verifyAccessToken(header.slice("Bearer ".length));
    req.userId = payload.sub;
    next();
  } catch {
    res.status(401).json({ error: "Invalid or expired token" });
  }
};
