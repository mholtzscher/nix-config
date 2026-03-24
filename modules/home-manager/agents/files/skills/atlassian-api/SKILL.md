---
name: atlassian-api
description: Search Jira issues, fetch Jira issue details, search Confluence pages, and fetch Confluence page content through bundled curl+jq shell helpers. Use when interacting directly with Atlassian Cloud REST APIs in read-only mode.
compatibility: Requires bash, curl, jq, and Atlassian credentials provided via environment variables. Read-only by default.
references:
  - references/operations.md
---

# Atlassian API

Use this skill for common read-only Atlassian Cloud workflows against the Jira and Confluence REST APIs.

## Prerequisites

The bundled scripts read shared Atlassian credentials from:

- `ATLASSIAN_BASE_URL` — site URL, for example `https://example.atlassian.net`
- `ATLASSIAN_EMAIL` — Atlassian account email for basic auth
- `ATLASSIAN_API_TOKEN` — Atlassian API token

## Hard Rules

- Never hardcode credentials into scripts or checked-in files.
- Never print tokens back to the user.
- Use only read-only API operations unless the user explicitly asks for create/update/delete behavior.
- If auth fails, tell the user to check their Atlassian environment variables and API token setup.

## Quick Start

```bash
./scripts/jira-search.sh --project DEV --text authentication
./scripts/jira-get-issue.sh DEV-123
./scripts/confluence-search.sh --space DEV --title architecture
./scripts/confluence-get-content.sh 12345678
```

## Bundled Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/jira-search.sh` | Search issues with raw JQL or simple filters |
| `./scripts/jira-get-issue.sh` | Fetch issue metadata, description, and optional comments |
| `./scripts/confluence-search.sh` | Search pages with raw CQL or simple filters |
| `./scripts/confluence-get-content.sh` | Fetch page metadata plus text/html/storage body |

### Jira issue search

```bash
./scripts/jira-search.sh --project DEV --text authentication
./scripts/jira-search.sh --project DEV --status "In Progress" --limit 5
./scripts/jira-search.sh --query "project = DEV AND assignee = currentUser() ORDER BY updated DESC"
```

- Accepts raw `--query` or builds JQL from `--project`, `--summary`, `--text`, `--status`, `--assignee`, and `--type`.
- Returns one JSON object with `query`, `results`, and `pagination`.

### Jira issue details

```bash
./scripts/jira-get-issue.sh DEV-123
./scripts/jira-get-issue.sh DEV-123 --format rendered
./scripts/jira-get-issue.sh DEV-123 --comments
./scripts/jira-get-issue.sh DEV-123 --body-only
```

- Default format is `text`.
- Supported formats: `text`, `raw`, `rendered`.
- Standard output is JSON with `issue`, `descriptionFormat`, `description`, and optional `comments`.
- Use `--body-only` when only the description is needed.

### Confluence page search

```bash
./scripts/confluence-search.sh --space DEV --title architecture
./scripts/confluence-search.sh --text runbook --limit 5
./scripts/confluence-search.sh --query "space = DEV AND label = 'runbook'"
```

- Accepts raw `--query` or builds CQL from `--space`, `--title`, `--text`, and `--label`.
- Returns one JSON object with `query`, `results`, and `pagination`.

### Confluence page content

```bash
./scripts/confluence-get-content.sh 12345678
./scripts/confluence-get-content.sh 12345678 --format view
./scripts/confluence-get-content.sh 12345678 --format storage
./scripts/confluence-get-content.sh 12345678 --body-only
```

- Default format is `text`.
- Supported formats: `text`, `view`, `html`, `storage`.
- Standard output is JSON with `page`, `bodyFormat`, and `body`.
- Use `--body-only` when only the rendered content is needed.

## In This Reference

| File | Purpose |
|------|---------|
| [operations.md](./references/operations.md) | Env vars, Jira JQL patterns, Confluence CQL patterns, endpoints, and output notes |
