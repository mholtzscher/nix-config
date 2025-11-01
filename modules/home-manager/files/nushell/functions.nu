# Helper: Require that a CLI tool is installed.
# Usage: _require_tool <tool-name> [custom error message]
# Returns exit code 1 if tool not found.
# This helper intentionally only log infos an error and returns 1 so it can be
# composed inside other functions without exiting the entire shell session.
# Callers should `return $in` (propagate) its non‑zero exit code if desired.
def _require_tool [tool: string, message?: string] {
  if (which $tool | is-empty) {
    error make --unspanned {msg: $"Required tool '($tool)' is not installed or not in PATH."}
  }
}

# Helper: Prompt user for confirmation before performing an action
# Usage: _confirm <message> [default_yes]
# Returns true if user confirms, false otherwise
# Example:
#   if (_confirm "Delete all files?") { rm * }
#   if (_confirm "Continue with upload?" true) { upload_file }
def _confirm [message: string, default_yes?: bool] {
  let default = if ($default_yes | default false) { "Y/n" } else { "y/N" }
  let prompt = $"($message) \(($default)\) "
  let response = (input $prompt | str trim | str downcase)

  if ($default_yes | default false) {
    # Default yes: accept empty, "y", "yes" 
    ($response == "" or $response == "y" or $response == "yes")
  } else {
    # Default no: only accept explicit "y", "yes"
    ($response == "y" or $response == "yes")
  }
}

# Test function to detect project type and run appropriate tests
def tst [] {
  if ("go.mod" | path exists) {
    log info "go.mod found. Running Go tests..."
    go test ./...
  } else if ("build.gradle" | path exists) or ("build.gradle.kts" | path exists) {
    log info "build.gradle found. Running ./gradlew test..."
    ./gradlew test
  } else {
    log warning "Neither go.mod nor build.gradle found in the current directory."
  }
}

# Format function to detect project type and run appropriate formatter
def fmt [] {
  if ("go.mod" | path exists) {
    log info "go.mod found. Running Go formatter..."
    go fmt ./...
  } else if ("build.gradle" | path exists) {
    log info "build.gradle found. Running ./gradlew spotlessApply..."
    run-external "./gradlew" "spotlessApply" "--parallel"
  } else {
    log warning "Neither go.mod nor build.gradle found in the current directory."
  }
}

# Format all Nix files recursively in current directory
def nf [] {
  let nix_files = (fd -e nix | lines)
  if ($nix_files | is-empty) {
    log warning "No .nix files found in current directory."
    return
  }

  log info $"Formatting ($nix_files | length) Nix files..."
  $nix_files | each {|file|
    log info $"Formatting ($file)"
    nixfmt $file
  }
  log info "Nix formatting complete."
}

# AWS profile management with SSO login
def --env aws_change_profile [profile?: string] {
  _require_tool aws
  _require_tool fzf

  let profile = if ($profile | is-empty) {
    aws configure list-profiles | fzf --prompt "Select AWS Profile:"
  } else {
    $profile
  }

  if ($profile | is-empty) {
    log warning "No profile selected"
    return 1
  }

  $env.AWS_PROFILE = $profile
  log info $"Using AWS profile: ($env.AWS_PROFILE)"

  if (aws configure get sso_start_url --profile $env.AWS_PROFILE | complete | get exit_code) != 0 {
    log error $"No SSO configuration found for profile: ($env.AWS_PROFILE)"
    return 1
  }

  let result = aws sts get-caller-identity | complete
  if ($result | get exit_code) == 0 {
    log info "Found valid AWS session"
    return 0
  }

  log info "Logging into AWS"
  let sso_result = aws sso login --profile $env.AWS_PROFILE | complete
  if ($sso_result | get exit_code) != 0 {
    log error "Failed to login to AWS SSO"
    log error ($sso_result | get stderr)
    return 1
  }
  return 0
}

# AWS logout function
def --env aws_logout [] {
  if (aws configure get sso_start_url --profile $env.AWS_PROFILE | complete | get exit_code) == 0 {
    aws sso logout
  }
  hide-env AWS_PROFILE
}

