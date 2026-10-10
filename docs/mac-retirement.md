# Retiring nix-darwin

**Status: replacement user configurations are prepared; system teardown is blocked on checks on each Mac. Do not uninstall nix-darwin yet.** NixOS and Wanda are unchanged. No Nix configuration has been applied by the agent.

Mise is the preferred manager for portable tools, writable configuration, fonts, preferences and user services. Standalone Home Manager is only the fallback for remaining Nix packages, agenix, app aliases, Nushell's generated plugin registry and package-coupled integrations. The old Darwin outputs remain available for recovery until both Macs pass the gates below; removing them or the input now would not uninstall the running systems safely.

## Prepared

- `homeConfigurations.personal-mac`: user `michael`, home `/Users/michael`.
- `homeConfigurations.work-mac`: user `michaelholtzcher`, home `/Users/michaelholtzcher` (the existing spelling is intentional).
- Both use the same Home Manager modules as their Darwin outputs and keep `home.stateVersion = "25.05"`. Personal agenix identities, paths and agents remain; work has no personal secrets.
- Native Mise shell sources load the installer Nix environment and prefer `~/.nix-profile` instead of requiring `/etc/profiles/per-user`. The old profile is a guarded fallback during migration. Both profiles set `NH_HOME_FLAKE` to their explicit standalone output.
- Native Mise packages provide Iosevka and JetBrains Mono Nerd Fonts in the user's font directory. Darwin's `/Library/Fonts/Nix Fonts` is not the replacement owner.
- On a Mac, `./scripts/agent-validate.sh personal-mac` or `work-mac` builds the standalone output without activating it. No flake update is needed.

Nix changes must be reviewed and published before the Macs can fetch them. Mise history is separate and synchronizes the native sources automatically. Back up locally edited files before fetching/applying, without placing credentials or runtime data in tracked history.

## 1. Build on both Macs

Keep the current terminal open. First complete the [standalone Mise handoff](mise-setup.md), choose the correct untracked local profile, and pull incoming history with `mise dot pull`. Inspect any conflicts rather than taking remote changes wholesale.

Personal Mac, from `~/.config/nix-config`:

```sh
./scripts/agent-validate.sh personal-mac
```

Work Mac:

```sh
./scripts/agent-validate.sh work-mac
```

