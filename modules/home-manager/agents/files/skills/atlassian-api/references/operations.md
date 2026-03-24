# Atlassian API Operations

## Required environment variables

```bash
export ATLASSIAN_BASE_URL="https://example.atlassian.net"
export ATLASSIAN_EMAIL="you@example.com"
export ATLASSIAN_API_TOKEN="..."
```

The scripts use basic auth with `curl` and never read any local config file.

## Use the wrappers first

```bash
./scripts/jira-search.sh --project DEV --text authentication
./scripts/jira-get-issue.sh DEV-123
./scripts/jira-get-issue.sh DEV-123 --comments
./scripts/confluence-search.sh --space DEV --title architecture
./scripts/confluence-get-content.sh 12345678 --body-only
```

## REST endpoints used by the scripts

Jira:

```text
GET /rest/api/3/search/jql?jql=...
GET /rest/api/3/issue/{key}?fields=...&expand=renderedFields
```

Confluence:

```text
GET /wiki/rest/api/content/search?cql=...
GET /wiki/rest/api/content/{id}?expand=space,version,metadata.labels,body.storage,body.view
```

## Common JQL patterns

```text
project = DEV
project = DEV AND status = "In Progress"
project = DEV AND summary ~ "auth"
project = DEV AND text ~ "authentication"
assignee = currentUser()
reporter = currentUser() AND updated >= -7d
project = DEV ORDER BY updated DESC
```

## Common CQL patterns

```text
space = DEV
space = DEV AND title ~ "architecture"
space = DEV AND text ~ "runbook"
label = "runbook"
ancestor = 12345678
text ~ "search term"
type = page AND lastModified > now("-7d")
```

## Search Strategy

Jira JQL and Confluence CQL are not semantic search. Try multiple related terms and fields.

- Search summary/title and body text separately
- Try synonyms and abbreviations
- Narrow by project or space when the result set is noisy
- Prefer exact fields like labels, status, assignee, or issue type when available

Examples:

```bash
./scripts/jira-search.sh --query "summary ~ 'auth'"
./scripts/jira-search.sh --query "text ~ 'authentication'"
./scripts/confluence-search.sh --query "title ~ 'auth'"
./scripts/confluence-search.sh --query "text ~ 'authentication'"
```

## Output notes

- `jira-search.sh` emits one normalized JSON object.
- `jira-get-issue.sh` emits one JSON object with issue metadata plus description and optional comments.
- `--format text` on `jira-get-issue.sh` converts Atlassian Document Format to approximate plain text.
- `--format raw` on `jira-get-issue.sh` returns the raw ADF description document.
- `confluence-search.sh` emits one normalized JSON object.
- `confluence-get-content.sh` emits one JSON object with metadata plus body content.
- `--format text` on `confluence-get-content.sh` converts rendered HTML to approximate plain text using jq-based cleanup.
- `--format view` and `--format html` return rendered HTML.
- `--format storage` returns the storage-format body.
