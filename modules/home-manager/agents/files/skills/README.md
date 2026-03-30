# Agent Skills Configuration

This directory contains shared skills for your agents. Skill content lives here, while installation and selection are managed declaratively via `agent-skills-nix`.

## Available Skills

- `atlas-cli`: Atlassian CLI (Jira/Confluence)
- `atlassian-api`: Atlassian Jira/Confluence API helpers implemented with curl, bash, and jq
- `build-skill`: Skill building utilities
- `conventional-commits`: Git commit conventions
- `gradle`: Gradle build/test execution guidance
- `index-knowledge`: Knowledge base indexing
- `librarian`: Multi-repo exploration
- `mermaid`: Mermaid chart authoring and validation guidance
- `spec-planner`: Spec development and planning

## Adding Skills

1. Create a new directory under `modules/home-manager/agents/files/skills/<name>/`
2. Add a `SKILL.md` file with frontmatter:
   ```yaml
   ---
   name: skill-name
   description: What this skill does
   ---
   ```
3. Add the skill ID to the shared allowlist in `modules/home-manager/agents/agent-skills.nix`

No source-path map or per-agent skill list updates are needed.

## Directory Structure

```
modules/home-manager/
├── agents/
│   ├── agent-skills.nix  # shared agent-skills-nix configuration
│   ├── opencode.nix      # opencode config
│   ├── pi.nix            # pi config
│   └── files/
│       └── skills/       # shared skill definitions
│           ├── atlas-cli/
│           ├── atlassian-api/
│           ├── build-skill/
│           └── ...
```