# Watch command - runs a command at specified intervals
def watch [interval: duration, ...command: string] {
  if ($command | is-empty) {
    log info "Usage: watch <interval> <command>"
    return 1
  }

  loop {
    clear
    run-external ...$command
    sleep $interval
  }
}

# Yazi with directory change support
def --env y [...args: string] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp | str trim)
  if ($cwd != "" and $cwd != $env.PWD) {
    cd $cwd
  }
  rm -f $tmp
}

# Gradle wrapper function
def gradle [...args: string] {
  if ("./gradlew" | path exists) {
    ./gradlew ...$args
  } else {
    log warning "No gradlew found"
  }
}

# SSH tunnel function
def __ssh_tunnel [key_file: string, local_port: string, endpoint: string, user_hostname: string] {
  ssh -i $key_file -v -N -L $"($local_port):($endpoint)" $user_hostname
}

# List active network interfaces and their IP addresses
# def ifactive [] {
#   networksetup -listallhardwareports 
#   | lines 
#   | where $it =~ "^Device:" 
#   | each { |line| 
#       let interface = ($line | split row " " | get 1)
#       let ip = (ipconfig getifaddr $interface | complete | get stdout | str trim)
#       if ($ip != "") {
#         $"($interface): ($ip)"
#       }
#     }
#   | where $it != null
# }
#
# # Add current directory and children to zoxide
# def zoxide_register_children [] {
#   let target_dir = $env.PWD
#   log info $"Adding current directory to zoxide: ($target_dir)"
#   zoxide add $target_dir
#
#   log info $"Scanning for child directories in: ($target_dir)"
#   let children = (fd --type d --maxdepth 1 . | lines | where $it != "")
#
#   if ($children | is-empty) {
#     log warning "No child directories found to add."
#   } else {
#     $children | each { |child_dir|
#       print $"\tAdding: ($child_dir)"
#       zoxide add $child_dir
#     }
#     log info $"Done. Added ($children | length) child directories to zoxide."
#   }
# }

# Chezmoi add with fzf selection
def chad [] {
  _require_tool fzf
  _require_tool bat
  _require_tool fd
  _require_tool chezmoi

  let selected_files = (fd -t f | fzf -m --height 60% --border --preview "bat --color=always --plain --line-range :50 {}" --preview-window "right:60%:wrap" | lines)
  if ($selected_files | is-empty) {
    log warning "No files selected."
    return
  }

  log info "The following files will be added to chezmoi:"
  $selected_files | each {|file| log info $"\t($file)" }

  if (_confirm "Proceed with 'chezmoi add'?" true) {
    log info "Adding files to chezmoi..."
    chezmoi add ...$selected_files
    log info "Files successfully added to chezmoi."
  } else {
    log warning "Operation cancelled by user."
  }
}

# Chezmoi forget with fzf selection
def chf [] {
  _require_tool fzf
  _require_tool bat
  _require_tool fd

  let selected_files = (fd -t f | fzf -m --height 60% --border --preview "bat --color=always --plain --line-range :50 {}" --preview-window "right:60%:wrap" | lines)

  if ($selected_files | is-empty) {
    log warning "No files selected."
    return
  }

  log info "The following files will be forgotten in chezmoi:"
  $selected_files | each {|file| print $"\t($file)" }

  if (_confirm "Proceed with 'chezmoi forget'?") {
    log info "Forgetting files in chezmoi..."
    chezmoi forget --force ...$selected_files
    log info "Files successfully forgotten in chezmoi."
  } else {
    log warning "Operation cancelled by user."
  }
}

# Restart Raycast
def raycast [] {
  log info "Attempting to restart Raycast..."

  let kill_result = (pkill -f Raycast | complete)
  if $kill_result.exit_code == 0 {
    log info "Raycast process found and terminated."
  } else {
    log warning "Raycast process not found or already terminated."
  }

  sleep 1sec

  let open_result = (^open -a Raycast | complete)
  if $open_result.exit_code == 0 {
    log info "Raycast launched successfully."
  } else {
    log error "Failed to launch Raycast. Make sure it's installed correctly."
  }
}

