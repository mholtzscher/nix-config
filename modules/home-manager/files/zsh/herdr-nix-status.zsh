autoload -Uz add-zsh-hook

typeset -g HERDR_NIX_STATUS=

_herdr_nix_status_enabled() {
  [[ ${HERDR_ENV:-} == 1 && -n ${HERDR_PANE_ID:-} ]]
}

_herdr_nix_command() {
  [[ $1 =~ '(^|[;&|][[:space:]]*)(sudo[[:space:]]+)?(nix[[:space:]]+build|nix-build|nh[[:space:]]+(os|darwin|home)[[:space:]]+(build|switch)|nixos-rebuild[[:space:]]+(build|switch)|darwin-rebuild[[:space:]]+(build|switch)|home-manager[[:space:]]+(build|switch)|nb|nup)([[:space:]]|$)' ]]
}

_herdr_nix_report() {
  _herdr_nix_status_enabled || return 0

  command herdr pane report-metadata "$HERDR_PANE_ID" \
    --source user:nix-status \
    --agent nix \
    --display-agent Nix \
    --state-label working=building \
    --state-label blocked='password required' \
    --state-label idle=succeeded \
    --state-label done=succeeded \
    --state-label unknown=failed \
    >/dev/null 2>&1

  command herdr pane report-agent "$HERDR_PANE_ID" \
    --source user:nix-status \
    --agent nix \
    --state "$1" \
    >/dev/null 2>&1
}

_herdr_nix_preexec() {
  _herdr_nix_status_enabled || return 0

  if _herdr_nix_command "$1"; then
    HERDR_NIX_STATUS=running
    _herdr_nix_report working
  elif [[ -n $HERDR_NIX_STATUS ]]; then
    command herdr pane release-agent "$HERDR_PANE_ID" \
      --source user:nix-status \
      --agent nix \
      >/dev/null 2>&1
    HERDR_NIX_STATUS=
  fi
}

_herdr_nix_precmd() {
  local exit_code=$?
  [[ $HERDR_NIX_STATUS == running ]] || return 0

  if (( exit_code == 0 )); then
    _herdr_nix_report idle
  else
    _herdr_nix_report unknown
  fi
  HERDR_NIX_STATUS=finished
}

# Pre-authorize privileged nh switches so Herdr can distinguish a password
# prompt from build activity. The external command remains authoritative.
nh() {
  if [[ ${1:-} == (os|darwin) && ${2:-} == switch ]] && _herdr_nix_status_enabled; then
    if ! command sudo -n true >/dev/null 2>&1; then
      _herdr_nix_report blocked
      command sudo -v || return $?
      _herdr_nix_report working
    fi
  fi

  command nh "$@"
}

add-zsh-hook preexec _herdr_nix_preexec
add-zsh-hook precmd _herdr_nix_precmd
