# ScorchePay server

Real backend for ScorchePay: Express + TypeScript + Postgres, with a real
Paystack integration (initialize/verify transactions, dedicated virtual
accounts, HMAC-verified webhooks). This is separate from the Flutter app
— the app currently runs entirely on local simulated state
(`lib/state/`); this server is the first real piece of backend
infrastructure, and is not yet wired into the app.

## What's real vs. what you still need to do

**Already built and running:**
- Real Postgres schema (`users`, `balances`, `ledger_entries`,
  `payment_transactions`, `virtual_accounts`) — see `src/db/schema.sql`.
- A real, atomic ledger service (`src/services/ledger.ts`) — every
  credit/debit runs inside a Postgres transaction with a row lock, so
  there's no window where a balance and its ledger entry disagree.
- Real Paystack API calls (`src/services/paystack.ts`): initialize a
  transaction, verify one server-side, create a customer, create a
  dedicated virtual account.
- **Real webhook signature verification** — `POST /api/webhooks/paystack`
  is mounted with `express.raw()` specifically so the HMAC-SHA512 check
  runs against the exact bytes Paystack signed, not a re-serialized copy.
  A request with a missing or wrong signature is rejected with 401
  before any database write happens.
- Idempotent crediting — both the webhook and the client-facing
  `/verify` endpoint check `payment_transactions.status` before
  crediting, so a retried webhook or a double client call can't credit
  a wallet twice for the same Paystack reference.

**You still need to:**
1. Get a **free Paystack test secret key** (no business verification
   required for test mode): https://dashboard.paystack.com/#/settings/developer
   → paste it into `.env` as `PAYSTACK_SECRET_KEY`.
2. Decide on real hosting once you're ready to go beyond local testing
   (Railway or Render are the simplest for a Node + Postgres app) —
   Paystack's webhooks need a public HTTPS URL to call, which your
   laptop isn't unless you tunnel it (see below).
3. Wire the Flutter app to call this server instead of (or alongside)
   its local state — not done yet, since the app's entire state layer
   currently assumes no backend exists.

## Local setup

This machine already has a Postgres 16 server running via Homebrew — but
**on port 5433**, not the default 5432 (there's a separate,
password-protected PostgreSQL 17 install occupying 5432). The `.env`
below is already pointed at the right one.

```bash
cd server
npm install
cp .env.example .env   # already done — just edit in your real Paystack key
npm run migrate        # creates the schema (already run once)
npm run dev            # starts the server on http://localhost:4000
```

Check it's alive:

```bash
curl http://localhost:4000/health
# {"ok":true,"db":"connected"}
```

## Testing the Paystack flow once you have a real test key

1. `POST /api/users` with `{ username, displayName, email }` → creates a
   user + a real Paystack customer.
2. `POST /api/payments/initialize` with `{ userId, email, amountNaira }`
   → returns a real `authorizationUrl` you can open in a browser and pay
   with Paystack's test card (`4084084084084081`, any future expiry, CVV
   `408`, PIN `0000`, OTP `123456`).
3. `GET /api/payments/verify/:reference` → verifies with Paystack and
   credits the wallet — check it landed with `GET /api/wallet/:userId/balance`.

To receive real webhooks while testing locally, tunnel this server with
[ngrok](https://ngrok.com) (`ngrok http 4000`) and paste the resulting
`https://....ngrok-free.app/api/webhooks/paystack` URL into Paystack's
dashboard under Settings → API Keys & Webhooks.

## Why two "for later" pieces are stubbed rather than fully wired

- **Dedicated virtual accounts** (`POST /api/payments/virtual-account`)
  work in Paystack test mode with `preferred_bank: 'test-bank'` only —
  real bank-backed NUBANs (Wema, Titan) require your business to be
  KYB-verified on a **live** Paystack account. The code is real and
  correct; it just can't be fully exercised until you have that
  business account.
- **Cross-border/multi-currency** (Flutterwave, per the earlier
  recommendation) isn't integrated yet — Paystack came first since it
  covers the NGN-primary rails (card, bank transfer, virtual accounts)
  that most of the app's flows need.
