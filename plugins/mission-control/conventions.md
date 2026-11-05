# mission-control conventions

Shared by every skill. Each skill also restates, in one line, the parts it relies on, so it still works if this file isn't read.

## Cast

A space mission. Flavor in headings, never cute filler.

| Role | Who | Does |
|---|---|---|
| Flight Director | the human | briefs, makes the calls, gives go/no-go, owns the outcome |
| Captain | the root orchestrator (the main agent session, one per project) | plans the flight, assigns the crew, merges, runs final verify, briefs the Flight Director |
| Crew | worker agents | do one assignment each and self-verify. Roles: researcher, engineer, reviewer, comms (changelog). The Captain may name others. |

Phases: pre-flight (`explore`, `brief`, `blindspots`), flight (`execute`), landing (`verify`, `evidence`), go/no-go (`decisions`, `quiz`, `go-no-go`). `park` and `parked` work throughout.

## 1. Playback

Any skill that proposes something (an explore direction, a brief, a flight plan, a verify plan, a go/no-go briefing) shows it in plain words, marks inferences `(my guess)`, and ends with **"Tell me what's wrong."** (or "...or missing"). Never "looks good?", "ok?", "shall I proceed?". A reply like "fine" or "go" counts as approval. Approval is never assumed.

Why: a critique question makes the human judge, while an approval question invites a rubber stamp.

## 2. One question at a time

Ask one question at a time, most important first.

## 3. Stop on risky gaps

Stop and ask on security, data, money, deploy, user-facing behavior, public APIs, and anything hard to reverse. Never guess these. Smaller uncovered choices are either decided and recorded for `decisions`, or parked (crew).

## 4. Evidence over claims

Only report checks actually run in this session after the latest change, with verbatim output.

## 5. Depth matches stakes

Skip steps that the cost of being wrong doesn't justify, and say which ones were skipped.
