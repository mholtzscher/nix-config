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
| Add reusable knowledge/workflow | `skills/` | See `skills/AGENTS.md` |
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
- Use YAML frontmatter for agent and skill entry files.
- Keep commands thin: route to skills, do not stuff long policy docs into command files.
- Keep deep background in `skills/*/references/`; keep entry files short enough to scan fast.

## ANTI-PATTERNS

- Do not duplicate skill-authoring rules here; put them in `skills/AGENTS.md`.
- Do not turn plugins into general-purpose automation if a script or skill can do it.
- Do not bury repo-global policy in one command or one agent file.
- Do not add empty placeholder trees unless a command/skill/agent will load them now.

## LOCAL RULES

- In interaction and commit messages, be extremely concise; sacrifice grammar for concision.
- Make minimal, surgical changes.
- Never use `any`, non-null assertions, or type assertions.
- Make illegal states unrepresentable; parse inputs at boundaries.
- Use Oracle for code review / planning / debugging second opinion.
- Use Librarian for third-party library or remote-repo research.
