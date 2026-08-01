def herdr-nix-status-enabled [] {
  (($env.HERDR_ENV? | default "") == "1") and (($env.HERDR_PANE_ID? | default "") != "")
}

def herdr-nix-command [command: string] {
  let command = ($command | str trim | str replace --all --regex '\s+' ' ')
  $command =~ '(^|[;&|]\s*)(sudo\s+)?(nix\s+build|nix-build|nh\s+(os|darwin|home)\s+(build|switch)|nixos-rebuild\s+(build|switch)|darwin-rebuild\s+(build|switch)|home-manager\s+(build|switch)|nb|nup)(\s|$)'
}

def herdr-nix-report [state: string] {
  if not (herdr-nix-status-enabled) {
    return
  }

  do { ^herdr pane report-metadata $env.HERDR_PANE_ID --source "user:nix-status" --agent nix --display-agent Nix --state-label "working=building" --state-label "blocked=password required" --state-label "idle=succeeded" --state-label "done=succeeded" --state-label "unknown=failed" } | complete | ignore

  do { ^herdr pane report-agent $env.HERDR_PANE_ID --source "user:nix-status" --agent nix --state $state } | complete | ignore
}

def --env herdr-nix-pre-execution [command: string] {
  if not (herdr-nix-status-enabled) {
    return
  }

  if (herdr-nix-command $command) {
    $env.HERDR_NIX_STATUS = "running"
    herdr-nix-report working
  } else if (($env.HERDR_NIX_STATUS? | default "") != "") {
    do { ^herdr pane release-agent $env.HERDR_PANE_ID --source "user:nix-status" --agent nix } | complete | ignore
    hide-env HERDR_NIX_STATUS
  }
}

def --env herdr-nix-pre-prompt [exit_code: int] {
  if (($env.HERDR_NIX_STATUS? | default "") != "running") {
    return
  }

  if $exit_code == 0 {
    herdr-nix-report idle
  } else {
    herdr-nix-report unknown
  }
  $env.HERDR_NIX_STATUS = "finished"
}

# Pre-authorize privileged nh switches so Herdr can distinguish a password
# prompt from build activity. The external command remains authoritative.
def --wrapped nh [...args] {
  let privileged_switch = (
    ($args | length) >= 2
    and (($args | get 0) in ["os" "darwin"])
    and (($args | get 1) == "switch")
  )

  if $privileged_switch and (herdr-nix-status-enabled) {
    let cached = (do { ^sudo -n true } | complete)
    if $cached.exit_code != 0 {
      herdr-nix-report blocked
      ^sudo -v
      if $env.LAST_EXIT_CODE != 0 {
        return
      }
      herdr-nix-report working
    }
  }

  ^nh ...$args
}

$env.config.hooks.pre_execution = (
  $env.config.hooks.pre_execution
  | append {|| herdr-nix-pre-execution (commandline) }
)
$env.config.hooks.pre_prompt = (
  $env.config.hooks.pre_prompt
  | append {|| herdr-nix-pre-prompt ($env.LAST_EXIT_CODE? | default 0) }
)
