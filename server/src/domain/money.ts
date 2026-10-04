/** Exact boundary for enabled currencies. No IEEE-754 money arithmetic. */
export function parseNgn(value: unknown): { minor: bigint; decimal: string } {
  if (typeof value !== 'string' || !/^(0|[1-9]\d{0,11})(\.\d{1,2})?$/.test(value)) {
    throw new Error('Amount must be a decimal string with at most two decimal places');
  }
  const [whole, fraction = ''] = value.split('.');
  const minor = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0'));
  if (minor <= 0n) throw new Error('Amount must be greater than zero');
  return { minor, decimal: `${whole}.${fraction.padEnd(2, '0')}` };
}
export function username(value: unknown): string {
  if (typeof value !== 'string') throw new Error('Enter a valid username');
  const normalized = value.trim().replace(/^@/, '').toLowerCase();
  if (!/^[a-z0-9_.]{3,32}$/.test(normalized)) throw new Error('Username must contain 3–32 letters, numbers, dots or underscores');
  return normalized;
}
export function operationKey(value: unknown): string {
  if (typeof value !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) {
    throw new Error('A UUID v4 Idempotency-Key is required');
  }
  return value.toLowerCase();
}
