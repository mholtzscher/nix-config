---
description: Commit changes on a new branch and open a GitHub pull request
---

Package the current working-tree changes into a GitHub pull request. Follow these steps in order:

1. **Review the changes** — run `git status` and `git diff` to understand what changed. Do not commit anything unrelated or pre-existing.

2. **Create a branch** — derive a short, kebab-case branch name from the change (e.g. `add-ripgrep-package`). If one is given below, use it. Create it off the current default branch with `git checkout -b <branch>`.

3. **Commit with a conventional commit message** — stage only the files relevant to this change, then commit using the Conventional Commits format:
   ```
   <type>(<optional scope>): <imperative subject>
   ```
   - `type` is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   - Keep the subject lowercase, imperative, and under 72 characters.
   - Add a body only if the "what" or "why" is not obvious from the subject.

4. **Push and open a PR** — push the branch with `git push -u origin <branch>`, then open a PR against the default branch using `gh pr create`:
   - Title: the same as the commit subject.
   - Body: a short summary of what changed and why, plus any verification steps the reviewer can run. Use `gh`'s `--body` flag or a heredoc.
   - If `gh` is unavailable or auth fails, stop and report the exact error instead of falling back to manual instructions.

5. **Report back** — print the PR URL and a one-line summary of the branch, commit, and PR.

If `$ARGUMENTS` is provided, treat it as the intended branch name / PR description and prefer it over an inferred one.

Arguments:
$ARGUMENTS
