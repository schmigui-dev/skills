# Worktree sessions

How the Captain runs an assignment as a separate agent session in its own git worktree. Never at `recommend` autonomy: there every assignment is a subagent.

Creating the mission branch, crew branches and worktrees, and committing on them, is allowed at any autonomy level. None of it touches the user's branch, the user's checkout or the remote. **Never switch, check out, merge into or otherwise touch the user's checkout** during flight: all merging happens in the mission worktree.

## Paths

Shell variables don't survive between commands: compute these once and use the absolute values literally in every later command. Quote every path.

- `<root>`: `git rev-parse --show-toplevel` from your session (the main repo).
- `<repo>`: `basename "<root>"`.
- `<parent>`: `dirname "<root>"`.
- Mission worktree: `"<parent>/<repo>-mc-<mission-id>"`, on branch `mc/<mission-id>`.
- Crew worktree: `"<parent>/<repo>-mc-<crew-id>"`, on branch `mc/<mission-id>--<crew-id>`. (Not `mc/<mission-id>/<crew-id>`: git can't hold a branch `mc/<mission-id>` and branches under `mc/<mission-id>/` at the same time.)
- Assignment: `"<root>/.mission-control/missions/<mission-id>/assignments/<crew-id>.md"`.
- Report: `"<root>/.mission-control/missions/<mission-id>/reports/<crew-id>.md"`.
- Log: `"<root>/.mission-control/missions/<mission-id>/reports/<crew-id>.log"`.

## Set up

1. **Mission branch and mission worktree**, once, when the first worktree is needed. The branch is cut from HEAD, so uncommitted work in the user's tree is not included (the plan already raised this if the tree was dirty).

   ```bash
   git -C "<root>" worktree add -b "mc/<mission-id>" "<parent>/<repo>-mc-<mission-id>" HEAD
   ```

   Set `mission-branch: mc/<mission-id>` and `mode: worktrees` (or `mixed`) in `state.md`.

2. **Crew worktree**, created when that crew member launches (not earlier), from the mission branch as it is then, so a sequenced assignment starts from the merged work before it:

   ```bash
   git -C "<root>" worktree add -b "mc/<mission-id>--<crew-id>" "<parent>/<repo>-mc-<crew-id>" "mc/<mission-id>"
   ```

3. **Assignment file**: write the filled-in assignment template to the assignment path in the main repo (`mkdir -p` its `assignments/` and `reports/` folders first). Its **Mode** names the crew worktree and branch, and its **Brings back** names the report path, all absolute.

## Launch

Use `crew-command` from `.mission-control/config.md` exactly as written (e.g. `claude -p`, `codex exec`, or Cursor's agent CLI). Run it in the background, with cwd = the crew worktree, this prompt, and stdout and stderr going to the log:

```bash
cd "<parent>/<repo>-mc-<crew-id>" && <crew-command> "Read <assignment path> and do it. Write your report to <report path>." > "<log path>" 2>&1
```

- **Never add flags to `crew-command`**, least of all permission or bypass flags. Permissions are the user's job: run exactly what's configured.
- `crew-command` unset, or launching isn't possible here: print the exact command (above) for the user to run in a new terminal, and wait for them to say it's done.

## Wait

A crew member is done when its process has exited. Wait with whatever background or notification mechanism the host has (e.g. a background command that notifies you when it exits). If there is none, poll for the report file at a sensible interval (a minute or so), never in a tight loop.

- **Success:** exit code 0 and the report file exists.
- **Failure:** a non-zero exit, or an exit with no report file. Show the last lines of the log (`tail -n 40 "<log path>"`), report the failure, and print the launch command for the user to run themselves. Permission failures show up here, in the log: don't retry with extra flags.

## Collect and merge

The report names the commit(s) the crew member made on its branch. Check the report has the **Verify with** output, and that the branch holds those commits:

```bash
git -C "<root>" log --oneline "mc/<mission-id>..mc/<mission-id>--<crew-id>"
```

Merge each finished crew branch in the mission worktree, in the planned order:

```bash
git -C "<parent>/<repo>-mc-<mission-id>" merge --no-ff "mc/<mission-id>--<crew-id>"
```

- **Conflict:** run `git -C "<parent>/<repo>-mc-<mission-id>" merge --abort`, stop, and add a **Needs your call** item to `state.md` naming the conflicting crew branches and files (source `plan`). Don't resolve it by guessing.
- **Remove a crew worktree** only when its branch is merged into `mc/<mission-id>` and the worktree is clean (`git -C "<parent>/<repo>-mc-<crew-id>" status --porcelain` prints nothing):

  ```bash
  git -C "<root>" worktree remove "<parent>/<repo>-mc-<crew-id>"
  ```

  Never use `--force`. A worktree that isn't clean or isn't merged stays, and you list it.
- The mission worktree stays: it holds the combined result for `/mission-control:verify` and `/mission-control:go-no-go`.
- On abort, leave every worktree in place and list them with their branches.
