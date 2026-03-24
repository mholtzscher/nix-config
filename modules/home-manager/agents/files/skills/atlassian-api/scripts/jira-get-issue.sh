#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/jira-get-issue.sh DEV-123
  ./scripts/jira-get-issue.sh DEV-123 --format rendered
  ./scripts/jira-get-issue.sh DEV-123 --format raw
  ./scripts/jira-get-issue.sh DEV-123 --comments
  ./scripts/jira-get-issue.sh DEV-123 --body-only

Options:
  --format <fmt>  Description format to fetch: text, raw, or rendered. Default: text.
  --comments      Include normalized comments in the output.
  --body-only     Print only the selected description content.
  -h, --help      Show this help.
EOF
}

format="text"
include_comments=0
body_only=0
issue_key=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      [[ $# -ge 2 ]] || die "Missing value for --format"
      format="$2"
      shift 2
      ;;
    --comments)
      include_comments=1
      shift
      ;;
    --body-only)
      body_only=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown argument: $1"
      ;;
    *)
      if [[ -n "$issue_key" ]]; then
        die "Only one issue key may be provided"
      fi
      issue_key="$1"
      shift
      ;;
  esac
done

[[ -n "$issue_key" ]] || die "An issue key is required"
case "$format" in
  text|raw|rendered) ;;
  *) die "--format must be one of: text, raw, rendered" ;;
esac

require_jira_env

fields="summary,description,status,issuetype,project,assignee,reporter,priority,created,updated"
if (( include_comments )); then
  fields+=",comment"
fi

api_url="$(jira_api_url "/issue/$(url_encode "$issue_key")?fields=$(url_encode "$fields")&expand=$(url_encode "renderedFields")")"
site_url="$(jira_site_url)"

jq_filter="$(cat <<'JQ'
  def normalize_text:
    gsub("\r"; "")
    | gsub("[ \t]+\n"; "\n")
    | gsub("\n{3,}"; "\n\n")
    | ltrimstr("\n")
    | rtrimstr("\n");

  def adf_text:
    if . == null then
      ""
    elif type == "string" then
      .
    elif type == "array" then
      map(adf_text) | join("")
    elif type == "object" then
      if .type? == "text" then
        .text // ""
      elif .type? == "hardBreak" then
        "\n"
      elif .type? == "paragraph" then
        ((.content // []) | adf_text) + "\n\n"
      elif .type? == "heading" then
        ((.content // []) | adf_text) + "\n\n"
      elif .type? == "blockquote" then
        ((.content // []) | adf_text) + "\n\n"
      elif .type? == "bulletList" or .type? == "orderedList" then
        ((.content // []) | adf_text) + "\n"
      elif .type? == "listItem" then
        "- " + ((.content // []) | adf_text)
      elif .type? == "codeBlock" then
        ((.content // []) | adf_text) + "\n\n"
      elif .type? == "mention" then
        (.attrs.text // .attrs.id // "")
      elif .type? == "emoji" then
        (.attrs.text // .attrs.shortName // "")
      elif .type? == "inlineCard" or .type? == "blockCard" then
        (.attrs.url // "")
      else
        (.content? // []) | adf_text
      end
    else
      ""
    end;

  def description_value:
    if $requestedFormat == "raw" then
      .fields.description
    elif $requestedFormat == "rendered" then
      (.renderedFields.description // null)
    else
      ((.fields.description | adf_text) | normalize_text)
    end;

  def comment_value:
    if $requestedFormat == "raw" then
      .body
    else
      ((.body | adf_text) | normalize_text)
    end;

  def issue_url:
    $siteUrl + "/browse/" + .key;

  if $bodyOnly == 1 then
    description_value
  else
    {
      issue: {
        key,
        id,
        summary: (.fields.summary // null),
        status: (.fields.status.name // null),
        issueType: (.fields.issuetype.name // null),
        projectKey: (.fields.project.key // null),
        assignee: (.fields.assignee.displayName // null),
        reporter: (.fields.reporter.displayName // null),
        priority: (.fields.priority.name // null),
        createdAt: (.fields.created // null),
        updatedAt: (.fields.updated // null),
        url: issue_url
      },
      descriptionFormat: $requestedFormat,
      description: description_value,
      comments: if $includeComments == 1 then
        [
          (.fields.comment.comments // [])[]
          | {
              id,
              author: (.author.displayName // null),
              createdAt: (.created // null),
              updatedAt: (.updated // null),
              body: comment_value
            }
        ]
      else
        null
      end
    }
  end
JQ
)"

if (( body_only )) && [[ "$format" != "raw" ]]; then
  jira_get_json "$api_url" |
    jq -r --arg requestedFormat "$format" --argjson includeComments "$include_comments" --argjson bodyOnly "$body_only" --arg siteUrl "$site_url" "$jq_filter"
else
  jira_get_json "$api_url" |
    jq --arg requestedFormat "$format" --argjson includeComments "$include_comments" --argjson bodyOnly "$body_only" --arg siteUrl "$site_url" "$jq_filter"
fi
