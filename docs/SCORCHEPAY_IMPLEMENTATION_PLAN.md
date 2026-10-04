# ScorchePay implementation plan

Prepared 30 September 2026 from the current root Flutter project, `server/src`, and the supplied Claude conversation. This is a code-based product/architecture review, not a claim that the current integrations are production-verified. The nested `scorchepay_flutter/` copy is not the implementation target.

## 1. Recommended product direction

Keep ScorchePay as one money app: hold supported fiat and crypto, receive money, convert deliberately or fund a payment through Smart Pay, exchange gift cards, and trade peer-to-peer. Keep the current modern UI rather than redesigning it: neutral surfaces, restrained ember/user-selected accent, rounded cards, compact typography, generous section spacing, and fully adaptive light/dark hero cards.

Build three connected experiences:

- Customer app: wallets, payments, gift cards, P2P, savings and account management.
- Merchant workspace: gift card buying operations, P2P advertisements, liquidity, settlement and team controls. General payment-acceptance merchants remain a separate capability from exchange merchants.
- Admin workspace: identity/business review, disputes, risk, treasury, reconciliation, support, configuration and audit.

Start with NGN payment rails and a small explicitly supported asset/corridor catalog. Add other currencies only when collection, custody, conversion and payout are genuinely supported for the user's region and account. A displayed USD equivalent is not a USD bank account. Smart Pay may spend another asset only after the customer accepts an executable quote, fees and funding order.

## 2. What Claude started: retain and repair

| Area | Evidence in current code | Decision |
| --- | --- | --- |
| Design | `lib/theme`, shared cards/buttons, appearance settings, revised logos | Retain; extend shared components to dashboards. |
| Auth | JWT/OTP/refresh routes and secure-storage API client exist | Finish actual signup/login/PIN screen wiring before claiming a connected app. |
| Internal transfers | PostgreSQL transfer transaction exists | Useful foundation; add idempotency, strict validation, deterministic locking and authoritative balance refresh. This is not a P2P marketplace. |
| Smart Pay | `server/src/services/smartPay.ts` swallows conversion failures; executes legs individually | Replace with reservations and durable orchestration; never treat a failed conversion as funding. |
| Crypto precision | `balances` and `ledger_entries` use `NUMERIC(18,2)`; services convert to JS `Number` | Migrate before crypto settlement: asset-specific atomic units or exact decimal quantities, string API amounts, explicit rounding. |
| Provider integration | Eversend/Quidax adapters contain unverified contracts and estimator fallbacks; Smart Pay supplies no Quidax subaccount | Treat as scaffolding. Provision accounts and test quotes/execution/status against documented contracts. |
| Bills | Current bills route still imports VTpass | Replace with SMEPlug as requested, beginning with documented airtime/data capabilities. |
| Client money source | API client and notifier allow unreachable calls to fall back to simulation | Separate demo/live repositories explicitly. A timeout can happen after a real transfer succeeded; never simulate or blindly repeat it. |
| Processing | Shared ProcessingScreen lacks general catch/timeout recovery and assumes nonempty steps | Use structured success/failed/pending outcomes, attach error handling immediately, handle empty steps and restore a transaction by ID after restart. |
| Gift cards | Buy/redeem show success modals; exchange uses a simulated provider and fixed FX/payout assumptions | Implement real catalog, quotes, merchant review, evidence, disputes and settlement. Generic issuer redemption cannot be presumed. |
| P2P | Static buyers, fixed NGN conversion, default 0.01 amount, UI-only release | Replace with executable advertisements, validated order size, escrow and a persistent order lifecycle. External bank payment must not also credit a wallet. |
| Background work | MainShell runs savings/automation/escrow checks on a timer | Move financial scheduling and deadlines to server workers. |

The existing bill failure branch can also attempt compensation again if a later operation throws. Exactly-once refunds need durable identifiers and atomic state transitions. Local refund credits do not reverse completed external conversions.

The pasted transcript contains a provider credential. Rotate that exposed credential before live use; do not reproduce it in docs, code, logs or frontend configuration. No provider secret was used during this review.

