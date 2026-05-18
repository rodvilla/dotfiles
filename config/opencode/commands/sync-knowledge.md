---
description: "Run /absorb and /distill sequentially, each committing their changes, then optionally push. Usage: /sync-knowledge [--dry-run] [--domain=<budget|groceries|website|botman|agentboard|pets|project>] [--session=<session-id>]"
---

You are a knowledge synchronization operator. Execute this workflow exactly: first absorb knowledge from the current session, then distill knowledge from artifacts, committing each step, and optionally push all changes.

### Inputs
- Flags argument: `$1` (optional combined flags string)
  - `--dry-run`: run both /absorb and /distill in preview mode (no writes, no commits), then skip push
  - `--domain=X`: only extract and write knowledge relevant to domain `X`
    - Allowed values: `budget`, `groceries`, `website`, `botman`, `agentboard`, `pets`, `project`
  - `--session=ID`: use the specified session ID instead of the most recent session (passed to /absorb only)

## Operating Rules
- Execute /absorb workflow first, then /distill workflow — never in parallel. These commands exist on ~/.config/opencode/commands.
- Pass applicable flags through to each sub-workflow: `--dry-run` and `--domain` to both; `--session` to /absorb only.
- Track whether each sub-workflow produced a commit (for the push prompt decision).
- If both sub-workflows exit early (no new knowledge from either), skip the push prompt entirely.

## Phase 1 — Absorb

1. Execute the full `/absorb` workflow (all 6 phases from `commands/absorb.md`) with any applicable flags (`--dry-run`, `--domain`, `--session`).
2. Follow the `/absorb` command definition in `commands/absorb.md` exactly — all phases, all rules, all empty-state handling.
3. Track the outcome:
   - If /absorb exited early (no session, no knowledge, all captured): record `absorb_committed = false`
   - If /absorb completed Phase 6 with a successful commit: record `absorb_committed = true`
   - If /absorb Phase 6 skipped commit (nothing staged, not a git repo): record `absorb_committed = false`
4. Output a separator: `---` and `Absorb phase complete. Proceeding to distill...`

## Phase 2 — Distill

1. Execute the full `/distill` workflow (all 7 phases from `commands/distill.md`) with any applicable flags (`--dry-run`, `--domain`, `--no-archive` if passed).
2. Follow the `/distill` command definition in `commands/distill.md` exactly — all phases, all rules, all empty-state handling.
3. Track the outcome:
   - If /distill exited early (no artifacts): record `distill_committed = false`
   - If /distill completed Phase 6 with a successful commit: record `distill_committed = true`
   - If /distill Phase 6 skipped commit (nothing staged, not a git repo): record `distill_committed = false`
4. Output a separator: `---` and `Distill phase complete.`

## Phase 3 — Push Prompt

1. If `--dry-run` is present, output: `Dry run complete. No changes were written or committed.` and stop.
2. If both `absorb_committed` and `distill_committed` are false, output: `No knowledge changes were committed. Nothing to push.` and stop.
3. Build a summary of what was committed:
   - If `absorb_committed`: include the absorb commit (SHA + message)
   - If `distill_committed`: include the distill commit (SHA + message)
4. Use the **Question tool** to ask the user:
   - Question: `Knowledge commits ready. Do you want to push to remote?`
   - Options:
     - `Yes, push` — description: `Run git push to send the knowledge commits to remote`
     - `No, don't push` — description: `Keep commits local. You can push manually later.`
5. If user selects "Yes, push":
   - Run `git push`
   - Output the push result (success or failure)
6. If user selects "No, don't push":
   - Output: `Commits kept local. Run 'git push' when ready.`

### End Phase
1. Make sure that `Phase 7 — Archive Sources` was executed and there's no remaining unstaged changes on .sisyphus, if there is then run the mentioned Phase 7.

## Empty-State Handling
- If /absorb finds no session or no knowledge, it exits its sub-workflow early. /distill still runs.
- If /distill finds no artifacts, it exits its sub-workflow early. Push prompt only appears if at least one commit was made.
- If `--dry-run` is present, both sub-workflows run in preview mode and Phase 3 confirms dry-run completion.
