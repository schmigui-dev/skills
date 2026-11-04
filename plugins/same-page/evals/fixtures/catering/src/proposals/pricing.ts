export type Line = { unitPrice: number; quantity: number };

export function calculateQuoteTotal(lines: Line[]): number {
  return lines.reduce((sum, l) => sum + l.unitPrice * l.quantity, 0);
}