## 3. Frontend information architecture

Preserve Home / Wallet / QR action / Crypto / More. Home should surface Send, Receive, Smart Pay and Exchange, with pending activity directly below the balance. Crypto should link to Buy, Sell, Swap, Receive, Withdraw and P2P. More gets a searchable Exchange section with Gift Exchange and P2P Market.

Gift exchange: catalog → card region/type/value → quote with fees/expiry → private evidence → submit → order timeline → merchant decision → accept revised quote if needed → wallet payout → receipt/dispute.

P2P: Buy/Sell tabs → asset/fiat/payment/amount filters → merchant offer → order confirmation → escrow reservation → payment instructions → mark paid → receipt confirmation/release → receipt/review. My Orders persists open and past orders, chat, deadlines and disputes.

Merchant: overview → gift card queue → secure review → rates/capacity → P2P ads/orders → liquidity → settlements → disputes → team/settings. Desktop uses a sidebar and data tables; mobile uses cards, tabs and detail pages. Scope all data to the business.

Admin: overview → review queue → customers/KYC → merchants/KYB → gift cards → P2P/disputes → payments → treasury/reconciliation → provider health → audit/configuration. Use a protected staff application/session with MFA; never grant permissions through a customer role picker.

### Frontend work included with this plan

`lib/features/exchange/exchange_workspace_screen.dart` adds four reviewable workspaces with theme-aware cards, wrapping tabs, search, narrow/wide layouts and detail navigation. Reach them from More:

- Exchange → Gift Exchange: Sell cards, Buy cards, My orders.
- Exchange → P2P Market: Buy crypto, Sell crypto, My orders.
- Workspace Previews → Merchant Desk: Orders, Rates, Settlements.
- Workspace Previews → Admin Desk: Review queue, Merchants, Reconciliation.

Merchant/admin preview entries appear only in debug builds. All new screens explicitly label sample data and do not execute payments, approvals or settlement. These previews are the first frontend slice, not completed operational dashboards. Existing older simulated screens remain to be replaced during the relevant phases. Production authorization must be enforced server-side irrespective of menu visibility.

## 4. Feature-by-feature delivery scope

Each row includes customer/frontend work, server work and a concrete completion condition. All writes share validated inputs, authenticated ownership, request idempotency, audit references and structured errors.

