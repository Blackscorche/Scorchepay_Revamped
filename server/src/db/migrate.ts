import fs from 'fs';
import path from 'path';
import { pool } from './pool';

async function migrate() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(`SELECT pg_advisory_xact_lock(hashtextextended('scorchepay-migrations', 0))`);
    await client.query(fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8'));
    await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations(name TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())`);
    const directory = path.join(__dirname, 'migrations');
    for (const name of fs.readdirSync(directory).filter(n => n.endsWith('.sql')).sort()) {
      const applied = await client.query('SELECT 1 FROM schema_migrations WHERE name=$1', [name]);
      if (applied.rowCount) continue;
      await client.query(fs.readFileSync(path.join(directory, name), 'utf-8'));
      await client.query('INSERT INTO schema_migrations(name) VALUES($1)', [name]);
    }
    await client.query('COMMIT');
    console.log('Versioned migrations applied.');
  } catch (error) { await client.query('ROLLBACK'); throw error; }
  finally { client.release(); await pool.end(); }
}
migrate().catch(() => { console.error('Migration failed; transaction rolled back.'); process.exitCode = 1; });
