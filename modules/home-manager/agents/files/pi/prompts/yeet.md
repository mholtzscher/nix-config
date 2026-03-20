---
description: Auto-branch, commit, and PR - just yeet code to GitHub
---

Yeet the current changes to GitHub by automatically creating a branch, committing, and opening a PR.

Steps:
1. Check git status to see the current staged and unstaged changes.
2. Stage all changes, including untracked files.
3. Analyze the staged changes to understand what was modified:
   - Look at which files changed
   - Understand the nature of the changes (`feat`, `fix`, `refactor`, `docs`, etc.)
   - Identify the scope or component affected
4. Generate a branch name following the pattern `<type>/<brief-description>-<timestamp>`.
   Examples: `feat/add-user-auth-20250206`, `fix/login-bug-20250206`, `docs/update-readme-20250206`
5. Create and check out the new branch.
6. Create a conventional commit message based on the changes. Use the `conventional-commits` skill if needed.
7. Push the branch to `origin`.
8. Create a pull request with `gh pr create`, using the commit message as the title and a brief description.

Do not ask for a branch name or commit message. Generate them automatically based on the changes.
Just do it. Yeet it to GitHub.
