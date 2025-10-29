Analyze the current git state and create a conventional commit message following best practices.

## Analysis Steps

1. Run `git status` to see staged and unstaged changes
2. Run `git diff --cached` to see staged changes that will be committed
3. If no changes are staged, run `git diff` to see unstaged changes and ask if they should be staged
4. Run `git log --oneline -5` to understand recent commit message patterns in this repository

## Conventional Commit Format

Create a commit message following the conventional commit specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types to use

- **feat**: new feature for the user
- **fix**: bug fix for the user
- **docs**: changes to documentation
- **style**: formatting, missing semicolons, etc; no production code change
- **refactor**: refactoring production code, eg. renaming a variable
- **test**: adding missing tests, refactoring tests; no production code change
- **chore**: updating grunt tasks etc; no production code change
- **perf**: performance improvements
- **ci**: changes to CI configuration files and scripts
- **build**: changes that affect the build system or external dependencies

## Requirements

1. **Analyze the changes**: Understand what was modified, added, or removed
2. **Determine the type**: Choose the most appropriate conventional commit type
3. **Write a clear description**: Concise but descriptive (50 chars or less for the subject)
4. **Add body if needed**: For complex changes, include a body explaining the "why"
5. **Stage files if needed**: If no files are staged, ask what should be committed
6. **Create the commit**: Use `git commit -m` with the conventional commit message

## Output Format

After analysis, create the commit using this exact format:

```bash
git commit -m "<type>[optional scope]: <description>"
```

If a body is needed:

```bash
git commit -m "<type>[optional scope]: <description>

<body explaining the why and any breaking changes>"
```

Focus on creating a single, well-crafted conventional commit that accurately represents the changes.
