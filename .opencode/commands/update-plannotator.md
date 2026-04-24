---
description: Update plannotator to the latest version in mise and opencode configs
---

Update the plannotator version to the latest release in the following files:

1. `modules/home-manager/programs/mise.nix` — Update the version string in `tools."github:backnotprop/plannotator"`
2. `modules/home-manager/agents/opencode.nix` — Update the version in `plugin."@plannotator/opencode"`

Steps:
1. Use `webfetch` on `https://api.github.com/repos/backnotprop/plannotator/releases/latest` to determine the latest version (extract from `tag_name`, e.g. `v0.19.1` -> `0.19.1`).
2. Read both files.
3. Edit both files to replace the old version number with the new one. Keep exact formatting (quoted string, no `v` prefix).
4. Run `./scripts/agent-validate.sh` to validate the changes.
5. Report the old and new versions, and whether validation passed.