| Feature | Frontend implementation | Server/data implementation | Done when |
| --- | --- | --- | --- |
| Onboarding/auth | Resume signup; contact verification; PIN setup; login; recovery; session expiry | Signup challenge/session, OTP limits and expiry, hashed secrets, refresh rotation/reuse detection, device sessions | Real screens create/login a verified account; expired/replayed challenges fail; logout revokes session. |
| Profile/KYC | Profile edit, ID/selfie upload, tier status, retry/requested-info screens | Identity provider adapter, protected media, verification cases, tier limits | Provider updates change eligibility; rejected/pending states cannot bypass limits. |
| Security | PIN change/recovery, biometric device unlock, MFA, trusted devices | Step-up transaction challenges, throttling, risk checks, session revocation | Device biometrics do not replace server authorization; unauthorized actions are rejected. |
| Home | Real balance summary, hidden balance, pending actions, recent activity | Read projections, totals with valuation timestamps, feature eligibility | Totals reconcile to holdings and stale valuations are identified. |
| Wallets/receive | Available/reserved balances, account details, deposit instructions, network/memo warnings | Accounts, asset metadata, provider account mapping, collection events, confirmations | A verified collection credits once, including duplicate/out-of-order events. |
| Internal send | Recipient resolve, amount, fee, PIN, pending/result and receipt | Atomic double-entry transfer, amount/asset limits, beneficiary ownership | Concurrent sends cannot overspend; same request returns same operation. |
| Bank send | Bank lookup, name confirmation, beneficiary save, payout status | Beneficiaries, payout quote/create/status, provider callbacks | Timeouts remain pending until reconciled; no premature refund. |
| QR/request/split | Scan/display signed request, amount/expiry, split participants, per-person status | Payment requests, payer allocations, expiry, settlement events | QR cannot authorize spending; duplicate payments and overpayment follow explicit policy. |
| Multi-currency/FX | Add eligible currency; convert preview, fee/rate/expiry; receipts | Provider-backed balances, quote and execution, supported corridors, exact math | No fabricated account/currency; execution matches accepted quote or requests a new one. |
| Smart Pay | Choose source/priority, inspect funding breakdown, confirm quote, pending tracker | Reserve funds, quote each leg, execute conversions, await liquidity, pay destination, reconcile | Failed conversion cannot fund payment; restart resumes; no double debit/refund. |
| Airtime/data | Network/phone/plans, recipient validation, amount, result and history | SMEPlug catalog, airtime/data adapter, operation status, provider balance monitoring | Contract tests and controlled fulfillment prove success, failure and unknown outcomes. |
| Other bills | Electricity meter/name; cable packages; internet; education; eligible betting | Product capability registry and approved provider adapters | Only documented supported services are enabled; tokens/references survive restart. |
| Crypto spot | Markets, buy/sell/swap quotes, order history, deposits/withdrawals | Custody/subaccounts, exchange quote/execute/status, network/address checks and fees | Amount precision preserved; confirmations/rejections visible; custody reconciles. |
| Price alerts | Asset, threshold, direction, delivery preferences | Server quote ingestion, deduplicated threshold jobs | Alert fires while app is closed and does not repeatedly notify unchanged crossings. |
| Gift card sell | Region/type/value quote, private uploads, timeline, counteroffer, payout, appeal | Catalog/rate rules, funded offers, assignment lease, encrypted secrets, settlement/dispute | Exactly one merchant wins assignment; revised price needs consent; payout posts once. |
| Gift card buy/redeem | Inventory, regional restrictions, delivery vault, order history | Supplier fulfillment or platform-issued voucher validation, secure code delivery | Never promise arbitrary third-party redemption; fulfilled code and debit reconcile. |
| P2P customer | Buy/Sell discovery, verified offer details, payment steps, chat/evidence, timer, appeal | Ads, inventory reservation, escrow order state machine, deadlines, notifications | No unreserved trade; paid orders cannot auto-expire into refunds; release is one-time. |
| Exchange merchant | Onboarding/KYB, order queue, secure card review, rate bands, inventory, settlement, reports/team | Business membership/permissions, capacity, reserve wallet, rate versions, decisions/audit | Merchant cannot access another merchant's cards/orders or settle beyond funded capacity. |
| Exchange admin | Cases, merchant approval/suspension, rate oversight, reconciliation, audited adjustments | Staff RBAC/MFA, dual approval, cases/evidence, compensating journals, audit log | Every sensitive action has actor/reason; no direct balance editing or self-approved adjustment. |
| General merchant payments | QR POS, payment links, storefront, invoice items, customer status, sales | Businesses, invoices, checkout requests, settlements, merchant notifications | Paid badge follows authoritative settlement; expired/partial invoices handled. |
| Escrow services | Create/fund, milestones, delivery evidence, review, release/refund, dispute | Reserved funds, milestone state machine, worker deadlines and cases | Funds cannot be both released and refunded; disputes freeze automatic release. |
| Savings | Goal, target/date, contribution, recurring funding, pause/withdraw | Goal accounts, schedules, explicit lock/withdrawal rules | Available money excludes reserved savings; no invented yield; jobs execute once. |
| Group features | Invite/roles, contributions, group goals, splits, approvals/history | Membership, contribution ledger, withdrawal approval policies | Members see permitted data; owner cannot bypass agreed withdrawal rules. |
| Automation | Rule builder, spend cap, funding source, schedule/timezone, pause/history | Durable jobs, authorization scope, limits, retries and missed-run policy | Executes with app closed, never beyond mandate, handles insufficient balance. |
| Transactions | Unified activity, filters, status, details, receipts and statements | Paginated activity projection, immutable operation IDs, export jobs | Every monetary action has a traceable journal/provider reference. |
| Insights/analytics | Spending categories, budgets, cash flow and merchant reports | Ledger-derived aggregates with currency/date basis and FX timestamp | Summaries reconcile; different currencies are not simply added together. |
| AI assistant | Explain transactions/budgets, draft requests, explicit confirmation | Permission-scoped tools, redacted context, read-first actions | Assistant cannot move money or reveal card secrets without appropriate authorization. |
| Rewards/referrals | Eligibility, progress, pending/earned/reversed credits | Campaign rules, budget, qualified-event rewards, abuse controls | Rewards are funded and idempotent; reversal policy is visible. |
| Notifications/support | Inbox, push settings, case threads, unread status | Outbox, delivery preferences, push/email/SMS adapters, support cases | Financial outcome survives notification failure; sensitive data absent from push. |
| Appearance/accessibility | Light/dark/system/accent, responsive layout, text scaling, focus/semantics | Persist preferences; optional account sync | Readable cards/statuses with all accents, keyboard navigation and large text. |
| Business/developer platform | API-key management, scopes, webhook configuration, event logs, docs | Scoped hashed keys, quotas, signed outgoing events, sandbox and replay protection | Merchant keys cannot act as admin or query other businesses. |

