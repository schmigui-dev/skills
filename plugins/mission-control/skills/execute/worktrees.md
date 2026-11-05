# Worktree sessions

How the Captain runs an assignment as a separate agent session in its own git worktree. Never at `recommend` autonomy: there every assignment is a subagent.

Creating the mission branch, crew branches and worktrees, and committing on them, is allowed at any autonomy level. None of it touches the user's branch or the remote.

## Set up

1. **Mission branch**, once, when the first worktree is needed: `mc/<mission-id>`, created from the user's current branch.

   ```bash
   git branch mc/<mission-id>
   ```

   Set `mission-branch: mc/<mission-id>` and `mode: worktrees` (or `mixed`) in `state.md`.

2. **One worktree per crew member**, next to the repo:

   ```bash
   git worktree add ../<repo>-mc-<crew-id> -b mc/<mission-id>/<crew-id> mc/<mission-id>
   ```

3. **Assignment file** in the **main** repo: `.mission-control/missions/<id>/assignments/<crew-id>.md`, the filled-in assignment template. Its report path is `.mission-control/missions/<id>/reports/<crew-id>.md`, also in the main repo. Give the crew member both as absolute paths.

## Launch

Use `crew-command` from `.mission-control/config.md` exactly as written (e.g. `claude -p`, `codex exec`, or Cursor's agent CLI). Run it in the background, with cwd = the worktree, and this prompt:

```text
Read <abs assignment path> and do it. Write your report to <abs report path>.
```

```bash
cd <abs worktree path> && <crew-command> "Read <abs assignment path> and do it. Write your report to <abs report path>."
```

- **Never add flags to `crew-command`**, least of all permission or bypass flags. Permissions are the user's job: run exactly what's configured.
- `crew-command` unset, or launching isn't possible here: print the exact command for the user to run in a new terminal, and wait for them to say it's done.
- A crew session fails on permissions: report the failure and print the command for the user to run themselves. Don't retry with extra flags.

## Collect and merge

- The crew's report is the file at its report path. Check it has the **Verify with** output.
- Merge each finished crew branch into `mc/<mission-id>`, in the planned order. A merge conflict means ownership overlapped: stop and tell the user, don't resolve it by guessing.
- After a successful merge, remove that crew's worktree (`git worktree remove ../<repo>-mc-<crew-id>`).
- On abort, leave the worktrees in place and list them for the user.
