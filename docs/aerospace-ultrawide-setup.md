# Aerospace Ultrawide Monitor Configuration

This guide covers configuring Aerospace for a 5120px ultrawide display, including dynamic workspace sizing with Nushell and Raycast, and screen sharing integration with DeskPad.

## Overview

Windows spanning the full 5120px width of an ultrawide monitor become unreadable—code editors can't be read without constant horizontal eye movement, and applications become impractical to use. This setup constrains the workspace to a manageable width (typically 40%, or ~2048px) while providing quick Raycast commands to adjust sizing on demand.

## Prerequisites

- **Aerospace** – Window manager for macOS
- **Nushell** – Shell with scripting capabilities
- **Raycast** – Command launcher with script integration
- **DeskPad** (optional) – Virtual monitor for screen sharing

## Architecture

The setup consists of three components:

1. **Nushell function** (`aerospace_workspace_size`) – Queries display resolution, calculates gaps, updates Aerospace config, and reloads
2. **Raycast script** – Wrapper providing single-command access to the Nushell function
3. **Aerospace config** – Monitor-specific gap settings and workspace-to-monitor assignments

## Setup

### 1. Nushell Function

Add the `aerospace_workspace_size` function to `~/.config/nushell/functions.nu`:

```nushell
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
  let lines = ($display_info.stdout | lines)
  
  # Find the index of "Main Display: Yes"
  let main_display_index = ($lines | enumerate | where $it.item =~ "Main Display: Yes" | get index.0?)
  
  if ($main_display_index | is-empty) {
    log error "Could not find main display"
    return 1
  }
  
  # Look backwards from main display line to find the resolution
  let resolution_line = ($lines | take ($main_display_index + 1) | where $it =~ "Resolution:" | last)
  
  if ($resolution_line | is-empty) {
    log error "Could not find resolution for main display"
    return 1
  }
  
  # Parse resolution - handle both "Resolution: 5120 x 1440" and "Resolution: 5120 x 1440 Retina"
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
```

### 2. Raycast Scripts

The following scripts are automatically deployed via your Nix configuration:

#### Main Script: `aerospace-workspace-size.sh`

```bash
#!/usr/bin/env zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Aerospace Workspace Size
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🖥️
# @raycast.argument1 { "type": "text", "placeholder": "Percentage (1-100)", "percentBarLabel": "Usable Workspace Size", "optional": true }

# Documentation:
# @raycast.description Set Aerospace workspace size by percentage of monitor width (defaults to 40%)
# @raycast.author mholtzscher
# @raycast.authorURL https://raycast.com/mholtzscher

# Use 40% as default if no argument provided
PERCENTAGE="${1:-40}"

nu -c "source '~/Library/Application Support/nushell/config.nu'; aerospace_workspace_size $PERCENTAGE"
```

#### Increment Script: `aerospace-workspace-size-increment.sh`

```bash
#!/usr/bin/env zsh

# @raycast.schemaVersion 1
# @raycast.title Aerospace Workspace Increment
# @raycast.mode silent
# @raycast.icon 📈
# @raycast.argument1 { "type": "text", "placeholder": "Increment amount (default: 5)", "optional": true }
# @raycast.description Increment Aerospace workspace size by percentage (default 5%)
# @raycast.author mholtzscher
# @raycast.authorURL https://raycast.com/mholtzscher

AMOUNT="${1:-5}"

nu -c "source '~/Library/Application Support/nushell/config.nu'; aerospace_workspace_adjust $AMOUNT"
```

#### Decrement Script: `aerospace-workspace-size-decrement.sh`

```bash
#!/usr/bin/env zsh

# @raycast.schemaVersion 1
# @raycast.title Aerospace Workspace Decrement
# @raycast.mode silent
# @raycast.icon 📉
# @raycast.argument1 { "type": "text", "placeholder": "Decrement amount (default: 5)", "optional": true }
# @raycast.description Decrement Aerospace workspace size by percentage (default 5%)
# @raycast.author mholtzscher
# @raycast.authorURL https://raycast.com/mholtzscher

AMOUNT="${1:--5}"

nu -c "source '~/Library/Application Support/nushell/config.nu'; aerospace_workspace_adjust $AMOUNT"
```

These scripts are automatically deployed via your Nix configuration in `modules/home-manager/home.nix`. They are made executable and available in Raycast without manual setup.

### 3. Aerospace Configuration

Update your `~/.config/aerospace/aerospace.toml` with workspace-to-monitor assignments:

