import { debit, credit, getBalances, InsufficientFundsError } from "./ledger";
import { estimateConvert, isCryptoCurrency } from "./rates";
import { convert as eversendConvert } from "./eversend";
import { sellAtMarket as quidaxSell } from "./quidax";

/**
 * Server-side port of the Flutter app's `SmartPayEngine`
 * (`lib/state/services/smart_pay_engine.dart`) — same funding-priority
 * walk (native currency → stablecoins → other fiat → volatile crypto),
 * same all-or-nothing multi-leg debit with rollback on failure. The one
 * real difference: converting between legs now calls real vendors
 * (Eversend for fiat↔fiat, Quidax for crypto→fiat) instead of an
 * in-memory rate table — see the plan's "Core architecture" note for why
 * this, not the ledger schema, is what makes multi-currency/crypto real.
 *
 * Planning (`planPayment`) uses the free live-rate estimate for both
 * directions — cheap, and only used to decide *how much* of each source
 * currency to take. The real vendor conversion only gets executed once
 * per committed leg, in `debitLegs`, where a real quote finally matters.
 */

const STABLECOINS = new Set(["USDT"]);

export interface FundingLeg {
  currency: string;
  sourceAmount: number;
  nativeEquivalent: number;
}

export interface FundingPlan {
  nativeCurrency: string;
  nativeAmount: number;
  legs: FundingLeg[];
  shortBy: number;
}

export function isPlanSufficient(plan: FundingPlan): boolean {
  return plan.shortBy <= 1e-6;
}

export async function planPayment(params: {
  userId: string;
  nativeCurrency: string;
  nativeAmount: number;
  fixedSourceCurrency?: string;
}): Promise<FundingPlan> {
  const balances = Object.fromEntries(Object.entries(await getBalances(params.userId)).map(([code, amount]) => [code, Number(amount)]));

  if (params.fixedSourceCurrency) {
    const have = balances[params.fixedSourceCurrency] ?? 0;
    const haveNative = have > 0 ? await estimateConvert(have, params.fixedSourceCurrency, params.nativeCurrency) : 0;
    const take = Math.min(haveNative, params.nativeAmount);
    const takeSource = take > 0 ? await estimateConvert(take, params.nativeCurrency, params.fixedSourceCurrency) : 0;
    return {
      nativeCurrency: params.nativeCurrency,
      nativeAmount: params.nativeAmount,
      legs: take > 0 ? [{ currency: params.fixedSourceCurrency, sourceAmount: takeSource, nativeEquivalent: take }] : [],
      shortBy: params.nativeAmount - take,
    };
  }

  const held = Object.keys(balances);
  const candidates: string[] = [];
  if (held.includes(params.nativeCurrency)) candidates.push(params.nativeCurrency);
  for (const c of held) if (STABLECOINS.has(c)) candidates.push(c);
  for (const c of held) if (c !== params.nativeCurrency && !STABLECOINS.has(c) && !isCryptoCurrency(c)) candidates.push(c);
  for (const c of held) if (isCryptoCurrency(c) && !STABLECOINS.has(c)) candidates.push(c);

  let remaining = params.nativeAmount;
  const legs: FundingLeg[] = [];
  for (const currency of candidates) {
    if (remaining <= 1e-9) break;
    const available = balances[currency] ?? 0;
    if (available <= 1e-9) continue;
    const availableNative = await estimateConvert(available, currency, params.nativeCurrency);
    const takeNative = availableNative >= remaining ? remaining : availableNative;
    const takeSource = await estimateConvert(takeNative, params.nativeCurrency, currency);
    legs.push({ currency, sourceAmount: takeSource, nativeEquivalent: takeNative });
    remaining -= takeNative;
  }
  return { nativeCurrency: params.nativeCurrency, nativeAmount: params.nativeAmount, legs, shortBy: remaining };
}

/**
 * Debits every leg of [plan] — if any leg fails, refunds every leg
 * already applied and rethrows (all-or-nothing, matching
 * `SmartPayEngine._debitLegs`'s atomicity guarantee). The real
 * cross-currency conversion is executed per leg (best-effort — a vendor
 * hiccup here doesn't undo the user's ledger debit, since the estimate
 * already determined a fair source amount; it's logged for reconciliation).
 */
export async function debitLegs(userId: string, plan: FundingPlan, title: string): Promise<void> {
  const applied: FundingLeg[] = [];
  try {
    for (const leg of plan.legs) {
      await debit({
        userId,
        currency: leg.currency,
        amount: leg.sourceAmount,
        title,
        subtitle: leg.currency !== plan.nativeCurrency ? `Smart Pay funding leg · converted to ${plan.nativeCurrency}` : "Smart Pay funding leg",
        category: "smart_pay",
        meta: { nativeEquivalent: leg.nativeEquivalent, nativeCurrency: plan.nativeCurrency },
      });
      applied.push(leg);

      if (leg.currency !== plan.nativeCurrency) {
        try {
          if (isCryptoCurrency(leg.currency)) {
            await quidaxSell({ cryptoCurrency: leg.currency, fiatCurrency: plan.nativeCurrency, amount: leg.sourceAmount });
          } else {
            await eversendConvert({ from: leg.currency, to: plan.nativeCurrency, amount: leg.sourceAmount });
          }
        } catch (err) {
          console.warn(`Real conversion failed for ${leg.currency}->${plan.nativeCurrency} (ledger already debited at the estimated rate):`, (err as Error).message);
        }
      }
    }
  } catch (err) {
    await refundLegs(userId, applied, title);
    throw err;
  }
}

/**
 * Credits every leg back to the user's local balance in its own source
 * currency — used both by `debitLegs`'s own rollback (a mid-loop debit
 * failure) and by callers whose *provider* call fails after all legs
 * already succeeded (e.g. VTpass rejects the airtime purchase after
 * funds were moved — see `routes/bills.ts`). Deliberately does not try
 * to unwind the real Eversend/Quidax conversion already executed for
 * each leg; that's the platform's own treasury position to manage, not
 * something to re-expose to the user (same rollback philosophy as
 * `SmartPayEngine._debitLegs`/`LedgerService.refund` on the Flutter side).
 */
export async function refundLegs(userId: string, legs: FundingLeg[], title: string): Promise<void> {
  for (const leg of legs) {
    await credit({
      userId,
      currency: leg.currency,
      amount: leg.sourceAmount,
      title: `Refund — ${title}`,
      subtitle: "Funding leg rolled back",
      category: "refund",
    });
  }
}

export { InsufficientFundsError };
