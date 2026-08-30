import { Router } from "express";
import { pool } from "../db/pool";
import { createCustomer } from "../services/paystack";

export const usersRouter = Router();

usersRouter.post("/", async (req, res, next) => {
  try {
    const { username, displayName, email, phone } = req.body;
    if (!username || !displayName || !email) {
      return res.status(400).json({ error: "username, displayName, and email are required" });
    }

    const [firstName, ...rest] = displayName.split(" ");
    const paystackCustomer = await createCustomer({
      email,
      firstName,
      lastName: rest.join(" ") || firstName,
      phone,
    });

    const { rows } = await pool.query(
      `INSERT INTO users (username, display_name, email, phone, paystack_customer_code)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, username, display_name, email, phone, created_at`,
      [username, displayName, email, phone ?? null, paystackCustomer.customerCode]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    next(err);
  }
});

usersRouter.get("/:id", async (req, res, next) => {
  try {
    const { rows } = await pool.query(`SELECT id, username, display_name, email, phone, created_at FROM users WHERE id = $1`, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: "User not found" });
    res.json(rows[0]);
  } catch (err) {
    next(err);
  }
});
