#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/confluence-get-content.sh <page-id>
  ./scripts/confluence-get-content.sh <page-id> --format view
  ./scripts/confluence-get-content.sh <page-id> --format storage
  ./scripts/confluence-get-content.sh <page-id> --body-only

Options:
  --format <fmt>  Body format to fetch: text, view, html, or storage. Default: text.
  --body-only     Print only the selected body content.
  -h, --help      Show this help.
EOF
}

format="text"
body_only=0
page_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      [[ $# -ge 2 ]] || die "Missing value for --format"
      format="$2"
      shift 2
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
      if [[ -n "$page_id" ]]; then
        die "Only one page ID may be provided"
      fi
      page_id="$1"
      shift
      ;;
  esac
done

[[ -n "$page_id" ]] || die "A page ID is required"
case "$format" in
  text|view|html|storage) ;;
  *) die "--format must be one of: text, view, html, storage" ;;
esac

require_confluence_env

api_url="$(confluence_api_url "/content/$page_id?expand=$(url_encode "space,version,metadata.labels,body.storage,body.view")")"

jq_filter="$(cat <<'JQ'
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

  def html_to_text:
    gsub("(?i)<br */?>"; "\n")
    | gsub("(?i)</p>"; "\n\n")
    | gsub("(?i)</div>"; "\n")
    | gsub("(?i)</li>"; "\n")
    | gsub("(?i)<li[^>]*>"; "- ")
    | gsub("(?i)</tr>"; "\n")
    | gsub("(?i)</t[dh]>"; "\t")
    | gsub("(?s)<[^>]*>"; "")
    | gsub("&nbsp;"; " ")
    | gsub("&amp;"; "&")
    | gsub("&lt;"; "<")
    | gsub("&gt;"; ">")
    | gsub("&quot;"; "\"")
    | gsub("&#39;"; "'")
    | gsub("\r"; "")
    | gsub("[ \t]+"; " ")
    | gsub(" *\n *"; "\n")
    | gsub("\n{3,}"; "\n\n")
    | ltrimstr("\n")
    | rtrimstr("\n");

  def resolved_format:
    if $requestedFormat == "html" then "view" else $requestedFormat end;

  def body_value:
    if resolved_format == "storage" then
      .body.storage.value
    elif resolved_format == "view" then
      .body.view.value
    else
      (.body.view.value | html_to_text)
    end;

  if $bodyOnly == 1 then
    body_value
  else
    {
      page: {
        id,
        title,
        type: (.type // "page"),
        status: (.status // null),
        spaceKey: (.space.key // null),
        version: (.version.number // null),
        updatedAt: (.version.when // null),
        url: page_url,
        labels: normalized_labels
      },
      bodyFormat: resolved_format,
      body: body_value
    }
  end
JQ
)"

if (( body_only )); then
  confluence_get_json "$api_url" |
    jq -r --arg requestedFormat "$format" --argjson bodyOnly "$body_only" "$jq_filter"
else
  confluence_get_json "$api_url" |
    jq --arg requestedFormat "$format" --argjson bodyOnly "$body_only" "$jq_filter"
fi
