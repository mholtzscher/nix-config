---
description: Commit changes on the current or a new branch and open a GitHub pull request
argument-hint: "[--watch] [branch or PR description]"
---

Package the current working-tree changes into a GitHub pull request. Follow these steps in order:

1. **Review the repository and changes** — run `git status`, `git diff`, and `git branch --show-current` to understand the current branch or worktree and what changed. Determine the repository's default branch from GitHub (for example, `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`) or the remote's symbolic HEAD. Never assume it is `main` or `master`. Do not commit anything unrelated or pre-existing.

2. **Choose a branch** — if the current branch is a non-default branch, including a branch already checked out in a linked worktree, use it as-is; do not create or switch branches. If the current branch is the default branch or HEAD is detached, derive a short, kebab-case branch name from the change (e.g. `add-ripgrep-package`), unless one is given below, and create it from the current HEAD with `git switch -c <branch>`.

3. **Commit with a conventional commit message** — stage only the files relevant to this change, then commit using the Conventional Commits format:
   ```
   <type>(<optional scope>): <imperative subject>
   ```
   - `type` is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
   - Keep the subject lowercase, imperative, and under 72 characters.
   - Add a body only if the "what" or "why" is not obvious from the subject.

4. **Push and open a PR** — push the selected branch with `git push -u origin <branch>`, then open a PR against the discovered default branch using `gh pr create --base <default-branch>`:
   - Title: the same as the commit subject.
   - Body: a short summary of what changed and why, plus any verification steps the reviewer can run. Use `gh`'s `--body` flag or a heredoc.
   - If `gh` is unavailable or auth fails, stop and report the exact error instead of falling back to manual instructions.

5. **Watch checks when requested** — if an exact standalone `--watch` argument was provided, run `gh pr checks --watch --interval 10 <PR-URL>` after creating the PR. Wait until all reported checks finish, then summarize passed, failed, and cancelled checks. If watching fails, report the exact error.

6. **Report back** — print the PR URL and a one-line summary of the branch, commit, and PR.

Treat an exact standalone `--watch` argument as a control option and remove it before interpreting the remaining arguments. If any arguments remain, treat them as the intended branch name / PR description and prefer them over an inferred one when a new branch is needed. Do not switch away from an existing non-default branch.

Arguments:
$ARGUMENTS
