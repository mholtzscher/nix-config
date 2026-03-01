---
name: atlas-cli
description: Interact with Atlassian Jira and Confluence via the atlas CLI. Use when querying issues, searching with JQL/CQL, reading Confluence pages, or listing projects/spaces.
---

# Atlas CLI

Use `atlas` to fetch Atlassian Cloud data (Jira, Confluence). Prefer read-only ops.

## Hard Rules

- Auth: **NEVER read/write auth config** (`atlas.json`, `~/.config/atlas/atlas.json`). Never pass `--email`, `--api-token`, or `--site` inline.
- Side effects: run only read-only commands unless user explicitly asks for create/update/delete.
- Output: prefer `--output jsonl`; `atlas confluence page view` writes raw HTML/Markdown to stdout (not JSONL).

If a command fails with `AUTH_FAILED`, `FORBIDDEN`, or missing `--site`, tell the user:

> Authentication failed. Please check your atlas configuration. Run `atlas --help` or see the atlas docs for setup instructions.

Do not attempt to fix auth, read configs, or suggest token values.

## Quick Start

```bash
atlas jira issue describe PROJ-123
```

## Common Tasks (Pick The Smallest Command)

Jira:

```bash
atlas jira issue describe PROJ-123
atlas jira issue search --query "project = PROJ AND status != Done" --limit 10
atlas jira issue comments PROJ-123
atlas jira project list
atlas jira issue types
atlas jira myself
```

**Note:** Jira search is not semantic - see [jira.md](./references/jira.md) for search strategy (try related terms, synonyms, summary vs text searches).

Confluence:

```bash
atlas confluence space list
atlas confluence space describe DEV
atlas confluence page describe 12345678
atlas confluence page view 12345678 --format markdown
atlas confluence page search --query "space = DEV AND title ~ 'architecture'" --limit 10
atlas confluence page comments 12345678
```

**Note:** Confluence search is not semantic - see [confluence.md](./references/confluence.md) for search strategy (try related terms, synonyms, title vs text searches).

## In This Reference

| File | Purpose |
|------|---------|
| [jira.md](./references/jira.md) | Jira commands, JQL examples, fields |
| [confluence.md](./references/confluence.md) | Confluence commands, CQL examples |
| [output-and-errors.md](./references/output-and-errors.md) | Output formats, error codes, retryable errors |

## Reading Order

| Task | Files |
|------|-------|
| Query Jira issues | jira.md |
| Read Confluence pages | confluence.md |
| Parse/handle output | output-and-errors.md |
