# Kitty sessionizer — replaces zellij zsm plugin
# Provides an interactive fzf picker to open projects in new kitty tabs.
#
# Usage:
#   ks              # Run from inside kitty (uses kitty @ remote control)
#   alt+f           # Kitty keybinding that spawns a picker window

# Find git repositories and immediate subdirectories under base paths
# to build the list of "projects" to pick from.
def __ks_find_projects [] {
  let base_paths = [
    $"($env.HOME)/code"
    $"($env.HOME)/.config"
    $"($env.HOME)"
  ] | where {|p| $p | path exists }

  if ($base_paths | is-empty) {
    return []
  }

  $base_paths | each {|base|
    # max-depth 2 finds both the base children and grandchildren,
    # which covers ~/code, ~/code/vibes, ~/code/paytient, etc.
    ^fd --max-depth 2 --type d --hidden --exclude ".git" --exclude "node_modules" --exclude ".nix-profile" --exclude ".local" --exclude "Library" . $base
    | lines
  } | flatten | uniq | sort
}

# Main sessionizer entrypoint.
# Picks a directory with fzf and opens it in kitty.
export def ks [] {
  _require_tool fzf
  _require_tool fd

  let choices = __ks_find_projects
  if ($choices | is-empty) {
    log warning "No projects found in base paths"
    return
  }

  let selected = (
    $choices | str join "\n"
    | fzf --height="60%" --border
          --prompt="kitty session: "
          --preview "ls -la {}"
    | str trim
  )

  if ($selected | is-empty) {
    # User cancelled — if we are in a dedicated picker window, close it.
    if ($env.KITTY_WINDOW_ID? | is-not-empty) {
      kitty @ close-window --match id:($env.KITTY_WINDOW_ID) | ignore
    }
    return
  }

  let session_name = ($selected | path basename)
  let session_file = $"($env.HOME)/.config/kitty/sessions/($session_name).session"

  # Persist a session file so the project can also be launched standalone
  # with: kitty --session ~/.config/kitty/sessions/<name>.session
  $"new_tab ($session_name)\ncd ($selected)\nlaunch nu\n"
  | save --force $session_file

  # If running inside a kitty with remote control enabled, open a new tab
  # in the same kitty instance and close the picker window.
  if ($env.KITTY_LISTEN_ON? | is-not-empty) {
    let launch_result = (
      kitty @ launch --type=tab --cwd $selected --tab-title $session_name
      | complete
    )

    if $launch_result.exit_code == 0 {
      log info $"Opened '($session_name)' in new kitty tab"

      # Close the picker window if we know our window id.
      if ($env.KITTY_WINDOW_ID? | is-not-empty) {
        kitty @ close-window --match id:($env.KITTY_WINDOW_ID) | ignore
      }
      return
    } else {
      log warning $"kitty @ launch failed: ($launch_result.stderr)"
    }
  }

  # Fallback: start a fresh kitty OS window for the project.
  log info $"Launching new kitty window for '($session_name)'"
  bash -c $"kitty --session ($session_file) > /dev/null 2>&1 &"
}
