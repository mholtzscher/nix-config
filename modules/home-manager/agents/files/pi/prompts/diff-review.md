---
description: Perform a comprehensive code review of staged changes
---

# Code Review

Thoroughly review the current staged git diff.

Use **ONLY** `git --no-pager diff --cached -U30` to get the diff to review.
Do **NOT** check for unstaged git changes.

## Review Scope

- **Only review the CHANGED lines** (additions, modifications, deletions)
- Consider the context around changes but don't review unchanged code
- Assume existing code (shown with context) is already approved

## Review Criteria

- **Bugs & Logic Errors**: Any issues that could cause failures
- **Security vulnerabilities**: Potential security risks
- **Performance issues**: Inefficiencies or bottlenecks
- **Code quality**: Readability, maintainability, best practices
- **Missing edge cases**: Unhandled scenarios
- **Error handling**: Proper error management and logging

## Output Format Requirements

For every suggestion, provide the fix in unified diff format:

1. Use ```diff code blocks
2. Each diff should show the file path as a comment on the first line
3. Show removed lines with `-` prefix
4. Show added lines with `+` prefix
5. Include enough context (3 lines before and after changes)
6. Add a comment line starting with `#` explaining the change
7. After each suggestion place a markdown horizontal rule

Example format:

---

## Issue 1

- filepath: src/utils/userHelper.js
- Explanation: A brief explanation of the problem

```diff
- const x = getUserData();
+ const userData = getUserData();

# Fix: Add null check to prevent runtime error
  function processUser(user) {
+   if (!user) {
+     throw new Error('User object is required');
+   }
    return user.name.toUpperCase();
  }
```

---

Structure your response as:

🔴 Critical Issues  
[List critical problems with diff fixes]

🟡 Improvements  
[List suggested improvements with diff fixes]

🟢 Good Practices  
[Brief list of what was done well - no diffs needed]

📊 Summary  
- Overall Rating: [1-10]
- Lines changed: [approximate count]
- Priority: [High/Medium/Low] for addressing these issues

If there are no staged changes, respond with `No changes detected` and a dad joke about programming.
Make sure every code change is shown as a diff for easy application.
