export interface Item {
  id: string;
  name: string;
  priceCents: number;
  qty: number;
}

export class Cart {
  items: Item[] = [];

  add(item: Item): void {
    const existing = this.items.find((i) => i.id === item.id);
    if (existing) existing.qty += item.qty;
    else this.items.push({ ...item });
  }

  remove(id: string): void {
    this.items = this.items.filter((i) => i.id !== id);
  }

  total(): number {
    return this.items.reduce((sum, i) => sum + i.priceCents * i.qty, 0);
  }
}
