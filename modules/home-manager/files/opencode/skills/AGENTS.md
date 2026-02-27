# OPENCODE SKILLS KNOWLEDGE

## OVERVIEW
Reusable skill packs for opencode. Each subdir owns one skill via `SKILL.md` frontmatter + optional refs/scripts.

## STRUCTURE
```text
modules/home-manager/files/opencode/skills/
├── build-skill/            # Authoring/validation workflow for skills
├── conventional-commits/   # Commit/PR message conventions
├── index-knowledge/        # Hierarchical AGENTS generation workflow
├── librarian/              # Multi-repo research workflow
└── spec-planner/           # Dialogue-first planning workflow
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new skill | `skills/<skill-name>/SKILL.md` | Directory name should match frontmatter `name` |
| Add long docs | `skills/<skill-name>/references/` | Keep `SKILL.md` concise |
| Add automation | `skills/<skill-name>/scripts/` | Keep scripts executable and documented |
| Validate skill shape | `skills/build-skill/scripts/validate_skill.sh` | Catches frontmatter/link/layout issues |

## CONVENTIONS
- `SKILL.md` starts with YAML frontmatter (`name`, `description` at minimum).
- Keep `SKILL.md` short; push heavy detail into `references/`.
- Use explicit workflow phases and anti-patterns for behavior-heavy skills.
- Prefer parallel tool execution guidance where independent.

## ANTI-PATTERNS (THIS DIRECTORY)
- Mismatch between directory name and frontmatter `name`.
- Broken skill include paths in command files (`commands/*.md`).
- Repeating generic advice that belongs in root/opencode AGENTS.
- Overloading `SKILL.md` with long reference content instead of `references/`.

## CURRENT DRIFT TO FIX WHEN TOUCHED
- `conventional-commits/SKILL.md` uses `name: conventional-commit` (singular) while directory is plural.
- `commands/build-skill.md` references `skill/build-skill/SKILL.md`; expected path prefix is `skills/`.
