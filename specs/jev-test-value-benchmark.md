# Jev Test-Value Effectiveness Benchmark

## Problem

Changes to the `evaluate_test_value` questions, aggregation, or provider can improve one example while silently degrading other languages or defect classes. We need a repeatable benchmark whose labels are independent of model output.

## Decision

Build a live, curated benchmark with 12 focused multilingual fixtures. The default command calls hosted Jev and evaluates every fixture three times. Live runs are explicit but are the benchmark's normal mode; deterministic self-tests remain offline.

This first version uses human-reviewed labels. Mutation-backed labels are intentionally deferred until the harness and prompts stabilize.

## Types

```ts
type Fixture = {
  id: string;
  language: string;
  params: {
    testCode: string;
    productionCode?: string;
    context?: string;
    language?: string;
  };
};

type CuratedLabel = {
  fixtureId: string;
  tier: 1 | 2 | 3 | 4 | 5;
  acceptableVerdicts: Array<"low-value" | "questionable" | "useful" | "high-value">;
  expectedTestKind: string;
  scoreRange: [number, number];
  riskExpectations: Record<string, { min?: number; max?: number }>;
  rationale: string;
};

type BenchmarkRecord = {
  fixtureId: string;
  repeat: number;
  latencyMs: number;
  ok: boolean;
  report?: TestValueReport;
  testKind?: string;
  answers?: Record<string, JevAnswer>;
  error?: string;
};
```

The model-visible corpus and hidden labels live in separate JSON files. The harness joins them only after all provider calls finish.

## Metrics

- Fixture score-range accuracy
- Acceptable-verdict accuracy
- Test-kind accuracy
- Risk-expectation accuracy using raw probabilities
- Weak-test recall for tiers 1–2
- Strong-test retention for tiers 4–5
- Spearman correlation between mean score and curated tier
- Repeatability: per-fixture score range and pooled standard deviation
- Provider/schema/error rate and latency percentiles

No single metric is treated as sufficient. Baseline comparison reports regressions per metric and per fixture.

## Layout

```text
benchmarks/test-value/
├── README.md                 # Usage, metrics, interpretation
├── fixtures/
│   ├── corpus.json           # Model-visible test inputs
│   └── labels.json           # Curated ground truth, never sent to provider
├── lib.mjs                   # Statistics, scoring, validation
├── run.mjs                   # Captures the actual registered Pi tool and runs it
├── self-test.mjs             # Offline harness/statistics checks
└── baselines/
    └── hosted-jev-*.json     # Versioned initial benchmark artifact
```

## Interfaces

```bash
node --experimental-strip-types benchmarks/test-value/self-test.mjs
node --experimental-strip-types benchmarks/test-value/run.mjs --repeats 3 --out /tmp/jev-benchmark.json
node --experimental-strip-types benchmarks/test-value/run.mjs --repeats 3 --baseline benchmarks/test-value/baselines/<file>.json
```

`run.mjs` dynamically imports the real extension and captures `evaluate_test_value` through a minimal `registerTool` adapter. It does not reimplement provider calls or aggregation.

## Acceptance criteria

1. All 12 fixtures invoke hosted Jev successfully and resolve a versioned Jev model.
2. Corpus and label sets have a one-to-one fixture ID mapping, with no labels in model-visible inputs.
3. Offline statistic/self-tests pass without credentials or network.
4. A baseline artifact records raw repeats, aggregate metrics, extension hash, corpus hash, resolved model, and timestamp.
5. The initial report includes all metrics above and preserves per-fixture results for future comparisons.
6. TypeScript extension checks and `./scripts/agent-validate.sh` pass.

## Non-goals

- Running live evaluations in normal Nix validation
- Treating curated labels as objective mutation evidence
- Establishing merge-blocking thresholds from only 12 fixtures
- Automatically applying configuration changes

## Risks

- Prompt overfitting: keep labels separate, use broad expectations, and add held-out/mutation-backed fixtures later.
- Hosted model drift: record the resolved model and refuse direct baseline comparison across resolved versions.
- Small sample size: report individual cases and multiple metrics; do not claim statistical significance.
- Cost/rate limits: bound concurrency and default to three repeats.