# Clear Cloudflare cache
def cloudcache [] {
  let api_token = (op item get cloudflare.com --fields cli-api-token --reveal | str trim)
  let zone_id = (op item get cloudflare.com --fields zone-holtzscher-com | str trim)
  let email = (op item get cloudflare.com --fields username | str trim)
  let url = $"https://api.cloudflare.com/client/v4/zones/($zone_id)/purge_cache"

  log info $"Purging Cloudflare cache for ZONE_ID: ($zone_id)"
  http post --content-type application/json -H {"X-Auth-Email": $email "Authorization": $"Bearer ($api_token)"} $url {"purge_everything": true}
}

# Select and launch Neovim with specific configuration
def nv [...args: string] {
  let config_dir = $"($env.HOME)/.config"
  let configs = (fd --type d --maxdepth 1 "nvim*" $config_dir | lines | each {|path| $path | path basename } | sort)

  if ($configs | is-empty) {
    log warning $"No Neovim configurations found in ($config_dir)"
    return
  }

  let selected_config = ($configs | str join "\n" | fzf --prompt="Select Neovim config: " --height=40% --border)
  # let selected_config = ($configs | input list --fuzzy "Select Neovim config: ")

  if ($selected_config | is-not-empty) {
    with-env {NVIM_APPNAME: $selected_config} { nvim ...$args }
  }
}

# Set GitHub PAT from 1Password or macOS Keychain
def --env pat [] {
  let serviceName = "github-packages-pat"
  if (which op | is-not-empty) {
    # TODO: update to use personal pat here
    $env.GITHUB_PAT = (op read "op://Personal/Github/paytient-pat")
  } else {
    $env.GITHUB_PAT = (security find-generic-password -s $serviceName -w | str trim)
  }
}

# Set Tonic Dump Password from macOS Keychain
def --env tonic [] {
  let serviceName = "tonic-dump"
  $env.POSTGRES_DUMP_PASSWORD = (security find-generic-password -s $serviceName -w | str trim)
}

# AWS export environment variables
def --env aws_export_envs [] {
  let credentials = (aws configure export-credentials --profile $env.AWS_PROFILE --format env-no-export | complete | get stdout | lines)
  $credentials | each {|line|
    if ($line | str contains "=") {
      let parts = ($line | split row "=" | str trim)
      if ($parts | length) >= 2 {
        let key = ($parts | first)
        let value = ($parts | skip 1 | str join "=")
        load-env {$key: $value}
      }
    }
  }
}

# Create directory and cd into it
export def --env mkcd [path: string] {
  if not ($path | path exists) {
    mkdir $path
  }
  cd $path
}

# Platform-aware Nix build/validate command
# On macOS: darwin-rebuild build
# On Linux: nix flake check
export def nb [] {
  if ($nu.os-info.name == "linux") {
    nix flake check --flake ~/.config/nix-config
  } else if ($nu.os-info.name == "macos") {
    darwin-rebuild build --flake ~/.config/nix-config
  } else {
    log error "Unsupported OS: ($nu.os-info.name)"
    return 1
  }
}

# Platform-aware Nix apply/switch command
# On macOS: sudo darwin-rebuild switch
# On Linux: sudo nixos-rebuild switch --flake ~/.config/nix-config#desktop
export def nup [] {
  if ($nu.os-info.name == "linux") {
    sudo nixos-rebuild switch --flake ~/.config/nix-config#desktop
  } else if ($nu.os-info.name == "macos") {
    sudo darwin-rebuild switch --flake ~/.config/nix-config
  } else {
    log error "Unsupported OS: ($nu.os-info.name)"
    return 1
  }
}

# Adjust aerospace workspace percentage by increment/decrement
# Usage: aerospace_workspace_adjust 5       # Increment by 5%
#        aerospace_workspace_adjust -5      # Decrement by 5%
#        aerospace_workspace_adjust         # Increment by default 5%
export def aerospace_workspace_adjust [amount?: int] {
  let adjustment = $amount | default 5
  let percentage_file = $"($env.HOME)/.config/aerospace/workspace-size-percentage.txt"
  
  if not ($percentage_file | path exists) {
    log error "Workspace percentage file not found at ($percentage_file)"
    log info "Please run 'aerospace_workspace_size <percentage>' first to initialize"
    return 1
  }
  
  let current_percentage = (open $percentage_file | into int)
  let new_percentage = ($current_percentage + $adjustment)
  
  if ($new_percentage < 1 or $new_percentage > 100) {
    log error $"Invalid percentage after adjustment: ($new_percentage). Must be between 1 and 100"
    return 1
  }
  
  log info $"Adjusting workspace from ($current_percentage)% to ($new_percentage)% \(adjustment: ($adjustment)%\)"
  aerospace_workspace_size $new_percentage
}

