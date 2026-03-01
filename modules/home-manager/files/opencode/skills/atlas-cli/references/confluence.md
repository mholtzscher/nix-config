# Confluence Commands

## space list

List accessible Confluence spaces.

```bash
atlas confluence space list
atlas confluence space list --limit 100
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--limit` | int | `25` | Max total results |
| `--page-size` | int | `25` | Results per API request |
| `--cursor` | string | - | Resume from specific position |
| `--raw` | bool | `false` | Full payload |

## space describe

Describe a space by its key.

```bash
atlas confluence space describe DEV
atlas confluence space describe DEV --raw
```

## page describe

Get page metadata by numeric page ID.

```bash
atlas confluence page describe 12345678
atlas confluence page describe 12345678 --include labels,versions
atlas confluence page describe 12345678 --include all
```

| Flag | Type | Description |
|------|------|-------------|
| `--include` | string slice | Fields to include: `labels`, `properties`, `operations`, `versions`, or `all` |

## page view

Render page body content. Writes directly to stdout (not through Emitter).

```bash
atlas confluence page view 12345678                    # HTML output
atlas confluence page view 12345678 --format markdown  # Markdown output
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--format` | string | `html` | Output format: `html` or `markdown` |

The HTML output is pretty-printed. Markdown conversion uses `html-to-markdown`.

## page search

Search pages using CQL. `--query` is required.

```bash
atlas confluence page search --query "space = DEV AND title ~ 'architecture'"
atlas confluence page search --query "label = 'runbook'" --limit 10
atlas confluence page search --query "type = page AND lastModified > now('-7d')" --include labels
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--query` | string | - | CQL query (required) |
| `--include` | string slice | - | Fields to include: `labels`, `properties`, `operations`, `versions`, or `all` |
| `--raw` | bool | `false` | Full payload |
| `--limit` | int | `25` | Max total results |
| `--page-size` | int | `25` | Results per API request |
| `--cursor` | string | - | Resume from specific position |

### Common CQL patterns

```
space = DEV                                  # pages in space
title = "Exact Title"                        # exact title match
title ~ "partial"                            # title contains
label = "runbook"                            # pages with label
type = page AND lastModified > now("-7d")    # recently modified pages
ancestor = 12345678                          # child pages under parent
text ~ "search term"                         # full-text search
```

### Search Strategy

Confluence CQL is not a semantic search engine. It does not automatically match related terms, synonyms, or variations. When searching, you must manually try multiple related terms and contexts.

**Best practices:**
- Search both `title` and `text` separately: `title ~ "term"` vs `text ~ "term"`
- Try synonyms and variations: "config" vs "configuration", "auth" vs "authentication"
- Search abbreviations: "API" vs "application programming interface"
- Check labels: `label = "topic"` may find better results than text search
- Use wildcards sparingly: `title ~ "deploy*"` matches "deploy", "deployment", "deploying"
- Search by space first: `space = TEAM AND text ~ "topic"` to narrow results

**Example dynamic search for "economics":**
```bash
# Search multiple related terms in a single query
atlas confluence page search --query "text ~ 'economics' OR text ~ 'pricing' OR text ~ 'cost' OR text ~ 'revenue' OR title ~ 'economics' OR label = 'economics'"
```

For more granular control over field matching, search terms can also be run separately:
```bash
atlas confluence page search --query "text ~ 'economics'"      # body text
atlas confluence page search --query "title ~ 'economics'"    # title only
atlas confluence page search --query "label = 'economics'"    # exact label match
```

## page comments

Get footer comments on a page. Performs DFS traversal of comment threads (fetches replies recursively). Returns **all comments** - pagination is not supported for this command. Comments include the body content as plain text.

```bash
atlas confluence page comments 12345678
atlas confluence page comments 12345678 --raw
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--raw` | bool | `false` | Full payload |