## 5. Money architecture and API contracts

Keep Flutter/Riverpod and the existing TypeScript/Express/PostgreSQL stack. Begin as a modular monolith with separately deployed API and durable workers, not many microservices. Use PostgreSQL-backed jobs initially, or a managed Redis queue when operations justify it. Store private evidence in encrypted object storage with short-lived signed access.

Core schema additions:

- Assets/currencies with scale, network and capabilities; accounts; balanced journals/postings; balance projections and holds.
- Operations, idempotency keys with request hashes, quotes, funding legs, provider attempts, webhook inbox, outbox and reconciliation runs.
- Businesses, memberships, roles, verification cases, staff permissions and append-only audit events.
- Gift card catalog, region/format/rate versions, offers/orders, merchant assignment, encrypted card secrets, evidence and settlement references.
- P2P ads, inventory reservations, payment methods, orders, escrow holds, messages, evidence, disputes and deadlines.
- Savings goals, group memberships, schedules, invoices, payment requests, alerts and rewards.

Postings balance per asset. FX uses separate asset journals and treasury/clearing accounts rather than adding USD and NGN values. Available = posted balance minus active holds. Represent amounts as decimal strings in API payloads and exact atomic units/decimals in storage and arithmetic. A provider timeout is UNKNOWN/PENDING, not proof of failure. Retry with the same operation key or query status; compensate only a confirmed failed outcome. Multi-provider work is a durable saga, not a database transaction stretched across external API requests.

Proposed API groups (design targets, not all existing endpoints):

| Group | Main contracts |
| --- | --- |
| Auth/account | `/api/auth/*`, `/api/me`, `/api/sessions`, `/api/verification` |
| Wallet/payments | `/api/wallets`, `/api/beneficiaries`, `/api/transfers`, `/api/operations/:id`, `/api/transactions` |
| Quotes/Smart Pay | `POST /api/quotes`, `POST /api/smart-pay/quotes`, `POST /api/smart-pay/payments` |
| Bills | `GET /api/bills/catalog`, `POST /api/bills/validate`, `POST /api/bills/payments` |
| Gift cards | `/api/gift-cards/catalog`, `/quotes`, `/orders`, `/orders/:id/evidence`, `/orders/:id/accept-offer` |
| P2P | `/api/p2p/ads`, `/orders`, `/orders/:id/mark-paid`, `/release`, `/cancel`, `/disputes`, `/messages` |
| Merchant | `/api/merchant/orders`, `/rates`, `/ads`, `/settlements`, `/members`, `/reports` |
| Admin | `/api/admin/cases`, `/merchants`, `/reconciliation`, `/adjustments`, `/audit`, `/provider-health` |
| Remaining products | `/api/savings`, `/groups`, `/automations`, `/invoices`, `/payment-requests`, `/notifications`, `/alerts`, `/rewards` |