Both standalone activation derivations now evaluate on Linux: moving plugin ownership to [Mise's Herdr manager](herdr-plugins.md) also removed the unused annotation-skill source that previously forced a foreign build during evaluation. Full Darwin builds and actual activation still need an Apple-Silicon Mac; successful evaluation is not a successful Mac build.

## 2. Activate only the fallback user configuration

Only the user runs activation. Review any existing `~/.nix-profile` packages and file conflicts before switching; don't delete the profile or force-overwrite files.

Personal:

```sh
home-manager switch --flake ~/.config/nix-config#personal-mac
```

Work:

```sh
home-manager switch --flake ~/.config/nix-config#work-mac
```

This does **not** uninstall nix-darwin or hand off its system services. Do not run another Darwin switch after the standalone handoff: the two Home Manager activation owners share some paths and agent labels.

Run `mise bootstrap` for incoming native setup changes. To install just the replacement fonts:

```sh
mise bootstrap packages apply brew-cask:font-iosevka-nerd-font brew-cask:font-jetbrains-mono-nerd-font
```

Review Font Book for duplicate families while Darwin fonts still exist. Don't delete unrelated fonts or casks. Confirm the configured font names render correctly in a newly opened terminal.

Verify fresh Zsh and Nushell sessions resolve `mise`, `nix`, `home-manager`, `nh`, `nu`, Ghostty and Neovim without depending on `/run/current-system`. `type -a mise` (Zsh) or `which --all mise` (Nushell) must show `~/.local/bin/mise` as the first external Mise. Check that `NH_HOME_FLAKE` selects the right output and that `~/Applications/Home Manager Apps` points to the standalone generation. Preserve existing work Keychain/onboarding, SSH-agent routing, plugin runtime and personal Podman machine state.

## 3. System gates — still required

### Installer Nix daemon and settings — both Macs

Identify the actual Nix installer (including any Determinate service) and its mount/daemon ownership. The pinned Darwin uninstaller restores the installer daemon **only if both files exist**:

```text
/run/current-system/Library/LaunchDaemons/org.nixos.nix-daemon.plist
/nix/var/nix/profiles/default/Library/LaunchDaemons/org.nixos.nix-daemon.plist
```

Existence alone is insufficient: verify the retained plist's program is executable, its closure is GC-rooted, and its service is compatible with this installation. A missing or unusable installer restoration is a blocker, not permission to invent a LaunchAgent for the daemon.

Inspect `/etc/nix/nix.conf`, installer includes and `.before-nix-darwin` backups locally. Preserve installer settings, flakes, the correct trusted user, and required caches/public keys from `modules/shared/nix-settings.nix`. Never replace the entire file from a generic template, disclose credentials, or overwrite installer-specific includes. Native Mise `bootstrap.files` can own a reviewed root-owned text file afterward, but no declaration is installed until that review identifies the correct content.

Darwin currently also runs **root** garbage collection weekly, Sunday at 02:00, with `--delete-older-than 14d`. A user LaunchAgent is not an equivalent policy. Establish its replacement owner/schedule deliberately; don't silently change retention or collect old generations during the handoff.

### Touch ID with reattachment — both Macs

Preserve password fallback and test it before teardown. macOS 14+ includes `/etc/pam.d/sudo_local` automatically; inspect older versions before assuming that include exists.

The replacement must retain the existing order:

```text
auth optional   /nix/store/<GC-rooted-pam-reattach>/lib/pam/pam_reattach.so
auth sufficient pam_tid.so
```

Resolve the real store path on the Mac and independently root its dependency closure before removing Darwin generations. Verify root-owned, non-user-writable path components. **Do not use `~/.nix-profile`, Homebrew or another user-writable library path in PAM.** Do not copy a binary through Mise's text-file declarations.

After Darwin has released the file, native Mise can own a reviewed `sudo_local` text source with `os = "macos"`, `owner = "root"`, `group = "wheel"`, and `mode = "0644"`. Its immutable library path is machine-local, not a synced path copied from another Mac. Until this source and the independent GC root are verified, authentication handoff is a blocker. Test Touch ID and password fallback in an ordinary terminal and the terminal multiplexer before closing the recovery terminal.

### Personal Tailscale daemon and DNS

The personal Mac uses the CLI `tailscaled` system service, not the GUI/App Store variant. The work profile has no repository-managed Tailscale service; don't introduce one there.

Make a protected local backup of `/Library/Tailscale/tailscaled.state` without reading/sharing its contents. Retain a compatible binary and confirm its upstream macOS daemon installer uses the existing `com.tailscale.tailscaled` label and state location. Preserve `/etc/resolver/ts.net`, MagicDNS and node identity; no logout, reset or re-authentication is part of this migration.

Darwin teardown removes that label's plist. A replacement installed before teardown may therefore be removed too: coordinate the service restoration **after** teardown with a local recovery path. Mise's macOS LaunchAgents and cross-platform user services cannot own this system LaunchDaemon. This remains a personal-Mac blocker until the exact installed version and restoration sequence are confirmed.

### System policy, accounts and restoration — both Macs

- Guest login must remain disabled in `/Library/Preferences/com.apple.loginwindow`. Mise defaults are user-scoped, including `host = "current"`; they cannot own this policy. Verify the existing value and retain an approved system/MDM owner or a narrowly targeted privileged defaults change. Never overwrite the whole plist.
- Inspect managed `/etc` links and their backups before restoring them. Retain account UIDs and `/etc/shells`; the uninstaller changes accounts whose login shells start with `/run/` to `/bin/zsh`.
- The repository creates `/Applications/Nix Apps` as a real alias directory, whereas the uninstaller explicitly removes only a symlink at that path. Inspect it for stale system-profile targets; do not recursively remove unrelated apps. Standalone Home Manager provides the retained user app aliases and Dock targets.
- Confirm replacement fonts exist before Darwin synchronizes away its own font directory.

## 4. Teardown gate and completion

There is intentionally **no unconditional uninstall command** here. Once every system gate is verified, use the uninstaller from the existing pinned Darwin generation, with a protected backup and a known rollback generation. The uninstaller removes Darwin services and managed `/etc` files; it does not uninstall Nix or remove every old system-generation root.

Do not remove those roots until replacement PAM/service dependencies are independently rooted. Keep the recovery terminal open until a fresh login and reboot verify Nix daemon/mounts, sudo/password/Touch ID, personal Tailscale identity/DNS, shell paths, fonts, app aliases, agenix and generated integrations.

After **both** Macs pass, remove the retired Darwin outputs, host system entrypoints, module directory and direct flake input. Preserve Linux configuration and any transitive inputs still needed by other flakes. Until then those files are deliberate recovery support, not a claim that nix-darwin has already been removed.

Sources checked: pinned nix-darwin `4cff07de74b50e64bdd68cd4e722ab5b6b35ee48` uninstaller, Nix daemon restoration, PAM, fonts and launchd modules; Mise `2026.10.6` [managed files](https://mise.jdx.dev/bootstrap/files.html), [LaunchAgents](https://mise.jdx.dev/bootstrap/launchd.html) and [user defaults](https://mise.jdx.dev/bootstrap/macos-defaults.html). Upstream Tailscale installer behavior must be checked against the Mac's installed version.
