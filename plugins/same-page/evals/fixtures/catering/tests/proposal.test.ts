import { describe, it, expect } from 'vitest';
import { Proposal } from '../src/proposals/proposal';

describe('Proposal', () => {
  it('accept works', () => {
    const p = new Proposal('p1', 'draft', 100);
    p.accept();
    expect(p.currentStatus).toBe('accepted');
  });
});