Every money mutation accepts an idempotency key bound to principal and payload. Return operation ID, exact amounts, currency and status; pending requests can return 202. Reject reuse with changed payload. Polling/subscriptions read that operation after navigation or reconnect. Cursor pagination and stable error codes apply throughout. Validate permissions and legal state transitions on the server, not from supplied client status.

## 6. Gift card and P2P operating rules

Gift cards: draft → quoted → submitted → assigned → reviewing → approved → settling → settled. Branches: evidence required, revised offer awaiting customer consent, rejected, disputed and cancelled where permitted. Lock merchant capacity/funds before exposing the card. Encrypt codes separately, mask by default, audit reveals, restrict assignment, and prevent concurrent claims. Refund unused reservations exactly once. A rejection must include reason/evidence; a changed quote cannot silently reduce payout. Uploads require file-size/type limits, malware scanning, restricted storage and retention rules. Never claim issuer verification unless the actual integration provides it.

P2P: created/reserved → awaiting payment → marked paid → payment review → released/completed. Branches: unpaid expiry, cancellation before payment, disputed, refunded after a supported resolution. Do not auto-cancel a marked-paid trade. Persist server time/deadline; UI countdown is informational. Freeze ad quantity and seller crypto atomically; forbid self-trading and enforce limits. Release requires authorized seller step-up or separately approved dispute resolution. Screenshots are evidence, not payment confirmation.

Distinguish external bank settlement from internal wallet settlement in both copy and journals. If the buyer sends NGN directly to the seller's bank, release crypto only; do not also credit seller NGN in ScorchePay. Customer gift-card payout, by contrast, transfers reserved merchant funds into the customer's selected supported wallet.

## 7. Providers and integration verification

Provider recommendations below preserve the supplied direction. Product availability, contracts, supported countries/assets, fees and account access must be verified before enabling each capability.

