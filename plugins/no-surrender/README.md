# no-surrender

Hand off the work, not the accountability.

As agents get better, their output looks finished and is usually right, and that's exactly what makes it easy to stop thinking. You read the last answer carefully, skim the next, and approve the one after that. Then someone asks about a line and you can't explain it. That's *cognitive surrender*: the agent's output quietly becomes yours without anyone checking it.

These five commands keep you in charge: say what you care about before the work starts, surface what you haven't thought of, and make sure you understand what you ship.

## Install

```text
/plugin marketplace add schmigui-dev/skills
/plugin install no-surrender@schmigui
```

Commands are namespaced as `/no-surrender:<command>`.

## Commands

| When | Command | Does |
| --- | --- | --- |
| Before | `/brief "task"` | Builds a short brief with you: what you care about, your hypothesis, scope, and what "done" and "verified" mean. While it works, the agent asks instead of guessing on anything risky the brief doesn't cover. |
| Before | `/blindspots [task]` | Sweeps security, data, deploy, failure modes, cost, users, integrations, and more for gaps specific to your project. Returns them as questions for you, plus the strongest counterargument. |
| After | `/evidence` | Shows the exact checks run and their real output first, then what each check proved and **didn't** prove, a verdict, and only then a one-line summary. |
| After | `/decisions` | Lists every choice you never made: invented values, defaults, interpretations, scope cuts, assumptions. Anything that needs your call comes first. |
| After | `/quiz [n=5] [hard]` | Writes a short report on the change, then quizzes you one question at a time and grades strictly. Ship only on a perfect score. |

All commands run only when you type them. Claude never invokes them on its own.

## Stop guard

Commands only help if you remember to run them, and you stop remembering at exactly the moment you've started to drift. So the plugin also installs a `Stop` hook that makes the two most important checks automatic.

When Claude changed files during a turn (with `Edit`, `Write`, `MultiEdit`, or `NotebookEdit`), it can't finish until its final message ends with:

- **`## Evidence`:** the checks it actually ran, with verbatim output, what each proved and didn't prove, and a verdict.
- **`## Decisions`:** every choice you didn't specify, with "needs your call" items first.

If a section is missing, the hook sends Claude back once to add it. Turns that change no files (questions, chat, research) finish normally.

**Limits:**
- The hook blocks at most once per stop, so it can never trap a session in a loop.
- It fails open: if `jq` or the transcript is unavailable, Claude stops normally.
- File changes made only through `Bash` (`sed`, scripts) aren't detected.

**Turn it off** for a project by adding this to `.claude/settings.json`:

```json
{ "env": { "NO_SURRENDER_STOP_GUARD": "off" } }
```

Set it in your shell to turn it off everywhere.

## A typical loop

```text
/brief "add rate limiting to the public API"
/blindspots              # security? deploy? what happens to existing clients?
... agent works ...
/evidence                # what ran, what it proved, what it didn't
/decisions               # what the agent decided for you
/quiz                    # can you defend it to whoever maintains it?
```

Not every task needs all five. Match the depth to how costly being wrong would be.

## Why

The best way to get good work out of an agent is to tell it what you care about. When you don't, it fills the gaps for you, and confidently. These commands are built on the ideas in *Critical thinking when agents do the work*:

- Form a hypothesis before you ask.
- Define "verified" upfront, because afterward you'll rationalize any outcome.
- A green check proves one thing. Ask what it didn't prove.
- Read what the agent decided for you, not just what it produced.
- If you can't explain it, even with the agent's help, you've surrendered it.

## License

MIT