# Update aerospace gaps based on percentage of monitor to use for workspace
# Usage: aerospace_workspace_size 40  # Uses center 40% of monitor for workspace
#        aerospace_workspace_size     # Uses percentage from ~/.config/aerospace/workspace-size-percentage.txt
export def aerospace_workspace_size [percentage?: int] {
  if (which aerospace | is-empty) {
    log error "Aerospace is not installed"
    return 1
  }

  # If no percentage provided, try to read from file
  let percentage = if ($percentage | is-empty) {
    let percentage_file = $"($env.HOME)/.config/aerospace/workspace-size-percentage.txt"
    if not ($percentage_file | path exists) {
      log info "No percentage provided and no saved percentage file found"
      return
    }
    (open $percentage_file | into int)
  } else {
    $percentage
  }
  
  if ($percentage < 1 or $percentage > 100) {
    log error "Percentage must be between 1 and 100"
    return 1
  }
  
  # Get the main monitor width using system_profiler
  let display_info = (system_profiler SPDisplaysDataType | complete)
  if $display_info.exit_code != 0 {
    log error "Failed to get display information"
    return 1
  }
  
  # Parse the output to find the main display's resolution
  # We need to find "Main Display: Yes" and then look backwards for the Resolution line
  let lines = ($display_info.stdout | lines)
  
  # Find the index of "Main Display: Yes"
  let main_display_index = ($lines | enumerate | where $it.item =~ "Main Display: Yes" | get index.0?)
  
  if ($main_display_index | is-empty) {
    log error "Could not find main display"
    return 1
  }
  
  # Look backwards from main display line to find the resolution
  # (Resolution comes a few lines before "Main Display: Yes")
  let resolution_line = ($lines | take ($main_display_index + 1) | where $it =~ "Resolution:" | last)
  
  if ($resolution_line | is-empty) {
    log error "Could not find resolution for main display"
    return 1
  }
  
  # Parse resolution - handle both "Resolution: 3456 x 2234" and "Resolution: 3456 x 2234 Retina"
  let parsed = ($resolution_line | str trim | parse --regex 'Resolution:\s+(?P<width>\d+)\s+x\s+(?P<height>\d+)')
  
  if ($parsed | is-empty) {
    log error "Could not parse monitor width from resolution line"
    return 1
  }
  
  let monitor_width = ($parsed | get width.0 | into int)
  
  # Calculate gap size to achieve the desired percentage
  # If user wants 40% workspace, then 60% should be gaps (30% on each side)
  let workspace_percentage = ($percentage / 100.0)
  let gap_percentage = (1.0 - $workspace_percentage) / 2.0
  let gap_size = (($monitor_width * $gap_percentage) | math round)
  
  let config_file = $"($env.HOME)/.config/aerospace/aerospace.toml"
  
  if not ($config_file | path exists) {
    log error $"Config file not found: ($config_file)"
    return 1
  }
  
  open $config_file 
    | update gaps.outer.right.1.monitor.main $gap_size 
    | update gaps.outer.left.1.monitor.main $gap_size
    | to toml 
    | save -f $config_file
  
  # Save the current percentage to a text file
  let percentage_file = $"($env.HOME)/.config/aerospace/workspace-size-percentage.txt"
  $percentage | save -f $percentage_file
  
  log info $"Set gaps to use center ($percentage)% of main monitor \(($gap_size)px per side, monitor width: ($monitor_width)px\)"
  log info $"Saved workspace percentage to ($percentage_file)"
  
  let reload_result = (aerospace reload-config | complete)
  if $reload_result.exit_code != 0 {
    log warning "Aerospace is not running or reload-config failed. Config updated but Aerospace not reloaded."
    return "Aerospace doesn't seem to be running..."
  }
  return "Completed."
}

