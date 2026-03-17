# SKILLS

## OVERVIEW

Registry for reusable OpenCode skills. Each skill is a directory with a `SKILL.md` entrypoint and optional support dirs.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Learn canonical skill shape | `build-skill/` | Source of truth for authoring rules |
| Generate AGENTS hierarchies | `index-knowledge/` | Documents this repo's doc-generation flow |
| Plan specs / RFCs | `spec-planner/` | Dialogue-first planning workflow |
| Research remote code | `librarian/` | Multi-repo exploration |
| Jira / Confluence ops | `atlas-cli/` | Atlas CLI usage |
| Commit message policy | `conventional-commits/` | Commit formatting rules |

## STRUCTURE

```text
skills/
|- <skill>/SKILL.md    # required entrypoint
|- <skill>/references/ # optional deep docs
`- <skill>/scripts/    # optional automation
```

## CONVENTIONS

- Directory name must match skill `name:` in frontmatter.
- Use lower-kebab-case names.
- `description:` must say what it does and when to use it.
- Keep `SKILL.md` under roughly 200 lines; move bulk examples/docs into `references/`.
- Use progressive disclosure: quick path in `SKILL.md`, detail in support files.
- If scripts exist, make them executable, document usage, and use `set -euo pipefail`.

## ANTI-PATTERNS

- Do not create a skill for one-off instructions better kept in root or subtree `AGENTS.md`.
- Do not copy large reference dumps into `SKILL.md`.
- Do not add individual `AGENTS.md` files inside each skill unless that skill grows its own build/release workflow.
- Do not skip validation when changing skill structure.

## NOTES

- Validate with `build-skill/scripts/validate_skill.sh <skill-dir>` when changing skill layout.
- `build-skill/` is the first file to read before authoring a new skill.
