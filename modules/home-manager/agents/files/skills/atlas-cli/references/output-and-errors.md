# Output Formats and Error Handling

## Output Formats

Controlled by `--output` flag.

### JSONL (default)

Each result on stdout: `{"data": <json>}`

Errors on stderr: `{"error": {"code": "...", "message": "...", "retryable": true|false, "details": {}}}`

**Pagination Metadata:**

For paginated list/search operations (`jira issue search`, `confluence space list`, `confluence page search`), a pagination record is emitted after all data records when more results are available:

```json
{"pagination":{"hasMore":true,"nextCursor":"abc123","returned":50}}
```

Fields:
- `hasMore`: Boolean indicating if additional results exist
- `nextCursor`: Token/cursor to fetch the next page
- `returned`: Number of records returned in this batch

When `hasMore` is false or pagination is not applicable (e.g., `confluence page comments`), the pagination record is omitted entirely.

Best for programmatic consumption. One JSON object per line.

### Text

Each result on stdout: raw JSON string + newline.

Errors on stderr: `CODE: message`

**Note:** Pagination metadata is not emitted in text format.

### Special case: `confluence page view`

Writes raw HTML or Markdown directly to stdout, bypassing the output format system entirely.

## Compact vs Raw Mode

**Compact** (default): Strips noisy fields to minimize tokens. Collapses nested objects to scalar values. Removes `_expandable`, `_links`, `avatarUrls`, `self`, `expand`, etc.

**Raw** (`--raw`): Full API response. Use when you need body content, all fields, or are debugging.

## Error Codes

| Code | HTTP Status | Retryable | Action |
|------|-------------|-----------|--------|
| `INVALID_ARGUMENT` | - | No | Fix the command arguments/flags |
| `AUTH_FAILED` | 401 | No | **Tell user to check their atlas config. Do not debug auth.** |
| `FORBIDDEN` | 403 | No | **Tell user to check their atlas config. Do not debug auth.** |
| `NOT_FOUND` | 404 | No | Verify the resource key/ID exists |
| `RATE_LIMITED` | 429 | Yes | Retry after `details.retryAfterSeconds` |
| `UPSTREAM_ERROR` | 5xx | Yes | Retry the request |
| `NETWORK_ERROR` | - | Yes | Retry the request |

## Retryable Errors

When `retryable: true`, the operation can be retried. For `RATE_LIMITED`, check `details.retryAfterSeconds` for the suggested wait time.

## Verbose Mode

`--verbose` logs HTTP request details to stderr. Useful for debugging API calls.

```bash
atlas --verbose jira issue describe PROJ-123
# stderr: GET https://yoursite.atlassian.net/rest/api/3/issue/PROJ-123 ...
```
