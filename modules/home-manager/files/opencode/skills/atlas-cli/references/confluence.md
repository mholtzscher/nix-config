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
atlas confluence page describe 12345678 --include-labels --include-versions
```

| Flag | Type | Description |
|------|------|-------------|
| `--include-labels` | bool | Include page labels |
| `--include-properties` | bool | Include page properties |
| `--include-operations` | bool | Include permitted operations |
| `--include-versions` | bool | Include version history |

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

Search pages using CQL. `--cql` is required.

```bash
atlas confluence page search --cql "space = DEV AND title ~ 'architecture'"
atlas confluence page search --cql "label = 'runbook'" --limit 10
atlas confluence page search --cql "type = page AND lastModified > now('-7d')" --include-labels
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--cql` | string | - | CQL query (required) |
| `--include-labels` | bool | `false` | Include page labels |
| `--include-properties` | bool | `false` | Include page properties |
| `--include-operations` | bool | `false` | Include permitted operations |
| `--include-versions` | bool | `false` | Include version history |
| `--raw` | bool | `false` | Full payload |
| `--limit` | int | `25` | Max total results |

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

## page comments

Get footer comments on a page. Performs DFS traversal of comment threads (fetches replies recursively). Comments include the body content as plain text.

```bash
atlas confluence page comments 12345678
atlas confluence page comments 12345678 --limit 100
```

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--raw` | bool | `false` | Full payload |
| `--limit` | int | `25` | Max total comments (including thread replies) |
