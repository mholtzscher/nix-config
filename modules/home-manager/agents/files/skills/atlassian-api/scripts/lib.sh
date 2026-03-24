#!/usr/bin/env bash

set -euo pipefail

die() {
  echo "Error: $*" >&2
  exit 1
}

need_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || die "Required environment variable is not set: $name"
}

url_encode() {
  [[ $# -gt 0 ]] || die "url_encode: missing argument"
  jq -rn --arg value "$1" '$value | @uri'
}

atlassian_escape() {
  local value="${1//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

cql_escape() {
  atlassian_escape "$1"
}

jql_escape() {
  atlassian_escape "$1"
}

join_by() {
  local delimiter="$1"
  shift || true

  local out=""
  local item
  for item in "$@"; do
    if [[ -z "$out" ]]; then
      out="$item"
    else
      out+="$delimiter$item"
    fi
  done

  printf '%s' "$out"
}

atlassian_base_url() {
  printf '%s' "${ATLASSIAN_BASE_URL%/}"
}

atlassian_email() {
  [[ -n "${ATLASSIAN_EMAIL:-}" ]] || die "ATLASSIAN_EMAIL is not set"
  printf '%s' "$ATLASSIAN_EMAIL"
}

atlassian_api_token() {
  [[ -n "${ATLASSIAN_API_TOKEN:-}" ]] || die "ATLASSIAN_API_TOKEN is not set"
  printf '%s' "$ATLASSIAN_API_TOKEN"
}

confluence_site_url() {
  printf '%s' "$(atlassian_base_url)"
}

jira_site_url() {
  printf '%s' "$(atlassian_base_url)"
}

confluence_api_root() {
  local base
  base="$(confluence_site_url)"

  if [[ "$base" == */wiki ]]; then
    printf '%s/rest/api' "$base"
  else
    printf '%s/wiki/rest/api' "$base"
  fi
}

jira_api_root() {
  printf '%s/rest/api/3' "$(jira_site_url)"
}

confluence_api_url() {
  local path="$1"
  printf '%s%s' "$(confluence_api_root)" "$path"
}

jira_api_url() {
  local path="$1"
  printf '%s%s' "$(jira_api_root)" "$path"
}

require_atlassian_env() {
  need_cmd curl
  need_cmd jq
  require_env ATLASSIAN_BASE_URL
  require_env ATLASSIAN_EMAIL
  require_env ATLASSIAN_API_TOKEN
}

require_confluence_env() {
  require_atlassian_env
}

require_jira_env() {
  require_atlassian_env
}

atlassian_get_json() {
  local url="$1"
  local service_name="$2"
  local body_file
  local status

  body_file="$(mktemp)"
  if ! status="$(curl -sS \
    --connect-timeout 10 \
    --max-time 60 \
    -u "$(atlassian_email):$(atlassian_api_token)" \
    -H 'Accept: application/json' \
    -o "$body_file" \
    -w '%{http_code}' \
    "$url")"; then
    rm -f "$body_file"
    die "Request to ${service_name} API failed"
  fi

  if [[ ! "$status" =~ ^2 ]]; then
    echo "HTTP $status from ${service_name} API" >&2
    if jq . "$body_file" >/dev/null 2>&1; then
      jq . "$body_file" >&2
    else
      cat "$body_file" >&2
    fi
    rm -f "$body_file"
    die "HTTP $status from ${service_name} API"
  fi

  cat "$body_file"
  rm -f "$body_file"
}

confluence_get_json() {
  local url="$1"
  atlassian_get_json "$url" "Confluence"
}

jira_get_json() {
  local url="$1"
  atlassian_get_json "$url" "Jira"
}
