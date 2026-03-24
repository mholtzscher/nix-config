#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/confluence-search.sh --query "space = DEV AND text ~ 'runbook'"
  ./scripts/confluence-search.sh --space DEV --title architecture
  ./scripts/confluence-search.sh --space DEV --text deployment --limit 5
  ./scripts/confluence-search.sh --label runbook

Options:
  --query <cql>    Raw CQL query. If omitted, the script builds one from the filters below.
  --space <key>    Restrict search to a Confluence space key.
  --title <term>   Partial title match.
  --text <term>    Full-text body match.
  --label <label>  Exact label match.
  --limit <n>      Maximum number of results to return. Default: 10.
  --start <n>      Offset for pagination. Default: 0.
  -h, --help       Show this help.
EOF
}

limit=10
start=0
query=""
space=""
title=""
text=""
label=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      [[ $# -ge 2 ]] || die "Missing value for --query"
      query="$2"
      shift 2
      ;;
    --space)
      [[ $# -ge 2 ]] || die "Missing value for --space"
      space="$2"
      shift 2
      ;;
    --title)
      [[ $# -ge 2 ]] || die "Missing value for --title"
      title="$2"
      shift 2
      ;;
    --text)
      [[ $# -ge 2 ]] || die "Missing value for --text"
      text="$2"
      shift 2
      ;;
    --label)
      [[ $# -ge 2 ]] || die "Missing value for --label"
      label="$2"
      shift 2
      ;;
    --limit)
      [[ $# -ge 2 ]] || die "Missing value for --limit"
      limit="$2"
      shift 2
      ;;
    --start)
      [[ $# -ge 2 ]] || die "Missing value for --start"
      start="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

[[ "$limit" =~ ^[0-9]+$ ]] || die "--limit must be a non-negative integer"
[[ "$start" =~ ^[0-9]+$ ]] || die "--start must be a non-negative integer"

require_confluence_env

if [[ -z "$query" ]]; then
  filters=()

  [[ -n "$space" ]] && filters+=("space = \"$(cql_escape "$space")\"")
  [[ -n "$title" ]] && filters+=("title ~ \"$(cql_escape "$title")\"")
  [[ -n "$text" ]] && filters+=("text ~ \"$(cql_escape "$text")\"")
  [[ -n "$label" ]] && filters+=("label = \"$(cql_escape "$label")\"")

  (( ${#filters[@]} > 0 )) || die "Provide --query or at least one of --space, --title, --text, or --label"
  query="$(join_by ' AND ' "${filters[@]}")"
fi

api_url="$(confluence_api_url "/content/search?cql=$(url_encode "$query")&limit=$limit&start=$start&expand=$(url_encode "space,version,metadata.labels")")"

confluence_get_json "$api_url" |
  jq --arg query "$query" --argjson limit "$limit" --argjson start "$start" '
    def page_url:
      if (._links.base? and ._links.webui?) then
        ._links.base + ._links.webui
      elif ._links.webui? then
        ._links.webui
      else
        null
      end;

    def normalized_labels:
      (.metadata.labels.results // [])
      | map(.name // tostring);

    {
      query: $query,
      results: [
        (.results // [])[]
        | {
            id,
            title,
            type: (.type // "page"),
            status: (.status // null),
            spaceKey: (.space.key // null),
            updatedAt: (.version.when // null),
            url: page_url,
            excerpt: (.excerpt // null),
            labels: normalized_labels
          }
      ],
      pagination: {
        start: (.start // $start),
        limit: (.limit // $limit),
        size: ((.results // []) | length),
        hasMore: (._links.next? != null),
        next: (._links.next // null)
      }
    }
  '
