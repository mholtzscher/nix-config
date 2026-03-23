---
name: gradle
description: Run Gradle tasks with minimal, high-signal output by capturing full logs and returning short summaries. Use when building, testing, or debugging Gradle projects.
---

# Gradle Command Execution for Agents

Run Gradle in a way that minimizes token usage while preserving the signal needed to debug failures.

## Rules

1. Run the narrowest possible task.
2. Capture all output to a log file.
3. Return only a short summary by default.
4. On failure, return failed task names plus a short tail of the log.
5. Prefer test/report artifacts over raw console output.

## Default Command

```bash
./gradlew -q --console=plain --warning-mode=none <task> > gradle.log 2>&1
```

## Preferred Task Scope

Prefer:

```bash
./gradlew -q --console=plain --warning-mode=none :app:test --tests "com.example.MyTest" > gradle.log 2>&1
./gradlew -q --console=plain --warning-mode=none :service:compileJava > gradle.log 2>&1
```

Avoid broad commands unless necessary:

```bash
./gradlew build
./gradlew test
./gradlew check
```

## Wrapper Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR=".agent-logs"
LOG_FILE="$LOG_DIR/gradle.log"
mkdir -p "$LOG_DIR"

set +e
./gradlew -q --console=plain --warning-mode=none "$@" >"$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

echo "Exit code: $EXIT_CODE"

if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Status: SUCCESS"
  grep -E "^(BUILD SUCCESSFUL|[0-9]+ actionable tasks:)" "$LOG_FILE" | tail -n 2 || true
  exit 0
fi

echo "Status: FAILURE"
grep -E "^Execution failed for task " "$LOG_FILE" | head -n 10 || true
echo
tail -n 80 "$LOG_FILE"
echo
echo "Full log: $LOG_FILE"

exit "$EXIT_CODE"
```

## Return Format

### Success

```text
Exit code: 0
Status: SUCCESS
BUILD SUCCESSFUL in 4s
6 actionable tasks: 2 executed, 4 up-to-date
```

### Failure

```text
Exit code: 1
Status: FAILURE
Execution failed for task ':app:test'.

...last 80 lines...

Full log: .agent-logs/gradle.log
```

## Debugging Order

1. Run the narrowest task
2. Read the summary
3. Read the short tail on failure
4. Open the full log only if needed
5. Inspect test XML/reports when that is more useful than console output

## Common Artifacts

```text
build/test-results/test/
build/reports/tests/test/
build/reports/problems/
```

## Avoid

- streaming full Gradle output into model context
- using `--info`, `--debug`, or `--stacktrace` by default
- rerunning `build` repeatedly during tight loops
- pasting full stack traces unless specifically needed

## Rule of Thumb

**Capture everything, return only the minimum needed to decide the next step.**
