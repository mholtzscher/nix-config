# Agent Skills Configuration

This directory contains skills for AI agents. Skills are selectively loaded per agent.

## Available Skills

- `atlas-cli`: Atlassian CLI (Jira/Confluence)
- `build-skill`: Skill building utilities
- `conventional-commits`: Git commit conventions
- `index-knowledge`: Knowledge base indexing
- `librarian`: Multi-repo exploration
- `spec-planner`: Spec development and planning

## Adding Skills

1. Create a new directory here
2. Add a `SKILL.md` file with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What this skill does
   ---
   ```
3. Reference the skill in agent configs:
    - `modules/home-manager/agents/opencode.nix` (opencodeSkills list)
    - `modules/home-manager/agents/pi.nix` (piSkills list)
    - `modules/home-manager/agents/skills/default.nix` (source path map)

## Directory Structure

```
modules/home-manager/
├── agents/
│   ├── opencode.nix      # opencode config with skill list
│   ├── pi.nix            # pi config with skill list
│   └── skills/           # shared skill definitions
│       ├── atlas-cli/
│       ├── build-skill/
│       └── ...
```