| Need | Proposed integration | Remaining work / constraint |
| --- | --- | --- |
| NGN collection/payout | Keep Paystack | Verify signed callbacks, server-side references/amount/currency, account provisioning, payout events and duplicate delivery. [Official webhooks](https://paystack.com/docs/payments/webhooks/). |
| Airtime/data | SMEPlug replaces VTpass | Website advertises airtime/data APIs. Use its linked [official Postman docs](https://documenter.getpostman.com/view/2351511/SzS5umB5?version=latest); contents were not extractable in this review. Confirm auth, networks/plans, vend/status payloads, references, retries and webhook signing in the dashboard/support docs. Do not invent a callback signature or assume all utility bill products exist. [SMEPlug](https://smeplug.com/). |
| Fiat FX/corridors | Eversend candidate already scaffolded | Verify account eligibility, authentication, executable quote/convert lifecycle, funding and settlement currencies. Current implementation is not proof of correctness. [API overview](https://eversend.readme.io/reference/api-overview), [FX product](https://eversend.co/infra/fx). |
| Crypto custody/conversion | Quidax candidate already scaffolded | Verify subaccounts, custody, deposit/withdrawal events and supported markets; implement quote and execute lifecycle. [Instant swap reference](https://docs.quidax.io/reference/create-swap). |
| OTP | Existing Termii adapter | Verify sandbox/production delivery, sender setup, pricing and rate limits; remove production OTP logging. |
| Identity/business checks | Provider selection pending | Evaluate coverage for launch users and merchant businesses; specify consent, status callbacks, retry/manual review before selecting vendor. |
| Gift card purchase inventory | Supplier selection pending | Distribution API must explicitly support chosen brands/regions. This does not automatically provide third-party card buyback verification. |
| Gift card exchange | ScorchePay merchant network | Implement merchant-backed review and funded settlement; optional issuer validation only where contractual access exists. |
| Push/email/media | Push provider, email delivery, encrypted object storage | Configure delivery adapters and private upload/retrieval before evidence-dependent features go live. |
| Market prices | Existing CoinGecko/FX read sources | Display/estimation only; executable provider quotes determine money movement. |

SMEPlug migration: add a provider interface; implement catalog/validation/purchase/status; rename VTpass-specific schema fields through a versioned migration while preserving historical records; replace route imports; add signature verification only from verified documentation; use authenticated status polling if callbacks are unavailable. Record the actual Railway HTTPS callback path only after the matching route and security contract exist. No live vend should be used merely to discover request fields.

## 8. Delivery sequence and release gates

These are dependency-based increments, not fixed dates; estimates require validated provider access and team capacity.

1. **Foundation and safety:** wire auth, separate demo/live environments, exact money schema, idempotent operations, journal/holds, processing recovery, typed errors and production API configuration. Gate: duplicate/concurrent/timeout tests pass; no local fallback can report live success.
2. **NGN wallet and SMEPlug:** verified deposits/payouts, internal transfers, airtime/data, receipts and worker reconciliation. Gate: end-to-end controlled provider verification, duplicate webhook test, unknown outcome recovery and matching statements.
3. **Gift card vertical slice:** customer catalog/quotes/evidence/orders + merchant onboarding/queue/rates/reserve/settlement + admin merchant review/disputes/audit. Gate: complete funded customer→merchant→admin exception journey, including counteroffer rejection, assignment race and repeat settlement.
4. **Crypto custody and P2P:** provider accounts and exact crypto balances; buy/sell offers, reserved inventory, payment messaging, escrow/release, merchant ads, admin appeals. Gate: release/refund race, paid-order expiry, cross-tenant access and external-bank/no-double-credit tests.
5. **Fiat FX and Smart Pay:** supported currencies, executable funding quotes, reserved multi-leg conversions and final payment. Gate: stale quotes, partial conversion, worker restart, liquidity shortfall and provider timeout reconciliation.
6. **Savings, service escrow, groups, recurring payments:** migrate app timers to durable workers; introduce mandates and approval policies. Gate: app-closed execution, duplicate-job handling and dispute holds.
7. **Merchant checkout/business tools:** invoices, QR, links, settlements, reports and teams. Gate: invoice/payout reconciliation and business permissions.
8. **Insights, alerts, rewards, AI and developer platform:** trusted ledger projections, budgeted reward rules, scoped API keys and signed outgoing events. Gate: reconciliation of summaries, action authorization and abuse tests.
9. **Production rollout:** staged cohorts, product/currency flags, treasury liquidity checks, monitoring, tested backup restore and operational incident runbooks. Expand only after settlement and support operations work reliably.

Do not call the whole backend complete after a local curl test or after a missing-credentials failure. Each release requires actual contract verification plus frontend integration and recovery tests.

## 9. Verification and Railway deployment

Automated checks: Flutter analyzer and focused widget tests; TypeScript compile; API integration tests on disposable PostgreSQL; ledger invariant/property tests; provider fixtures; idempotency, authorization, concurrency and fault-injection tests. Use no production database seeding or live purchase as a default test.

UX verification: phone 360–430px and desktop 1024px+; light/dark/system and accent choices; large text, keyboard/focus and accessibility labels; loading/empty/offline/error/pending/completed states; restart an unfinished operation and open its notification deep link. Financial screens must show real fees and pending status without fabricated success.

Railway: separate staging/live projects and credentials; managed PostgreSQL; API plus worker services; environment-driven HTTPS base URL; readiness and liveness endpoints; reviewed versioned migration job; database backup/restore drill; strict CORS for web; secret redaction; provider timeouts; dead-letter queue; metrics for pending age, settlement drift and provider balances. Webhooks authenticate, deduplicate and durably enqueue before acknowledging; workers handle retries. Deployment rollback must preserve in-flight operations and compatible schema changes.

Launch decisions still needed, but do not block frontend planning: supported initial countries/assets; approved provider accounts; gift card merchant model and funding terms; fees and limits; dispute SLA; gift-card supplier; identity provider; staff roles. Confirm applicable product and operating permissions with the relevant partners before activating live financial services; this document makes no licensing determination.
