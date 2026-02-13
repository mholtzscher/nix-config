---
description: Auto-branch, commit, and PR - just yeet code to GitHub
agent: general
---

Yeet the current changes to GitHub by automatically creating a branch, committing, and opening a PR.

Steps:
1. Check git status to see current state and staged/unstaged changes
2. Stage all changes (including untracked files)
3. Analyze the staged changes to understand what was modified:
   - Look at which files were changed
   - Understand the nature of the changes (feat, fix, refactor, docs, etc.)
   - Identify the scope/component affected
4. Generate a branch name based on the changes following pattern: <type>/<brief-description>-<timestamp>
   Examples: feat/add-user-auth-20250206, fix/login-bug-20250206, docs/update-readme-20250206
5. Create and checkout the new branch
6. Create a conventional commit message based on the changes (use conventional-commit skill)
7. Push the branch to origin
8. Create a pull request using gh pr create with title matching commit message and brief description

DO NOT ask for branch name or commit message - generate them automatically based on the changes.
Just do it - yeet it to GitHub!
