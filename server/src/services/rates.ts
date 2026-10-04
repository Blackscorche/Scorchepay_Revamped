import axios from "axios";

/**
 * Free, keyless live rates — the server-side twin of the Flutter app's
 * `FxRateService`/`CoinGeckoService` (`lib/state/services/fx_rate_service.dart`,
 * `lib/data/coingecko_service.dart`). Used two ways here:
 *  1. As the dev-fallback conversion rate when Eversend/Quidax aren't
 *     configured yet (see eversend.ts/quidax.ts), so the funding
 *     waterfall is fully testable before either vendor account exists.
 *  2. As a sanity/estimate figure even once real vendors are wired, since
 *     both still quote their own rate at execution time.
 */

let fxCache: { rates: Record<string, number>; at: number } | null = null;
const FX_CACHE_MS = 60 * 60 * 1000;

/** Every rate as "1 unit of code in NGN". */
export async function getFxRatesToNgn(): Promise<Record<string, number>> {
  if (fxCache && Date.now() - fxCache.at < FX_CACHE_MS) return fxCache.rates;
  const { data } = await axios.get("https://open.er-api.com/v6/latest/NGN", { timeout: 8000 });
  if (data.result !== "success") throw new Error(`FX rate API result: ${data.result}`);
  const out: Record<string, number> = { NGN: 1 };
  for (const [code, perNgn] of Object.entries(data.rates as Record<string, number>)) {
    if (perNgn > 0) out[code] = 1 / perNgn;
  }
  fxCache = { rates: out, at: Date.now() };
  return out;
}

let cryptoCache: { prices: Record<string, number>; at: number } | null = null;
const CRYPTO_CACHE_MS = 30 * 1000;
const COINGECKO_IDS: Record<string, string> = {
  BTC: "bitcoin",
  ETH: "ethereum",
  USDT: "tether",
  SOL: "solana",
  BNB: "binancecoin",
};

/** USD price per unit of each supported crypto symbol. */
export async function getCryptoPricesUsd(): Promise<Record<string, number>> {
  if (cryptoCache && Date.now() - cryptoCache.at < CRYPTO_CACHE_MS) return cryptoCache.prices;
  const ids = Object.values(COINGECKO_IDS).join(",");
  const { data } = await axios.get(`https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=${ids}`, { timeout: 8000 });
  const out: Record<string, number> = {};
  for (const item of data as Array<{ symbol: string; current_price: number }>) {
    out[item.symbol.toUpperCase()] = item.current_price;
  }
  cryptoCache = { prices: out, at: Date.now() };
  return out;
}

export function isCryptoCurrency(code: string): boolean {
  return code.toUpperCase() in COINGECKO_IDS;
}

/** Converts [amount] of [from] into [to] using free live rates — fiat via NGN pivot, crypto via USD. */
export async function estimateConvert(amount: number, from: string, to: string): Promise<number> {
  if (from === to) return amount;
  const needsCrypto = isCryptoCurrency(from) || isCryptoCurrency(to);
  const fx = await getFxRatesToNgn();
  const crypto = needsCrypto ? await getCryptoPricesUsd() : {};

  const toNgn = (code: string, value: number): number => {
    if (isCryptoCurrency(code)) {
      const usdPrice = crypto[code.toUpperCase()];
      if (!usdPrice) throw new Error(`No price for ${code}`);
      const ngnPerUsd = fx["USD"];
      return value * usdPrice * ngnPerUsd;
    }
    const rate = fx[code.toUpperCase()];
    if (!rate) throw new Error(`No FX rate for ${code}`);
    return value * rate;
  };

  const fromNgn = (code: string, ngnValue: number): number => {
    if (isCryptoCurrency(code)) {
      const usdPrice = crypto[code.toUpperCase()];
      const ngnPerUsd = fx["USD"];
      return ngnValue / (usdPrice * ngnPerUsd);
    }
    const rate = fx[code.toUpperCase()];
    return ngnValue / rate;
  };

  const ngnValue = toNgn(from, amount);
  return fromNgn(to, ngnValue);
}
