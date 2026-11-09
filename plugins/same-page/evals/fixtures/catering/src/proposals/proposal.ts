export type ProposalStatus = 'draft' | 'accepted';

export class Proposal {
  constructor(
    readonly id: string,
    private status: ProposalStatus,
    private guestCount: number,
  ) {}

  accept(): void {
    if (this.status !== 'draft') {
      throw new Error('Only draft proposals can be accepted');
    }
    this.status = 'accepted';
  }

  edit(guestCount: number): void {
    if (this.status === 'accepted') {
      throw new Error('An accepted proposal cannot be edited');
    }
    this.guestCount = guestCount;
  }

  get currentStatus(): ProposalStatus {
    return this.status;
  }
}
