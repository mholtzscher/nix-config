# Test-value effectiveness benchmark

This benchmark measures how well the `evaluate_test_value` Pi tool distinguishes meaningful regression protection from tautological, weak, brittle, or flaky tests.

It invokes the **actual registered extension tool** rather than duplicating its provider request or aggregation code.

## Corpus

`fixtures/corpus.json` contains 12 synthetic, model-visible test reviews across 12 languages. `fixtures/labels.json` contains independent, curated expectations and is loaded only after provider calls complete.

The first corpus intentionally uses broad score bands. These labels are review judgments, not mutation evidence. Future versions should add held-out and mutation-backed fixtures before benchmark results become merge gates.

## Run

Install the extension's development dependencies once after a fresh clone, then run the offline harness checks:

```bash
npm --prefix modules/home-manager/agents/files/pi/extensions install
node --experimental-strip-types benchmarks/test-value/self-test.mjs
```

Hosted Jev benchmark (default, 36 calls):

```bash
node --experimental-strip-types benchmarks/test-value/run.mjs \
  --repeats 3 \
  --out benchmarks/test-value/runs/hosted-jev.json
```

The extension resolves the hosted key through `TYPESAFE_API_KEY` or `~/.local/share/agenix/typesafe-api-key`. Custom non-TypeSafe HTTPS endpoints require `JEV_TEST_VALUE_API_KEY`.

Local Kev comparison:

```bash
node --experimental-strip-types benchmarks/test-value/run.mjs \
  --endpoint http://127.0.0.1:8009/v1/systemone \
  --repeats 3 \
  --out benchmarks/test-value/runs/local-kev.json
```

Compare a candidate with a compatible baseline:

```bash
node --experimental-strip-types benchmarks/test-value/run.mjs \
  --repeats 3 \
  --baseline benchmarks/test-value/baselines/2026-09-19-hosted-jev-1.13.0.json \
  --out benchmarks/test-value/runs/candidate.json
```

Comparison is refused when the resolved model, corpus hash, label hash, or repeat count differs.

## Metrics

- **Score-range accuracy:** mean secondary diagnostic score falls within the broad curated band.
- **Verdict accuracy:** majority primary System One `overall_value` classification is one of the accepted verdicts.
- **Test-kind accuracy:** majority kind matches behavioral, structural, interaction, smoke, or tautological expectations.
- **Risk-expectation accuracy:** raw Jev probabilities satisfy fixture-specific minimum or maximum bounds.
- **Weak-test recall:** tier 1–2 fixtures are classified `low-value` or `questionable`.
- **Strong-test retention:** tier 4–5 fixtures avoid `low-value` and `questionable`.
- **Tier/score Spearman:** ordinal correlation between curated tiers and mean scores.
- **Repeatability:** pooled score standard deviation, maximum per-fixture range, and verdict-flip rate.
- **Operational:** error rate and latency percentiles.

The primary verdict comes directly from the model. The numeric score remains an extension-defined diagnostic assembled from independent quality and risk answers. No single metric establishes effectiveness; always inspect the per-fixture report.

## Regression policy

The initial comparator allows up to a 0.10 absolute decline in each aggregate effectiveness metric. A previously passing per-fixture risk expectation regresses only when its mean misses the labelled bound by more than three percentage points; this prevents three-repeat sampling noise at an exact boundary from failing a candidate. A suspected regression should still be reproduced in a second run before changing the extension.

These thresholds are intentionally permissive because the corpus is small. Do not tune fixture labels or score bands after seeing candidate output merely to make a change pass.

## Adding fixtures

1. Add only test, production, language, and review context to `corpus.json`.
2. Add the independent judgment to `labels.json` under the same ID.
3. Explain the protected behavior and plausible defect in the label rationale.
4. Keep expectations broad unless backed by executable mutation evidence.
5. Update the exact corpus-size invariant in `validateBenchmarkInputs` when expanding beyond the initial 12 cases.
6. Capture a new baseline because corpus and label hashes changed.

Never use `evaluate_test_value` to author its own ground-truth labels.
