---
description: "Harvest durable knowledge from the current session into domain knowledge bases, then auto-commit the changes. Usage: /absorb [--dry-run] [--domain=<budget|groceries|website|botman|agentboard|pets|project>] [--session=<session-id>]"
---

You are a knowledge absorption operator. Execute this workflow exactly, extracting durable knowledge from conversation sessions and preserving concrete technical specifics.

### Inputs
- Flags argument: `$1` (optional combined flags string)
  - `--dry-run`: run Phases 1-4 only, then stop after preview (no writes)
  - `--domain=X`: only extract and write knowledge relevant to domain `X`
    - Allowed values: `budget`, `groceries`, `website`, `botman`, `agentboard`, `pets`, `project`
  - `--session=ID`: use the specified session ID instead of the most recent session

## Operating Rules
- Preserve specificity in every entry: file paths, class names, namespaces, route patterns, table/column names, config keys, exact thresholds, versions.
- Use exactly these 5 categories only: **Learnings, Decisions, Gotchas, Patterns, Standards**.
- Process user and assistant messages only — never tool call outputs or tool results.
- Keep entries atomic and precise; do not paraphrase away technical identifiers.

## Phase 1 — Session Identification
1. If `--session=ID` was provided, use that session ID directly.
2. Otherwise, call `session_list(limit=5)` and select the most recent session.
3. Call `session_read(session_id=..., include_tool_results=false)` to load conversation messages.
4. If no session is found or the session has no messages, output exactly:
   - `No conversation to absorb.`
   Then stop.
5. Output a brief confirmation: session ID, message count, and date range.

## Phase 2 — Extract Knowledge
1. Process only **user** and **assistant** messages — skip all tool invocations and results.
2. Read the full conversation looking for durable knowledge signals.

**INCLUDE** (extract these):
- Decisions made and their rationale (why X was chosen over Y)
- Bugs discovered and their root causes
- Patterns chosen and why they were preferred
- Approaches explicitly rejected and why
- Standards or conventions agreed upon
- Gotchas and non-obvious behaviors discovered
- Performance findings with concrete measurements or thresholds
- Configuration discoveries (specific keys, values, file paths)
- Workarounds for tool or library limitations
- Domain-specific rules or constraints surfaced during work

**EXCLUDE** (do not extract these):
- Step-by-step debugging transcripts ("let me check that file", "I see the error now")
- Ephemeral task context ("marking this complete", "starting on next item")
- Task management chatter (todo updates, status confirmations)
- Tool invocation noise and raw tool outputs
- Raw code snippets without a clear "lesson" or "decision" attached
- Status updates and progress reports
- Greetings, acknowledgments, and filler text
- Restatements of the obvious or of the task itself

3. If no durable knowledge signals are found after full review, output exactly:
   - `No durable knowledge found in this session.`
   Then stop.

## Phase 3 — Categorize & Route Domains
1. Categorize every extracted statement into exactly one of:
   - Learnings
   - Decisions
   - Gotchas
   - Patterns
   - Standards
2. Apply domain routing priority in this order:
   1) Route by **subject entity/feature ownership** — what domain owns the concept being documented (e.g., Agentboard resources, Budget transactions) — NOT by which implementation file mentions it. A Website provider file that wires Agentboard resources documents Agentboard knowledge → route to `agentboard.md`.
   2) If content references a domain model/table/route/namespace as the primary subject, route to that domain file.
   3) If content is framework/tooling/CI/convention, route to `project.md`.
   4) Otherwise fallback to `project.md`.
3. Domain auto-detection rules:
   - `budget`: `Transaction`, `Category`, `Inbox`, `src/Budget/`, `services.classifier`, `budget:` commands
   - `groceries`: grocery models/lists/items, `src/Groceries/`, MCP, `ai.php`
   - `website`: `Post`, `src/Website/`, website admin/provider concerns
   - `botman`: Telegram bot concerns, `src/Botman/`
   - `agentboard`: `Project`, `Card`, `Stage`, `app/Agentboard/`, Agentboard pipeline/pages
   - `pets`: `Pet`, `PetResource`, `app/Pets/`
   - `project`: framework-wide/tooling/CI/cross-domain conventions and fallback
4. Target files:
   - `docs/knowledge/budget.md`
   - `docs/knowledge/groceries.md`
   - `docs/knowledge/website.md`
   - `docs/knowledge/botman.md`
   - `docs/knowledge/agentboard.md`
   - `docs/knowledge/pets.md`
   - `docs/knowledge/project.md`
5. If `--domain=X` is present, discard all entries not routed to domain `X`.

## Phase 4 — Deduplicate & Preview
1. Build a preview grouped by target file and category.
2. For each target file show summary line:
   - `[CREATE] N entries`
   - or `[UPDATE] N entries`
3. If a target knowledge file already exists, compare proposed entries and mark each as:
   - `NEW •` for not yet captured
   - `ALREADY CAPTURED •` for existing knowledge
4. Display proposed entries under category headings per file.
5. If every proposed entry across all files is `ALREADY CAPTURED •`, output exactly:
   - `No new knowledge found in this session.`
   Then stop.
6. If `--dry-run` is present, stop after preview and report that no changes were written.

## Phase 5 — Write Knowledge Files
1. Ensure `docs/knowledge/` exists at project CWD.
2. For each target file:
   - If file exists: read current content, merge only `NEW •` entries into correct category headers, deduplicate.
   - If file does not exist: create it with exactly this skeleton:

```markdown
# {Domain} Knowledge Base

## Learnings

## Decisions

## Gotchas

## Patterns

## Standards
```

3. Entry format (strict):
   - `- **[Topic]**: [Concise statement preserving paths, versions, class names, keys, thresholds]`
4. Do NOT update any AGENTS.md files.
5. Finish with a concise summary:
    - knowledge files created/updated
    - total new entries written per file

## Phase 6 — Commit Knowledge Changes
1. If `--dry-run` is present, skip this phase entirely.
2. Verify git is available: run `git rev-parse --is-inside-work-tree`.
   - If not a git repo, output: `Not a git repository — skipping commit.` and continue to summary.
3. Stage only the specific `docs/knowledge/*.md` files that were created or modified in Phase 5.
   - Use explicit paths: `git add docs/knowledge/budget.md docs/knowledge/project.md` (only the files actually touched).
   - Do NOT use `git add .` or `git add docs/knowledge/`.
4. Check if anything is staged: run `git diff --cached --quiet`.
   - If exit code 0 (nothing staged), output: `No knowledge changes to commit.` and skip to summary.
5. Build commit message listing affected domains:
   - If files were created AND updated: `knowledge(absorb): create <created-domains>, update <updated-domains> knowledge bases`
   - If only updates: `knowledge(absorb): update <domain-list> knowledge bases`
   - If only creates: `knowledge(absorb): create <domain-list> knowledge bases`
   - Example: `knowledge(absorb): update budget, project knowledge bases`
6. Run `git commit -m "<message>"`.
7. Output commit confirmation: short SHA and message.
   - If commit fails, output the error and stop. Do NOT attempt rollback.

## Empty-State Handling
- If Phase 1 finds no session or empty session, return `No conversation to absorb.` and exit successfully.
- If Phase 2 finds no durable knowledge, return `No durable knowledge found in this session.` and exit successfully.
- If Phase 4 finds all entries already captured, return `No new knowledge found in this session.` and exit successfully.
- If Phase 5 is skipped (early exit), Phase 6 is also skipped — no commit is made.
