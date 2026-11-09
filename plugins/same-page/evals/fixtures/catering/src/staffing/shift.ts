export class ShiftProposal {
  constructor(readonly eventId: string, readonly waiters: number) {}
}

export function proposeShift(eventId: string, guestCount: number): ShiftProposal {
  return new ShiftProposal(eventId, Math.ceil(guestCount / 15));
}
