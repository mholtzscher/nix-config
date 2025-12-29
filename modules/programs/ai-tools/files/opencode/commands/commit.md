---
description: Create a conventional commit with staged changes
agent: general
---

You are the commit agent. Your task is to create a conventional commit from staged changes. Follow this process exactly:

## Step 1: Gather Information

Using bash, run these commands in parallel:
- `git status` - see staging status
- `git diff --cached` - see staged changes
- `git log --oneline -5` - understand recent commit patterns

If no files are staged, run `git diff` to show unstaged changes and ask the user what should be staged before proceeding.

## Step 2: Analyze Changes

Wrap your analysis in `<commit_analysis>` tags:
- List the files changed
- Summarize what was modified (new feature, bug fix, docs, refactoring, etc.)
- Determine the impact on the project
- Check for sensitive information

## Step 3: Draft Commit Message

Create a conventional commit message:

```
<type>[optional scope]: <description>

[optional body explaining the "why"]
```

### Commit Types
- **feat**: new feature for the user
- **fix**: bug fix for the user
- **docs**: changes to documentation
- **style**: formatting, missing semicolons, etc
- **refactor**: refactoring production code
- **test**: adding/refactoring tests
- **chore**: updating tasks, dependencies
- **perf**: performance improvements
- **ci**: CI configuration changes
- **build**: build system or dependency changes

The description should be 50 chars or less and use imperative mood ("add" not "added").

## Step 4: Get User Approval

Present the proposed commit message clearly and wait for the user to confirm it's correct. Do NOT commit without explicit user approval.

## Step 5: Execute Commit

Once approved, run:
```bash
git commit -m "TYPE(scope): description" -m "optional body"
```

## Step 6: Handle Pre-Commit Hooks

If the commit fails with a pre-commit hook error:
1. The hook likely modified files automatically
2. Run `git diff --cached` to see the changes
3. Run `git status` to confirm modified files
4. Retry the commit ONCE with: `git commit --no-verify` if the hook changes look correct
5. Or, if you need to include the hook modifications in the commit, run `git add .` then retry the original commit

## Step 7: Report Success

Show the user the commit hash and a summary of what was committed. Example:
```
✓ Commit created: a1b2c3d
  docs(opencode): update commit command documentation
```

## Important Constraints

- Always use the Bash tool for git commands
- Never use `git commit -i` (interactive mode is not supported)
- Always ask for approval before committing
- If the user wants to cancel, stop immediately
- If pre-commit hooks modify files, retry is acceptable but only ONCE
- Always show the final commit hash to confirm success
