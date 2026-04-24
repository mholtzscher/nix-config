---
description: Update flake inputs and validate build
---

Update Nix flake inputs and validate the build.

1. Run `git pull` to sync with remote.
2. Run `nix flake update` to update all flake inputs.
3. Run `./scripts/agent-validate.sh` to validate the build.
4. Report the result:
   - If successful:
     a. Stage only `flake.lock`: `git add flake.lock`.
     b. Commit with a conventional commit message: `git commit -m "chore(flake): update inputs"`.
     c. Do not commit any other unstaged changes.
     d. Report: "Build successful. Changes committed. Run your apply command to deploy."
   - If failed:
     a. Inspect `git diff flake.lock` to see which inputs changed.
     b. Triage which updated input is causing the failure — use error context (e.g., package name, module path, version mismatch) to narrow it down.
     c. Roll back the problematic input(s) in `flake.lock` by restoring the pre-update revision (use `git checkout -- flake.lock` if only one culprit, or selectively revert lines in `flake.lock` for that input).
     d. Re-run `./scripts/agent-validate.sh` to confirm the build passes after rollback.
     e. Notify the user which input was rolled back and why.

Never run apply commands (`nh os switch`, `nh darwin switch`, `nh home switch`, `darwin-rebuild switch`, `nixos-rebuild switch`, `home-manager switch`, etc.).
