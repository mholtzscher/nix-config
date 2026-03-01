# Jira Commands

## issue describe

Get details for a specific issue.

```bash
atlas jira issue describe PROJ-123
atlas jira issue describe PROJ-123 --fields labels,components
atlas jira issue describe PROJ-123 --raw   # full API payload
```

| Flag | Type | Description |
|------|------|-------------|
| `--fields` | string slice | Additional fields beyond defaults |
| `--expand` | string slice | Jira expand parameters |
| `--raw` | bool | Full payload, skip field projection |

### Default fields

`summary`, `status`, `issuetype`, `priority`, `assignee`, `reporter`, `project`, `created`, `updated`

Additional `--fields` values are additive (merged with defaults, deduplicated).

### Field projection behavior

By default, known nested objects are collapsed to scalar values:

| Field | Projected to |
|-------|-------------|
| `status` | `.name` |
| `issuetype` | `.name` |
| `priority` | `.name` |
| `assignee` | `.displayName` |
| `reporter` | `.displayName` |
| `project` | `.key` |

## issue search

Search issues using JQL. `--query` is required.

```bash
atlas jira issue search --query "project = PROJ AND status = 'In Progress'"
atlas jira issue search --query "assignee = currentUser() ORDER BY updated DESC" --limit 10
atlas jira issue search --query "sprint in openSprints()" --fields sprint,labels
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--query` | string | - | JQL query (required) |
| `--fields` | string slice | - | Additional fields |
| `--expand` | string slice | - | Jira expand parameters |
| `--raw` | bool | `false` | Full payload |
| `--limit` | int | `50` | Max total results |
| `--page-size` | int | `50` | Results per API request |
| `--page-token` | string | - | Resume from specific position |

### Common JQL patterns

```
project = PROJ                              # all issues in project
assignee = currentUser()                    # my issues
status changed to "Done" after -7d          # resolved last week
sprint in openSprints()                     # current sprint
labels = "bug" AND priority = High          # high priority bugs
text ~ "search term"                        # full-text search
ORDER BY updated DESC                       # sort by recently updated
```

### Search Strategy

Jira JQL is not a semantic search engine. It does not automatically match related terms, synonyms, or variations. When searching, you must manually try multiple related terms and contexts.

**Best practices:**
- Search both `summary` and `description` separately: `summary ~ "term"` vs `text ~ "term"`
- Try synonyms and variations: "bug" vs "defect" vs "issue", "PR" vs "pull request"
- Search abbreviations: "API" vs "application programming interface"
- Check labels: `labels = "topic"` may find better results than text search
- Use wildcards: `summary ~ "deploy*"` matches "deploy", "deployment", "deploying"
- Search by project first: `project = PROJ AND text ~ "topic"` to narrow results
- Try exact phrase vs partial: `"exact phrase"` vs `term`

**Example dynamic search for "performance":**
```bash
# Search multiple related terms in a single query
atlas jira issue search --query "text ~ 'performance' OR text ~ 'slow' OR text ~ 'latency' OR text ~ 'optimization' OR summary ~ 'performance' OR summary ~ 'speed' OR labels = 'performance'"
```

For more granular control over field matching, search terms can also be run separately:
```bash
atlas jira issue search --query "text ~ 'performance'"       # body text
atlas jira issue search --query "summary ~ 'performance'"     # title only
atlas jira issue search --query "labels = 'performance'"      # exact label match
```

## issue comments

Get comments on an issue. Comments include the body content as plain text (ADF converted to readable text).

```bash
atlas jira issue comments PROJ-123
```

No additional flags. Returns all comments with plain text bodies.

## issue types

List all issue types in the instance.

```bash
atlas jira issue types
```

## project list

List all accessible projects.

```bash
atlas jira project list
```

## myself

Get current authenticated user info. Useful for verifying auth works.

```bash
atlas jira myself
```
