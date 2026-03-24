#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/jira-search.sh --query "project = DEV AND assignee = currentUser() ORDER BY updated DESC"
  ./scripts/jira-search.sh --project DEV --summary authentication
  ./scripts/jira-search.sh --project DEV --text deployment --limit 5
  ./scripts/jira-search.sh --project DEV --status "In Progress"

Options:
  --query <jql>       Raw JQL query. If omitted, the script builds one from the filters below.
  --project <key>     Restrict search to a Jira project key.
  --summary <term>    Partial summary match.
  --text <term>       Full-text issue match.
  --status <status>   Exact status match.
  --assignee <user>   Exact assignee match or JQL function expression.
  --type <type>       Exact issue type match.
  --limit <n>         Maximum number of results to return. Default: 10.
  --start <n>         Offset for pagination. Default: 0.
  -h, --help          Show this help.
EOF
}

limit=10
start=0
query=""
project=""
summary=""
text=""
status=""
assignee=""
issue_type=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query)
      [[ $# -ge 2 ]] || die "Missing value for --query"
      query="$2"
      shift 2
      ;;
    --project)
      [[ $# -ge 2 ]] || die "Missing value for --project"
      project="$2"
      shift 2
      ;;
    --summary)
      [[ $# -ge 2 ]] || die "Missing value for --summary"
      summary="$2"
      shift 2
      ;;
    --text)
      [[ $# -ge 2 ]] || die "Missing value for --text"
      text="$2"
      shift 2
      ;;
    --status)
      [[ $# -ge 2 ]] || die "Missing value for --status"
      status="$2"
      shift 2
      ;;
    --assignee)
      [[ $# -ge 2 ]] || die "Missing value for --assignee"
      assignee="$2"
      shift 2
      ;;
    --type)
      [[ $# -ge 2 ]] || die "Missing value for --type"
      issue_type="$2"
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

require_jira_env

if [[ -z "$query" ]]; then
  filters=()

  [[ -n "$project" ]] && filters+=("project = \"$(jql_escape "$project")\"")
  [[ -n "$summary" ]] && filters+=("summary ~ \"$(jql_escape "$summary")\"")
  [[ -n "$text" ]] && filters+=("text ~ \"$(jql_escape "$text")\"")
  [[ -n "$status" ]] && filters+=("status = \"$(jql_escape "$status")\"")
  [[ -n "$assignee" ]] && filters+=("assignee = \"$(jql_escape "$assignee")\"")
  [[ -n "$issue_type" ]] && filters+=("issuetype = \"$(jql_escape "$issue_type")\"")

  (( ${#filters[@]} > 0 )) || die "Provide --query or at least one of --project, --summary, --text, --status, --assignee, or --type"
  query="$(join_by ' AND ' "${filters[@]}") ORDER BY updated DESC"
fi

fields="summary,status,issuetype,project,assignee,reporter,priority,updated"
api_url="$(jira_api_url "/search/jql?jql=$(url_encode "$query")&maxResults=$limit&startAt=$start&fields=$(url_encode "$fields")")"
site_url="$(jira_site_url)"

jira_get_json "$api_url" |
  jq --arg query "$query" --argjson limit "$limit" --argjson start "$start" --arg siteUrl "$site_url" '
    def issue_url:
      if .key? then
        $siteUrl + "/browse/" + .key
      else
        null
      end;

    {
      query: $query,
      results: [
        (.issues // [])[]
        | {
            key,
            id,
            summary: (.fields.summary // null),
            status: (.fields.status.name // null),
            issueType: (.fields.issuetype.name // null),
            projectKey: (.fields.project.key // null),
            assignee: (.fields.assignee.displayName // null),
            reporter: (.fields.reporter.displayName // null),
            priority: (.fields.priority.name // null),
            updatedAt: (.fields.updated // null),
            url: issue_url
          }
      ],
      pagination: {
        startAt: (.startAt // $start),
        maxResults: (.maxResults // $limit),
        total: (.total // null),
        size: ((.issues // []) | length),
        hasMore: (((.startAt // $start) + (.maxResults // $limit)) < (.total // 0))
      }
    }
  '
