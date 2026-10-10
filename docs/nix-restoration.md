# Return to the pre-Mise configuration

Baseline: `2636695` (2026-10-09 10:52 Central), before Mise migration history
began that afternoon. The restoration is a new commit, not rewritten history.
The previous Nix tree remains on `recovery/pre-nix-restoration-20261010`.

Two safety exceptions to the baseline: Homebrew cleanup is `none`, not `zap`,
and Pi activation preserves unrelated custom agents instead of deleting their
directory. No flake inputs are updated. Credentials and runtime data are not
rolled back. Existing native applications are retained until verified.

## Macs: build before disabling the migration

Use a local terminal, not a Tailscale-dependent SSH session. Open `/bin/bash`
so the following commands do not depend on Nushell syntax or Mise tools.
Do not run `mise dot pull`, `mise bootstrap`, or a flake update during recovery.

```bash
cd "$HOME/.config/nix-config"
git status --short
git pull --ff-only
```

If Git reports local changes or cannot fast-forward, stop; do not reset it.

Select the host matching your account:

```bash
# Personal Mac:
host=Michaels-M1-Max

# Work Mac, instead:
# host=Michael-Holtzscher-Work

nix build --out-link ./result-nix-restoration \
  ".#darwinConfigurations.${host}.system"
```

Only after the build succeeds, prepare the ownership handoff:

```bash
/bin/bash scripts/prepare-nix-restoration.sh
```

This checkpoints tracked configuration, removes only the Mise history and
tool-update user services, and moves five migration configuration files to
a private recovery directory. It does not apply Nix, remove installed tools,
read credentials, touch Tailscale, or change Podman state. Native source
directories remain in place for the current shell.

Home Manager backs up regular files, but refuses to overwrite foreign symlinks.
Before applying, archive only migration links at paths the restored generation
owns (this also fixes a system switch whose Home Manager activation stopped):

```bash
hm="$(nix build --no-link --print-out-paths ".#darwinConfigurations.${host}.config.home-manager.users.$(id -un).home.activationPackage")"
/bin/bash scripts/archive-mise-links.sh "$hm/home-files"
```

The helper moves only symlinks pointing into `~/.config/mise/`, at paths present
in that generation's `home-files`. It preserves links in a private, unique
recovery directory, without reading their contents. It does not move unrelated
links, regular files, or `.backup` files. Keep the terminal open until activation
has successfully installed the replacement links.

## Personal Mac: hand the native Tailscale daemon back to nix-darwin

Skip this section on the work Mac. Check the current daemon and plist first:

```bash
tailscale version --daemon
sudo ls -ld /Library/LaunchDaemons/com.tailscale.tailscaled.plist \
  /Library/Tailscale/tailscaled.state
```

For the native installation restored during the migration, preserve state and
archive its plist before nix-darwin installs its own job with the same label:

```bash
root_backup="/var/root/nix-restoration-$(date +%Y%m%d-%H%M%S)"
sudo install -d -m 700 "$root_backup"
sudo cp -p /Library/Tailscale/tailscaled.state "$root_backup/"
sudo launchctl bootout system /Library/LaunchDaemons/com.tailscale.tailscaled.plist
sudo mv /Library/LaunchDaemons/com.tailscale.tailscaled.plist "$root_backup/"
```

Stop on any error. Do not log out, reset, delete live state, or re-authenticate.
This briefly interrupts Tailscale; the Nix daemon uses the existing node state.
If the switch fails before restoring the daemon, recover the native job with
the following commands, using the same `root_backup` variable:

```bash
sudo cp -p "$root_backup/com.tailscale.tailscaled.plist" \
  /Library/LaunchDaemons/com.tailscale.tailscaled.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tailscale.tailscaled.plist
```

## Apply (user only)

```bash
sudo ./result-nix-restoration/sw/bin/darwin-rebuild switch --flake ".#${host}"
```

This re-establishes nix-darwin with embedded Home Manager and agenix. Do not
run a separate Mac `home-manager switch`. Preserve the current password-sudo
session until sudo has been tested from another terminal.

If activation reports conflicting files or an existing `.backup`, stop and
report the exact paths. Do not delete files or force Home Manager to overwrite
them. Home Manager's existing `backupFileExtension = "backup"` preserves
unmanaged configuration when possible.

After a successful switch, archive the standalone Mise executable so it no
longer shadows Nix's copy. Do not move a symlink or a different installation:

```bash
backup="$(cat "$HOME/.local/state/nix-restoration/latest")"
if [[ -f "$HOME/.local/bin/mise" && ! -L "$HOME/.local/bin/mise" ]]; then
  mv "$HOME/.local/bin/mise" "$backup/mise-standalone"
fi
hash -r
```

Open a fresh terminal and verify shell startup, Git, editor tools, Pi/OpenCode,
skills, Herdr integrations/plugins, native app aliases, password sudo/Touch ID,
and personal Tailscale/Podman. Verify secret paths and permissions without
printing their contents. Reboot only after these checks pass.

## Linux

The restored tree also reinstates the original Linux Home Manager owners.
Build first, then run the preparation script and apply yourself:

- NixOS desktop: `./scripts/agent-validate.sh`, then `nh os switch`.
- Wanda: `./scripts/agent-validate.sh wanda`, then `nh home switch .#wanda`.

Do not touch Linux Tailscale's daemon. After a successful apply, archive the
standalone Mise executable as above and test a fresh terminal.

## Recovery boundaries

The archived Mise configuration can be moved back from the printed recovery
directory if the handoff is abandoned, but do not overwrite files produced by
a successful Nix activation or restart the Mise watcher over Nix-owned files.
Mise history, installed tool directories, native app installs, Podman VMs,
credentials, and the root-owned native PAM module are intentionally retained.
Remove redundant migration artifacts only after both Macs and Linux verify.