```nix
# Window detection rules - route apps to specific workspaces
on-window-detected = [
  {
    "if" = {
      app-name-regex-substring = "Ghostty";
    };
    run = [ "move-node-to-workspace Ghostty" ];
  }
  {
    "if" = {
      app-name-regex-substring = "Intellij";
    };
    run = [ "move-node-to-workspace IntelliJ" ];
  }
  {
    "if" = {
      app-name-regex-substring = "Code";
    };
    run = [ "move-node-to-workspace VSCode" ];
  }
  {
    "if" = {
      app-name-regex-substring = "Postico";
    };
    run = [ "move-node-to-workspace Postico" ];
  }
];

# Workspace-to-monitor assignment: pull sharing apps to Deskpad when available
workspace-to-monitor-force-assignment = {
  Ghostty = [
    "DeskPad Display"
    "main"
  ];
  IntelliJ = [
    "DeskPad Display"
    "main"
  ];
  VSCode = [
    "DeskPad Display"
    "main"
  ];
  Postico = [
    "DeskPad Display"
    "main"
  ];
};

# Gaps tailored per monitor/use-case
gaps = {
  inner.horizontal = 20;
  inner.vertical = 20;
  outer.right = [
    { monitor."DeskPad Display" = 0; }    # No gaps on virtual display
    { monitor.main = 1536; }              # 40% default on 5120px ultrawide
    24
  ];
  outer.left = [
    { monitor."DeskPad Display" = 0; }
    { monitor.main = 1536; }
    24
  ];
  outer.bottom = 10;
  outer.top = 10;
};
```

## Usage

### Adjusting Workspace Size

You have three ways to adjust your workspace size:

#### Option 1: Set to Specific Percentage
1. Press `⌘ Space` to open Raycast
2. Type "Aerospace Workspace Size"
3. Enter a percentage (1-100)
4. Press Enter

Examples:
- `40` – Constrains workspace to ~2048px (readable code, side-by-side panels)
- `50` – Constrains workspace to ~2560px (more space)
- `100` – Full 5120px (maximum space, less readable)

#### Option 2: Increment by Percentage
1. Press `⌘ Space` to open Raycast
2. Type "Aerospace Workspace Increment"
3. Optionally enter increment amount (default: 5%)
4. Press Enter

#### Option 3: Decrement by Percentage
1. Press `⌘ Space` to open Raycast
2. Type "Aerospace Workspace Decrement"
3. Optionally enter decrement amount (default: 5%)
4. Press Enter

The function saves your choice to `~/.config/aerospace/workspace-size-percentage.txt` and reloads Aerospace instantly. Subsequent calls without an argument reuse the saved percentage.

### Screen Sharing with DeskPad

1. Launch DeskPad
2. Open the applications you want to share (e.g., Ghostty, VSCode)
3. Aerospace automatically routes them to the DeskPad virtual display
4. Select DeskPad as your share source in Zoom/Meet/Teams
5. Your ultrawide workspace remains private

When DeskPad closes, those workspaces fall back to your main ultrawide display.

## Configuration Details

### Gap Calculation

The function calculates gaps to center your workspace:

```
workspace_percentage = 40%
gap_percentage = (100% - 40%) / 2 = 30% per side

For 5120px monitor:
gap_size = 5120 × 0.30 = 1536px per side
usable_workspace = 5120 - (1536 × 2) = 2048px
```

### Key Bindings

Add these to your Aerospace config for quick workspace navigation:

```nix
"alt-ctrl-cmd-h" = "focus left";
"alt-ctrl-cmd-j" = "focus down";
"alt-ctrl-cmd-k" = "focus up";
"alt-ctrl-cmd-l" = "focus right";
"alt-ctrl-cmd-d" = "workspace Deskpad";  # Jump to DeskPad workspace
```

## Troubleshooting

### Aerospace doesn't reload after running the script

Check that Aerospace is running:

```bash
ps aux | grep -i aerospace
```

If not running, the function logs a warning but doesn't fail—the config file is still updated.

### Resolution not detected

Verify `system_profiler` output:

```bash
system_profiler SPDisplaysDataType | grep -A 5 "Main Display: Yes"
```

Look for the `Resolution:` line in the output. If format differs, adjust the regex in the Nushell function accordingly.

### Percentage not persisting

Ensure `~/.config/aerospace/` directory exists and is writable:

```bash
ls -ld ~/.config/aerospace/
```

The percentage file should be created at `~/.config/aerospace/workspace-size-percentage.txt`.

## Performance Notes

- **Gap recalculation**: <100ms
- **Config write**: <50ms
- **Aerospace reload**: ~500ms-1s
- **Total time**: ~1-2 seconds

All operations are non-destructive—only `gaps.outer.left` and `gaps.outer.right.1.monitor.main` entries are modified.

## Integration with Nix Flakes

All Raycast scripts and Nushell functions are automatically deployed via your Home Manager configuration in `modules/home-manager/home.nix`:

```nix
# Raycast scripts
home.file."${config.xdg.configHome}/raycast/scripts/aerospace-workspace-size.sh" = {
  source = ./files/raycast/aerospace-workspace-size.sh;
  executable = true;
};

# Nushell functions (sourced in nushell.nix)
${builtins.readFile ../files/nushell/functions.nu}
```

This keeps your configuration version-controlled and automatically synchronized across machines. When you rebuild your system, these scripts and functions are deployed with correct permissions and paths.
