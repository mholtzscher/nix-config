# Herdr plugin ownership

The live shared `~/.config/mise/config.toml` declares [mise-herdr-plugins](https://github.com/mholtzscher/mise-herdr-plugins) under `[bootstrap.plugins]` and the four existing plugin repositories under `[bootstrap.packages]`. Herdr owns their GitHub checkouts, builds, registration and runtime data; Mise owns package status/apply/upgrade. `latest` means default-branch HEAD for new installs and explicit upgrades, not GitHub's latest release.

Rust is a global Mise tool because Focus or Tab, Navigator and Worktree Picker run `cargo build --release`. Git, Herdr and a working native linker must also be available globally; Macs need the Command Line Tools. Herdr itself, standalone annotation binaries, enabled agent skills and built-in Pi/OpenCode integration installation remain Nix fallbacks. No keybindings, enabled state, plugin configuration or annotation data are migrated into package declarations.

## One-time handoff on each machine

Review and publish the Nix changes, then have the user build and switch the appropriate NixOS or standalone Home Manager configuration. Nix no longer registers plugins. Applying an older Nix configuration can recreate the old links; do not switch back to it after handoff without deliberately undoing the ownership change.

Install only prerequisites before attempting plugin packages:

```sh
mise bootstrap plugins apply
mise install rust
herdr plugin list --json
mise bootstrap packages apply --manager herdr-plugins --dry-run
```

The adapter does not adopt or force-unlink local plugins. For each existing registration, inspect its source, root, enabled state and manifest ID. Back up the native list output locally. Unlink **only** a verified Nix-store local link for the plugin being migrated, then apply that single package:

```sh
herdr plugin unlink annotate
mise bootstrap packages apply herdr-plugins:plannotator/herdr-annotate
```

Repeat individually for `herdr-focus-or-tab`, `herdr-navigator` and `herdr-worktree-picker`, using their matching declarations. Never blanket-unlink other local development plugins. If a plugin is disabled, stop and decide its intended state before installing: native installation enables it. If installation fails after unlinking, inspect the native list before restoring the saved local link and its original enabled/disabled state; don't blindly retry or overwrite an unexpected registration.

Unlinking registration does not delete Nix-store code, plugin settings or annotation data. Leave unrelated registrations and runtime data alone; no prune, uninstall, server restart or direct registry edit is part of this handoff.

## Daily use

Once ownership has moved, normal `mise bootstrap` installs missing plugin packages. To inspect or target the manager explicitly:

```sh
mise bootstrap packages status
mise bootstrap packages apply --manager herdr-plugins
mise bootstrap packages upgrade --manager herdr-plugins --dry-run
mise bootstrap packages upgrade --manager herdr-plugins
```

Matching installations are not rebuilt by apply. Package upgrades are separate from Mise's native tool-update service. Disabled plugins satisfy status, but the adapter refuses updates that would silently enable them. Removing a declaration does not uninstall a plugin.

Verify `herdr plugin list --json` reports the expected GitHub source and preserved manifest ID/enabled state, and confirm the existing keybound actions still resolve. Test actual interactive actions on each Mac; Linux installation checks are not proof of Mac GUI/runtime behavior.
