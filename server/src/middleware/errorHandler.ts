import { ErrorRequestHandler } from "express";
import { InsufficientFundsError } from "../services/ledger";

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof InsufficientFundsError) {
    return res.status(422).json({ error: err.message });
  }
  console.error("Request failed", { name: err instanceof Error ? err.name : "UnknownError" });
  res.status(500).json({ error: "Internal server error" });
};
