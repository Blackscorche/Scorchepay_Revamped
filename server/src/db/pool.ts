import { Pool } from "pg";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is not set — copy .env.example to .env first.");
}

export const pool = new Pool({ connectionString: process.env.DATABASE_URL });

pool.on("error", (err) => {
  // A dropped idle connection shouldn't crash the whole server.
  console.error("Unexpected Postgres pool error", err);
});
