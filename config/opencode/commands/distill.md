---
description: "Distill project artifacts into domain knowledge bases and auto-commit the changes. Usage: /distill [--dry-run] [--no-archive] [--domain=<budget|groceries|website|botman|agentboard|pets|project>]"
---

You are a knowledge distillation operator. Execute this workflow exactly, preserving concrete technical specifics and avoiding generic rewrites.

### Inputs
- Flags argument: `$1` (optional combined flags string)
  - `--dry-run`: run Phases 1-4 only, then stop after preview (no writes, no archive)
   - `--no-archive`: run Phases 1-6, skip Phase 7 entirely
  - `--domain=X`: only process artifacts relevant to domain `X`
    - Allowed values: `budget`, `groceries`, `website`, `botman`, `agentboard`, `pets`, `project`

## Operating Rules
- This is iterative processing: handle **one notepad project at a time**.
- Skip `boulder.json` everywhere; it is active execution state.
- Skip the entire `evidence/` directory everywhere.
- Ignore non-markdown files.
- Preserve specificity in every entry: file paths, class names, namespaces, route patterns, table/column names, config keys, exact thresholds, versions.
- Use exactly these 5 categories only: **Learnings, Decisions, Gotchas, Patterns, Standards**.

## Phase 1 — Discovery & Inventory
1. Discover source artifacts from both ecosystems:
   - `.sisyphus/notepads/*/` (each subdirectory is one notepad project)
   - `.sisyphus/plans/*.md`
   - `.sisyphus/drafts/*.md`
   - `docs/superpowers/plans/*.md`
   - `docs/superpowers/specs/*.md`
2. Exclusions:
   - Skip `boulder.json`
   - Skip any path inside an `evidence/` directory
   - Skip non-`.md` files
3. If `--domain=X` is present, keep only artifacts relevant to domain `X`.
4. If nothing remains after filtering, output exactly:
   - `No artifacts to distill.`
   Then stop.
5. Output a numbered inventory list of discovered artifacts, grouped by source area.

## Phase 2 — Read & Extract
1. Process notepad projects **one at a time** (never batch all projects together).
2. For each discovered notepad project, read if present:
   - `learnings.md`
   - `decisions.md`
   - `issues.md`
   - `problems.md`
   Missing files are allowed; skip silently.
3. For `.sisyphus/plans/*.md`, `.sisyphus/drafts/*.md`, `docs/superpowers/plans/*.md`, and `docs/superpowers/specs/*.md`:
   - Extract only durable knowledge: decisions, patterns, standards, gotchas, verified learnings.
   - Do **not** copy step-by-step execution workflow instructions.
4. Keep extracted notes atomic and precise; do not paraphrase away technical identifiers.

## Phase 3 — Categorize & Assign Domains
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

## Phase 4 — Preview
1. Build a preview grouped by target file and category.
2. For each target file show summary line:
   - `[CREATE] N entries`
   - or `[UPDATE] N entries`
3. If a target knowledge file already exists, compare proposed entries and mark each as:
   - `NEW •` for not yet captured
   - `ALREADY CAPTURED •` for existing knowledge
4. Display proposed entries under category headings per file.
5. If `--dry-run` is present, stop after preview and report that no changes were written.

## Phase 5 — Write Knowledge Files
1. Ensure `docs/knowledge/` exists at project root.
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
4. AGENTS.md updates (domain-level only):
   - Find the domain-level AGENTS.md file (e.g., `src/Budget/AGENTS.md`, `app/Agentboard/AGENTS.md`).
   - Do NOT modify the root `AGENTS.md` — it is auto-generated by `init-deep` and your changes would be overwritten.
    - Add a `## Knowledge Base` section if not present, with a link to that domain's knowledge file.

## Phase 6 — Commit Knowledge Changes
1. If `--dry-run` is present, skip this phase entirely.
2. Verify git is available: run `git rev-parse --is-inside-work-tree`.
   - If not a git repo, output: `Not a git repository — skipping commit.` and continue to archive phase.
3. Stage the specific `docs/knowledge/*.md` files that were created or modified in Phase 5.
   - Use explicit paths: `git add docs/knowledge/budget.md docs/knowledge/project.md` (only the files actually touched).
   - Do NOT use `git add .` or `git add docs/knowledge/`.
4. Stage any domain-level AGENTS.md files that were updated in Phase 5 (the `## Knowledge Base` section additions).
   - Use explicit paths: `git add src/Budget/AGENTS.md app/Agentboard/AGENTS.md` (only the files actually touched).
5. Check if anything is staged: run `git diff --cached --quiet`.
   - If exit code 0 (nothing staged), output: `No knowledge changes to commit.` and skip to archive phase.
6. Build commit message listing affected domains:
   - If files were created AND updated: `knowledge(distill): create <created-domains>, update <updated-domains> knowledge bases`
   - If only updates: `knowledge(distill): update <domain-list> knowledge bases`
   - If only creates: `knowledge(distill): create <domain-list> knowledge bases`
   - If AGENTS.md files were also updated, append: `, update domain AGENTS.md`
   - Example: `knowledge(distill): update budget, project knowledge bases, update domain AGENTS.md`
7. Run `git commit -m "<message>"`.
8. Output commit confirmation: short SHA and message.
   - If commit fails, output the error and stop. Do NOT attempt rollback.

## Phase 7 — Archive Sources
1. If `--no-archive` is present, skip this entire phase.
2. Create archive folders for today (`YYYY-MM-DD`):
   - `.sisyphus/archive/{YYYY-MM-DD}/`
   - `docs/superpowers/archive/{YYYY-MM-DD}/`
3. Move processed sources into the correct archive root:
   - To `.sisyphus/archive/{YYYY-MM-DD}/`:
     - processed `.sisyphus/notepads/*`
     - processed `.sisyphus/plans/*.md`
     - processed `.sisyphus/drafts/*.md`
   - To `docs/superpowers/archive/{YYYY-MM-DD}/`:
     - processed `docs/superpowers/plans/*.md`
     - processed `docs/superpowers/specs/*.md`
4. Never archive `boulder.json`.
5. Finish with a concise summary that includes:
   - knowledge files created/updated
   - AGENTS.md domain files updated
   - archive destinations used (or skipped state)

## Empty-State Handling
- If discovery yields zero processable artifacts, return `No artifacts to distill.` and exit successfully.
- If an individual project folder has none of `learnings.md`, `decisions.md`, `issues.md`, `problems.md`, skip that project and continue.
- If Phase 5 is skipped (early exit), Phase 6 is also skipped — no commit is made.