# Theme settings
$env.config.color_config =  {
  binary: '#bb9af7'
  block: '#7aa2f7'
  cell-path: '#a9b1d6'
  closure: '#7dcfff'
  custom: '#c0caf5'
  duration: '#e0af68'
  float: '#f7768e'
  glob: '#c0caf5'
  int: '#bb9af7'
  list: '#7dcfff'
  nothing: '#f7768e'
  range: '#e0af68'
  record: '#7dcfff'
  string: '#9ece6a'

  bool: {|| if $in { '#7dcfff' } else { '#e0af68' } }

  datetime: {||
    (date now) - $in | if $in < 1hr {
      {fg: '#f7768e' attr: 'b'}
    } else if $in < 6hr {
      '#f7768e'
    } else if $in < 1day {
      '#e0af68'
    } else if $in < 3day {
      '#9ece6a'
    } else if $in < 1wk {
      {fg: '#9ece6a' attr: 'b'}
    } else if $in < 6wk {
      '#7dcfff'
    } else if $in < 52wk {
      '#7aa2f7'
    } else { 'dark_gray' }
  }

  filesize: {|e|
    if $e == 0b {
      '#a9b1d6'
    } else if $e < 1mb {
      '#7dcfff'
    } else { {fg: '#7aa2f7'} }
  }

  shape_and: {fg: '#bb9af7' attr: 'b'}
  shape_binary: {fg: '#bb9af7' attr: 'b'}
  shape_block: {fg: '#7aa2f7' attr: 'b'}
  shape_bool: '#7dcfff'
  shape_closure: {fg: '#7dcfff' attr: 'b'}
  shape_custom: '#9ece6a'
  shape_datetime: {fg: '#7dcfff' attr: 'b'}
  shape_directory: '#7dcfff'
  shape_external: '#7dcfff'
  shape_external_resolved: '#7dcfff'
  shape_externalarg: {fg: '#9ece6a' attr: 'b'}
  shape_filepath: '#7dcfff'
  shape_flag: {fg: '#7aa2f7' attr: 'b'}
  shape_float: {fg: '#f7768e' attr: 'b'}
  shape_garbage: {fg: '#FFFFFF' bg: '#FF0000' attr: 'b'}
  shape_glob_interpolation: {fg: '#7dcfff' attr: 'b'}
  shape_globpattern: {fg: '#7dcfff' attr: 'b'}
  shape_int: {fg: '#bb9af7' attr: 'b'}
  shape_internalcall: {fg: '#7dcfff' attr: 'b'}
  shape_keyword: {fg: '#bb9af7' attr: 'b'}
  shape_list: {fg: '#7dcfff' attr: 'b'}
  shape_literal: '#7aa2f7'
  shape_match_pattern: '#9ece6a'
  shape_matching_brackets: {attr: 'u'}
  shape_nothing: '#f7768e'
  shape_operator: '#e0af68'
  shape_or: {fg: '#bb9af7' attr: 'b'}
  shape_pipe: {fg: '#bb9af7' attr: 'b'}
  shape_range: {fg: '#e0af68' attr: 'b'}
  shape_raw_string: {fg: '#c0caf5' attr: 'b'}
  shape_record: {fg: '#7dcfff' attr: 'b'}
  shape_redirection: {fg: '#bb9af7' attr: 'b'}
  shape_signature: {fg: '#9ece6a' attr: 'b'}
  shape_string: '#9ece6a'
  shape_string_interpolation: {fg: '#7dcfff' attr: 'b'}
  shape_table: {fg: '#7aa2f7' attr: 'b'}
  shape_vardecl: {fg: '#7aa2f7' attr: 'u'}
  shape_variable: '#bb9af7'

  foreground: '#c0caf5'
  background: '#1a1b26'
  cursor: '#c0caf5'

  empty: '#7aa2f7'
  header: {fg: '#9ece6a' attr: 'b'}
  hints: '#414868'
  leading_trailing_space_bg: {attr: 'n'}
  row_index: {fg: '#9ece6a' attr: 'b'}
  search_result: {fg: '#f7768e' bg: '#a9b1d6'}
  separator: '#a9b1d6'
}
