---
description: Update plannotator versions in Nix and opencode configs
---

Update plannotator to the latest GitHub release in the following files:

1. `pkgs/plannotator/default.nix` — Update the CLI package `version`, release asset names if needed, and release asset hashes.
2. `modules/home-manager/agents/opencode.nix` — Update the opencode plugin version in `plugin."@plannotator/opencode"`.

Steps:
1. Run `./scripts/update-plannotator.sh latest --validate`.
2. To pin a specific release instead, run `./scripts/update-plannotator.sh <version> --validate`, for example `./scripts/update-plannotator.sh 0.19.0 --validate`.
3. Do not run `nix flake update` for this task.
4. Report the old version, new version, updated files, and whether validation passed. If validation fails, include the command and the relevant error output.

The script fetches the GitHub release metadata, extracts the CLI asset digests for `plannotator-darwin-arm64` and `plannotator-linux-x64`, converts those SHA-256 digests to Nix SRI hashes, updates the Nix package, and updates the opencode plugin pin.
