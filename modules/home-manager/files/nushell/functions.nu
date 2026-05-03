# Helper: Require that a CLI tool is installed.
# Usage: _require_tool <tool-name> [custom error message]
# Returns exit code 1 if tool not found.
# This helper intentionally only log infos an error and returns 1 so it can be
# composed inside other functions without exiting the entire shell session.
# Callers should `return $in` (propagate) its non‑zero exit code if desired.
def _require_tool [tool: string message?: string] {
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
def _confirm [message: string default_yes?: bool] {
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
def watch [interval: duration ...command: string] {
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

# Gradle wrapper function
def gradle [...args: string] {
  if ("./gradlew" | path exists) {
    ./gradlew ...$args
  } else {
    log warning "No gradlew found"
  }
}


# SSH tunnel function
def __ssh_tunnel [key_file: string local_port: string endpoint: string user_hostname: string] {
  ssh -i $key_file -v -N -L $"($local_port):($endpoint)" $user_hostname
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
    $env.GITHUB_PAT = (op read "op://Personal/Github/personal-access-token")
    $env.GITHUB_TOKEN = (op read "op://Personal/Github/personal-access-token")
  } else {
    $env.GITHUB_PAT = (security find-generic-password -s $serviceName -w | str trim)
    $env.GITHUB_TOKEN = (security find-generic-password -s $serviceName -w | str trim)
    $env.HOMEBREW_GITHUB_API_TOKEN = (security find-generic-password -s $serviceName -w | str trim)
  }
}

# Set/update GitHub PAT token in 1Password or macOS Keychain
# Usage: pat_set                    # Prompts for token (hidden input)
#        pat_set <token>            # Sets token directly (not recommended - visible in history)
#        pat_set --from-clipboard   # Sets token from clipboard
export def pat_set [
  token?: string # Optional token to set (prefer interactive input)
  --from-clipboard (-c) # Read token from clipboard
  --service-name (-s): string # Keychain service name (default: "github-packages-pat")
  --op-vault (-v): string # 1Password vault name (default: "Personal")
  --op-item (-i): string # 1Password item name (default: "Github")
  --op-field (-f): string # 1Password field name (default: "personal-access-token")
] {
  let serviceName = $service_name | default "github-packages-pat"
  let opVault = $op_vault | default "Personal"
  let opItem = $op_item | default "Github"
  let opField = $op_field | default "personal-access-token"

  # Determine token source
  let pat_token = if $from_clipboard {
    # Read from clipboard
    if (which pbpaste | is-not-empty) {
      let pbpaste_result = (pbpaste | complete)
      if $pbpaste_result.exit_code != 0 or ($pbpaste_result.stdout | str trim | is-empty) {
        log error "Failed to read from clipboard or clipboard is empty"
        return 1
      }
      log info "Reading PAT from clipboard..."
      $pbpaste_result.stdout | str trim
    } else {
      log error "pbpaste not found. Use interactive input instead (run without --from-clipboard)"
      return 1
    }
  } else if ($token | is-not-empty) {
    log warning "Setting token via command line argument is not recommended (visible in shell history)"
    $token
  } else {
    # Prompt for token with hidden input
    print "Enter GitHub Personal Access Token (input hidden): "
    let input_token = (input --suppress-output)
    if ($input_token | is-empty) {
      log error "No token provided"
      return 1
    }
    $input_token
  }

  # Validate token format (basic check - should start with ghp_, github_pat_, or gho_)
  if not ($pat_token | str starts-with "ghp_") and not ($pat_token | str starts-with "github_pat_") and not ($pat_token | str starts-with "gho_") {
    log warning "Token doesn't match expected GitHub PAT format (should start with 'ghp_', 'github_pat_', or 'gho_')"
    if not (_confirm "Continue anyway?") {
      log warning "Operation cancelled"
      return 1
    }
  }

  # Store in 1Password if available, otherwise use macOS Keychain
  if (which op | is-not-empty) {
    log info "Storing PAT in 1Password..."

    # Check if op is signed in
    let signin_check = (op account list | complete)
    if $signin_check.exit_code != 0 {
      log error "1Password CLI is not signed in. Run 'eval $(op signin)' first"
      return 1
    }

    # Update the token in 1Password using the assignment syntax
    let op_result = (op item edit $opItem --vault $opVault $"($opField)[password]=($pat_token)" | complete)

    if $op_result.exit_code == 0 {
      log info $"Successfully stored PAT in 1Password \(op://($opVault)/($opItem)/($opField)\)"
    } else {
      log error "Failed to store PAT in 1Password"
      log error $op_result.stderr
      return 1
    }
  } else if (which security | is-not-empty) {
    log info "Storing PAT in macOS Keychain..."

    # Check if entry exists
    let check_result = (security find-generic-password -s $serviceName | complete)

    if $check_result.exit_code == 0 {
      # Update existing entry
      log info $"Updating existing keychain entry: ($serviceName)"
      let delete_result = (security delete-generic-password -s $serviceName | complete)

      if $delete_result.exit_code != 0 {
        log error "Failed to delete existing keychain entry"
        log error $delete_result.stderr
        return 1
      }
    }

    # Add new entry (username is arbitrary for a token)
    let add_result = (security add-generic-password -s $serviceName -a "github-pat" -w $pat_token | complete)

    if $add_result.exit_code == 0 {
      log info $"Successfully stored PAT in macOS Keychain \(service: ($serviceName)\)"
    } else {
      log error "Failed to store PAT in macOS Keychain"
      log error $add_result.stderr
      return 1
    }
  } else {
    log error "Neither 1Password CLI (op) nor macOS security command found"
    log error "Cannot store PAT securely"
    return 1
  }

  return 0
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

# Platform-aware Nix flake update command
# On macOS: updates flake at ~/.config/nix-config
# On Linux: updates flake at ~/nix-config
export def nfu [] {
  if ($nu.os-info.name == "linux") {
    nix flake update --flake ~/nix-config
  } else if ($nu.os-info.name == "macos") {
    nix flake update --flake ~/.config/nix-config
  } else {
    log error "Unsupported OS: ($nu.os-info.name)"
    return 1
  }
}

# AI-powered conventional commit using pi
# Analyzes staged changes and generates a conventional commit message
# Usage: ai_commit          # With confirmation prompt
#        ai_commit --yes    # Skip confirmation (auto-commit)
export def ai_commit [
  --yes (-y) # Skip confirmation and commit immediately
] {
  _require_tool git
  _require_tool pi

  # Check if we're in a git repository
  let git_check = (git rev-parse --is-inside-work-tree | complete)
  if $git_check.exit_code != 0 {
    log error "Not in a git repository"
    return 1
  }

  # Check if there are staged changes
  let staged_diff = (git diff --staged)
  if ($staged_diff | is-empty) {
    log warning "No staged changes to commit"
    log info "Use 'git add' to stage files first"
    return 1
  }

  let model = "opencode-go/deepseek-v4-flash"
  log info $"Analyzing staged changes with AI using pi and ($model)..."

  # Use pi in print mode to analyze the diff and generate a commit message.
  let commit_prompt = $"Analyze the following staged git diff and create a conventional commit message that best describes the changes:

Staged changes:
```($staged_diff)
```

Return ONLY the commit message, nothing else. No explanations, no markdown code blocks, just the commit message text."

  let pi_result = (pi -p --no-session --no-tools --model $model $commit_prompt | complete)

  if $pi_result.exit_code != 0 {
    log error "Failed to generate commit message with pi"
    log error $pi_result.stderr
    return
  }

  let commit_message = ($pi_result.stdout | str trim)

  if ($commit_message | is-empty) {
    log error "pi returned an empty commit message"
    return
  }

  # Show the generated commit message
  print "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print "Generated commit message:"
  print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  print $commit_message
  print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"

  # Ask for confirmation unless --yes flag is provided
  let should_commit = if $yes {
    true
  } else {
    _confirm "Create commit with this message?" true
  }

  if $should_commit {
    let commit_result = (git commit -m $commit_message | complete)

    if $commit_result.exit_code == 0 {
      log info "Commit created successfully!"
      print $commit_result.stdout
      return
    } else {
      log error "Failed to create commit"
      log error $commit_result.stderr
      return
    }
  } else {
    log warning "Commit cancelled by user"
    return
  }
}

# Set Atlassian API credentials from 1Password
# Sets: ATLASSIAN_EMAIL, ATLASSIAN_BASE_URL, ATLASSIAN_API_TOKEN
export def --env atlassian [] {
  _require_tool op

  let email = (op item get Atlassian --fields email --reveal | str trim)
  let base_url = (op item get Atlassian --fields base-url --reveal | str trim)
  let api_token = (op item get Atlassian --fields api-key --reveal | str trim)

  load-env {
    ATLASSIAN_EMAIL: $email
    ATLASSIAN_BASE_URL: $base_url
    ATLASSIAN_API_TOKEN: $api_token
  }

  log info "Atlassian API credentials loaded from 1Password"
}
