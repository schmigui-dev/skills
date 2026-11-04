CREATE TABLE proposals (
  id TEXT PRIMARY KEY,
  status TEXT NOT NULL CHECK (status IN ('draft', 'accepted')),
  guest_count INTEGER NOT NULL
);
