---
description: Review and refine a spec for cohesiveness and brevity.
---

Review and refine $AGRUMENTS for cohesiveness and brevity.

Goals:

- Preserve all approved product behavior, implementation contracts, invariants, API semantics, and acceptance criteria.
- Remove repetition across recommendations, invariants, non-goals, contracts, acceptance criteria, test strategy, risks, trade-offs, rollout, and success
  criteria.
- Remove stale details from prior revisions—especially unrelated negative cases that only reject designs the current spec no longer suggests.
- Prefer positive statements of the chosen behavior over exhaustive lists of what will not be built.
- Retain negative cases only when they directly protect scope, privacy, security, compatibility, or error semantics.
- Consolidate identical or overlapping types, interfaces, requirements, and verification steps where doing so does not change behavior.
- Standardize terminology and identify contradictions or mismatched ownership.
- Keep concrete schema, type, interface, route, error, concurrency, configuration, and testing contracts needed for implementation.

Process:

1.  Read the spec and its Git history to identify residue from earlier designs.
2.  State any assumptions or semantic conflicts before changing them.
3.  Edit the file directly, making the smallest changes needed for substantial compression.
4.  Do not introduce new product or architectural decisions merely to simplify the prose.
5.  Verify formatting and run the repository’s required validation command.

When finished, report:

- Original and final line/word counts.
- The main categories of duplication or stale material removed.
- Any unresolved contradictions or decisions needing owner input.
- Validation results.
