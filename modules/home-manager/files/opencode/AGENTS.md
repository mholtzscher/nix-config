# OPENCODE

## OVERVIEW

Repo-local OpenCode config tree synced by `modules/home-manager/programs/opencode.nix` into `${config.xdg.configHome}/opencode`.
This dir holds persona defs, slash commands, reusable skills, and small runtime plugins.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Change package / permissions / MCP / models | `modules/home-manager/programs/opencode.nix` | Wiring lives there, not here |
| Adjust subagent personas | `agents/` | YAML frontmatter + prompt body |
| Add slash command | `commands/` | Thin entrypoint; load skills when workflow is non-trivial |
| Add reusable knowledge/workflow | `skills/` | Directory per skill; `SKILL.md` is required entrypoint |
| Change runtime interception | `plugins/` | Keep tiny; prefer docs/scripts first |

## STRUCTURE

```text
opencode/
|- AGENTS.md           # umbrella rules for this subtree
|- agents/             # persona definitions
|- commands/           # user-facing task entrypoints
|- skills/             # reusable workflow/domain packs
`- plugins/            # runtime hooks
```

## CONVENTIONS

- Keep naming kebab-case.
- Keep text telegraphic; brevity beats polish here.
- Use YAML frontmatter for agent, command, and skill entry files.
- Keep commands thin: route to skills, do not stuff long policy docs into command files.
- Keep deep background in `skills/*/references/`; keep entry files short enough to scan fast.
- In `skills/`, directory name should match skill `name:` and stay lower-kebab-case.
- Keep `skills/*/SKILL.md` short; push detail into `references/`, automation into `scripts/`.
- Read `skills/build-skill/SKILL.md` before authoring or restructuring a skill.

## ANTI-PATTERNS

- Do not duplicate detailed skill-authoring rules here; keep them in `skills/build-skill/SKILL.md`.
- Do not turn plugins into general-purpose automation if a script or skill can do it.
- Do not bury repo-global policy in one command or one agent file.
- Do not add empty placeholder trees unless a command/skill/agent will load them now.
- Do not create a skill for one-off instructions better kept in `AGENTS.md`.
- Do not add per-skill `AGENTS.md` files unless one skill grows its own local workflow.

## LOCAL RULES

- In interaction and commit messages, be extremely concise; sacrifice grammar for concision.
- Make minimal, surgical changes.
- Never use `any`, non-null assertions, or type assertions.
- Make illegal states unrepresentable; parse inputs at boundaries.
- Use Oracle for code review / planning / debugging second opinion.
- Use Librarian for third-party library or remote-repo research.
