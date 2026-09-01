---
description: Run relevant mutation tests and strengthen tests where they expose meaningful gaps
argument-hint: "[optional package, test, or change scope]"
---

Use mutation testing to assess the tests relevant to the current changes.

Scope the work to $ARGUMENTS when provided. Otherwise, inspect the working-tree diff and recent changes to identify the affected packages, production code, and tests.

1. Find mutation-testing commands, scripts, configuration, and repository instructions already present in the project. Use the configured tooling. Do not install or introduce a mutation-testing framework.
2. Run the focused ordinary tests first. Fix any existing test failures before interpreting mutation results.
3. Run mutation testing only for the affected packages and relevant tests when the tooling supports that scope. Avoid an unrelated repository-wide mutation run.
4. Review surviving mutants as evidence about test quality, not as a requirement to reach a perfect mutation score. Prioritize mutants that reveal missing checks of public behavior, important edge cases, error handling, state changes, or regressions related to the current work.
5. Add or improve tests only when they protect meaningful behavior. Do not add brittle implementation-detail assertions, duplicate existing coverage, weaken production code, or write tests whose only value is killing a mutant. Leave equivalent, unreachable, trivial, or low-value mutants alive when killing them would make the test suite worse.
6. Re-run the focused ordinary tests and relevant mutation command after changing tests.

If no mutation testing is configured, do not substitute coverage tooling or add new infrastructure. Report what you searched and stop after running the relevant ordinary tests.

When finished, report:

- The affected scope and mutation tooling found.
- Commands run and their results.
- Tests added or strengthened, with the behavior each protects.
- Mutation results before and after, when available.
- Important surviving mutants left intentionally, with a brief reason.
- Any failures, timeouts, or parts of the relevant scope that were not tested.
