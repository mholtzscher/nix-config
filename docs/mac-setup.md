# Mac configuration handoff

For the current **Mise-first, no nix-darwin** goal, follow [Retiring nix-darwin](mac-retirement.md). That guide prepares both standalone Home Manager fallbacks and lists the mandatory Mac-side system gates. The original Darwin-to-Mise adoption steps below describe the earlier handoff, not the next activation command; do not resume Darwin switches after moving to standalone Home Manager.

Mac user configuration is managed by native Mise declarations and history in the private `mholtzscher/workstation` repository. Nix still provides the remaining binaries and their generated integrations, except Mise itself: every machine uses the self-updatable official executable at `~/.local/bin/mise`. Linux retains its existing Nix shell, Git, SSH, and Herdr configuration, with Mise activation using the standalone executable.

## Ownership

- Shared macOS user preferences are in `~/.config/mise/config.toml`. Personal/work Dock layouts are in `config.personal.toml` and `config.work.toml`.
- Mac app and shell sources are writable files under `~/.config/mise/dotfiles/macos/`. Mise links the normal app/startup paths to them; edits through those paths update the tracked sources and are saved and synchronized automatically. Raycast uses native `symlink-each` so unrelated scripts stay untouched.
- Personal/work SSH, Git, shell environment, and agent-model settings remain separate. No private keys, Keychain values, agenix plaintext, sessions, caches, or installed plugins are tracked.
- AeroSpace still starts Borders through its unchanged startup command. Existing app login items remain local; no new app service is invented.
- Nix retains guest-login policy (system-wide), Touch ID/PAM with reattachment, Nix settings/GC, fonts, user/account setup, system shell/PATH setup, application aliases, agenix activation, personal Podman machine initialization/LaunchAgent, agent-skill installation and built-in Herdr agent integrations, Nushell's generated plugin registry, nix-direnv integration, and package-specific wrappers. Herdr plugin packages now belong to [Mise](herdr-plugins.md). These remaining Nix responsibilities are privileged settings or generated/package-coupled integrations, not portable user dotfiles.

## Prerequisites

The pending standalone-Mise Nix changes must be reviewed and published before either Mac can fetch them. The agent has **not** committed, pushed, or applied these Nix changes. The Mise history is published separately. Follow [Standalone Mise](mise-setup.md) to install the official executable before switching away from the Nix package.

Back up the existing Mac configuration locally before the handoff, particularly any files edited since their last Nix activation. Keep that backup outside tracked Mise sources. Preserve existing Homebrew installations and apps; do not prune or zap them.

Keep your current terminal open until the entire bootstrap succeeds. Do not restart Ghostty, Herdr, or Nushell midway through the handoff.

## Apply on each Mac

1. After the Nix changes are published, fetch and build them in your existing shell. Only the user runs the switch:

   ```sh
   git -C ~/.config/nix-config pull --ff-only
   nh darwin build
   nh darwin switch
   ~/.local/bin/mise --version
   ```

   Nix no longer installs Mise. Confirm the standalone executable is `2026.10.6` or newer before adoption. No flake update is required for this handoff.

2. In zsh, choose the profile **before first adoption**. Create or edit the untracked `~/.config/mise/miserc.local.toml`; preserve any other local settings. Personal Mac:

   ```toml
   env = ["personal"]
   ```

   Work Mac:

   ```toml
   env = ["work"]
   ```

3. Confirm GitHub SSH authentication and preview adoption:

   ```sh
   ~/.local/bin/mise bootstrap --adopt git@github.com:mholtzscher/workstation.git --dry-run
   ```

   Review configuration differences. Symlink deployment refuses existing regular files, including the old writable AeroSpace config. Inspect those files, preserve wanted changes in the appropriate shared or profile source, and move only the conflicting old files to the local backup before retrying. Do **not** use a blanket `--force`.

4. Apply the reviewed setup:

   ```sh
   ~/.local/bin/mise bootstrap --adopt git@github.com:mholtzscher/workstation.git
   ~/.local/bin/mise bootstrap services apply
   ~/.local/bin/mise doctor
   ~/.local/bin/mise dot status
   ~/.local/bin/mise bootstrap macos defaults status
   ```

   The Dock declaration requires every listed application to exist. This includes existing manually installed work apps and Nix's `~/Applications/Home Manager Apps/` aliases. Resolve a missing app, or deliberately adjust that profile's Dock list, rather than silently discarding pins. Existing Homebrew-owned casks remain installed and are not forcibly replaced; ownership transfer and upgrades are a separate Mac-side decision.

5. After success, open a fresh terminal. Verify Mise, shell completions, Ctrl-R, `yy`, Git/LFS, SSH/1Password agent routing, Ghostty, Neovim, and AeroSpace/Raycast. Nushell retains its existing native plugin registry. Existing personal agenix keys and work Keychain/onboarding state must remain available; they are not restored from dotfile history.

   Relaunch Dock/Finder/menu-bar processes when convenient to activate stored preference changes:

   ```sh
   killall Dock Finder SystemUIServer
   ```

## Subsequent updates

History services automatically save, push, fetch, and apply tracked configuration changes. After incoming setup/tool changes, run `mise bootstrap`; history sync does not install tools or apply preferences by itself. Bootstrap packages have their own upgrade command, `mise bootstrap packages upgrade`; it is not the native CLI tool updater.

## Validation boundary

The Linux NixOS build, byte-for-byte Linux config preservation, Mac preference/Dock parity, personal/work isolated restoration and file deployment, shell parsing/startup fixtures, and Apple-Silicon tool-resolution previews were checked on Linux. Fixtures verify that real-file conflicts and unrelated Raycast scripts are preserved, permissions survive restoration, and edits through native links can be saved.

Full Darwin builds and actual macOS preference, GUI, Keychain, and app execution still require a Mac. Both standalone Home Manager activation derivations now evaluate on Linux after removing an unused annotation-skill source; the earlier foreign-build evaluation failure no longer applies to those outputs. Build on the target Mac before switching. The standalone handoff must also confirm no Nix-owned Mise package or Mac Mise config file, with retained Touch ID, guest-login policy, agenix, and Nushell plugin registry on both Macs.
