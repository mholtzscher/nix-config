import { createHash } from "node:crypto";

export const VERDICTS = ["low-value", "questionable", "useful", "high-value"];
export const RISK_ANSWER_KEYS = {
  tautology: "tautological",
  falseConfidence: "false_confidence",
  implementationCoupling: "implementation_coupling",
  flakiness: "flakiness_risk",
  mutationSurvival: "mutation_survival",
};
const TEST_KINDS = new Set(["behavioral", "interaction", "structural", "smoke", "tautological", "insufficient_context"]);
const MODEL_CHOICE_TO_VERDICT = {
  high_value: "high-value",
  useful: "useful",
  questionable: "questionable",
  low_value: "low-value",
  insufficient_context: "questionable",
};
const CORPUS_PARAM_KEYS = new Set(["testCode", "productionCode", "context", "language"]);

export function sha256(content) {
  return createHash("sha256").update(content).digest("hex");
}

export function mean(values) {
  return values.length === 0 ? 0 : values.reduce((sum, value) => sum + value, 0) / values.length;
}

export function sampleStandardDeviation(values) {
  if (values.length < 2) return 0;
  const average = mean(values);
  return Math.sqrt(values.reduce((sum, value) => sum + (value - average) ** 2, 0) / (values.length - 1));
}

export function percentile(values, probability) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.ceil(probability * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(sorted.length - 1, index))];
}

function averageRanks(values) {
  const indexed = values.map((value, index) => ({ value, index })).sort((a, b) => a.value - b.value);
  const ranks = new Array(values.length);
  for (let start = 0; start < indexed.length;) {
    let end = start + 1;
    while (end < indexed.length && indexed[end].value === indexed[start].value) end += 1;
    const averageRank = (start + 1 + end) / 2;
    for (let position = start; position < end; position += 1) ranks[indexed[position].index] = averageRank;
    start = end;
  }
  return ranks;
}

export function spearmanCorrelation(left, right) {
  if (left.length !== right.length || left.length < 2) return 0;
  const leftRanks = averageRanks(left);
  const rightRanks = averageRanks(right);
  const leftMean = mean(leftRanks);
  const rightMean = mean(rightRanks);
  let covariance = 0;
  let leftVariance = 0;
  let rightVariance = 0;
  for (let index = 0; index < leftRanks.length; index += 1) {
    const leftDelta = leftRanks[index] - leftMean;
    const rightDelta = rightRanks[index] - rightMean;
    covariance += leftDelta * rightDelta;
    leftVariance += leftDelta ** 2;
    rightVariance += rightDelta ** 2;
  }
  const denominator = Math.sqrt(leftVariance * rightVariance);
  return denominator === 0 ? 0 : covariance / denominator;
}

export function validateBenchmarkInputs(corpus, labels) {
  if (!Array.isArray(corpus) || !Array.isArray(labels)) throw new Error("Benchmark corpus and labels must be JSON arrays");
  if (corpus.length !== 12 || labels.length !== 12) throw new Error("Benchmark requires exactly 12 corpus fixtures and 12 labels");

  const corpusIds = new Set();
  for (const fixture of corpus) {
    if (!fixture?.id || corpusIds.has(fixture.id)) throw new Error(`Duplicate or missing corpus fixture id: ${fixture?.id}`);
    corpusIds.add(fixture.id);
    const keys = Object.keys(fixture).sort().join(",");
    if (keys !== "id,language,params") throw new Error(`Corpus fixture ${fixture.id} contains label-like fields: ${keys}`);
    if (typeof fixture.params?.testCode !== "string" || fixture.params.testCode.trim() === "") {
      throw new Error(`Corpus fixture ${fixture.id} has no testCode`);
    }
    for (const key of ["productionCode", "context", "language"]) {
      if (fixture.params[key] !== undefined && typeof fixture.params[key] !== "string") {
        throw new Error(`Corpus fixture ${fixture.id} has non-string ${key}`);
      }
    }
    const unexpectedParams = Object.keys(fixture.params).filter((key) => !CORPUS_PARAM_KEYS.has(key));
    if (unexpectedParams.length > 0) throw new Error(`Corpus fixture ${fixture.id} contains unexpected params: ${unexpectedParams.join(",")}`);
  }

  const labelIds = new Set();
  for (const label of labels) {
    if (!label?.fixtureId || labelIds.has(label.fixtureId)) throw new Error(`Duplicate or missing label fixture id: ${label?.fixtureId}`);
    labelIds.add(label.fixtureId);
    if (!Number.isInteger(label.tier) || label.tier < 1 || label.tier > 5) throw new Error(`Invalid tier for ${label.fixtureId}`);
    if (!Array.isArray(label.scoreRange) || label.scoreRange.length !== 2 || label.scoreRange.some((value) => !Number.isFinite(value)) || label.scoreRange[0] > label.scoreRange[1]) {
      throw new Error(`Invalid scoreRange for ${label.fixtureId}`);
    }
    if (!Array.isArray(label.acceptableVerdicts) || label.acceptableVerdicts.length === 0 || label.acceptableVerdicts.some((value) => !VERDICTS.includes(value))) {
      throw new Error(`Invalid acceptableVerdicts for ${label.fixtureId}`);
    }
    if (!TEST_KINDS.has(label.expectedTestKind)) throw new Error(`Invalid expectedTestKind for ${label.fixtureId}`);
    if (typeof label.rationale !== "string" || label.rationale.trim() === "") throw new Error(`Missing rationale for ${label.fixtureId}`);
    for (const [riskName, expectation] of Object.entries(label.riskExpectations ?? {})) {
      if (!(riskName in RISK_ANSWER_KEYS)) throw new Error(`Unknown risk expectation ${riskName} for ${label.fixtureId}`);
      const { min, max } = expectation;
      if (min === undefined && max === undefined) throw new Error(`Risk expectation ${riskName} has no bound for ${label.fixtureId}`);
      if ([min, max].some((value) => value !== undefined && (!Number.isFinite(value) || value < 0 || value > 100))) {
        throw new Error(`Risk expectation ${riskName} has an invalid bound for ${label.fixtureId}`);
      }
      if (min !== undefined && max !== undefined && min > max) throw new Error(`Risk expectation ${riskName} is contradictory for ${label.fixtureId}`);
    }
  }

  const missingLabels = [...corpusIds].filter((id) => !labelIds.has(id));
  const missingFixtures = [...labelIds].filter((id) => !corpusIds.has(id));
  if (missingLabels.length || missingFixtures.length) {
    throw new Error(`Fixture/label mismatch: missing labels=${missingLabels.join(",")} missing fixtures=${missingFixtures.join(",")}`);
  }
}

function rawRiskProbability(answers, riskName) {
  const answer = answers?.[RISK_ANSWER_KEYS[riskName]];
  return answer?.type === "noul" && Number.isFinite(answer.noul) ? answer.noul * 100 : undefined;
}

function benchmarkPrimaryVerdict(record) {
  const modelChoice = record.answers?.overall_value;
  if (modelChoice?.type !== "choice" || !(modelChoice.choice in MODEL_CHOICE_TO_VERDICT)) {
    throw new Error(`Benchmark record ${record.fixtureId} has invalid overall_value answer: ${modelChoice?.choice}`);
  }
  let verdict = MODEL_CHOICE_TO_VERDICT[modelChoice.choice];
  const flakiness = rawRiskProbability(record.answers, "flakiness");
  if (flakiness === undefined) throw new Error(`Benchmark record ${record.fixtureId} has no flakiness answer`);
  if (Math.round(flakiness) >= 70 && (verdict === "high-value" || verdict === "useful")) verdict = "questionable";
  return verdict;
}

function strictMajority(values, allowedValues) {
  if (values.length === 0) return undefined;
  const counts = new Map(allowedValues.map((value) => [value, 0]));
  for (const value of values) counts.set(value, (counts.get(value) ?? 0) + 1);
  const ordered = [...counts.entries()].sort((left, right) => right[1] - left[1]);
  return ordered[0][1] > values.length / 2 ? ordered[0][0] : undefined;
}

export function summarizeBenchmark(corpus, labels, records) {
  validateBenchmarkInputs(corpus, labels);
  const labelsById = new Map(labels.map((label) => [label.fixtureId, label]));
  const successful = records.filter((record) => record.ok);
  for (const record of successful) {
    if (!VERDICTS.includes(record.report?.verdict)) {
      throw new Error(`Benchmark record ${record.fixtureId} has invalid verdict: ${record.report?.verdict}`);
    }
  }
  const perFixture = corpus.map((fixture) => {
    const label = labelsById.get(fixture.id);
    const fixtureRecords = successful.filter((record) => record.fixtureId === fixture.id);
    const scores = fixtureRecords.map((record) => record.report.overallScore);
    const meanScore = mean(scores);
    const majorityVerdict = strictMajority(fixtureRecords.map(benchmarkPrimaryVerdict), VERDICTS) ?? null;
    const kinds = fixtureRecords.map((record) => record.testKind);
    const majorityKind = strictMajority(kinds, [...TEST_KINDS]) ?? null;
    const risks = {};
    const riskChecks = [];
    for (const [riskName, expectation] of Object.entries(label.riskExpectations ?? {})) {
      const values = fixtureRecords.map((record) => rawRiskProbability(record.answers, riskName)).filter(Number.isFinite);
      const value = values.length > 0 ? mean(values) : null;
      const passed = value !== null && (expectation.min === undefined || value >= expectation.min) && (expectation.max === undefined || value <= expectation.max);
      risks[riskName] = { mean: value, expectation, passed };
      riskChecks.push(passed);
    }
    return {
      fixtureId: fixture.id,
      language: fixture.language,
      tier: label.tier,
      runs: fixtureRecords.length,
      meanScore,
      scoreRange: scores.length ? Math.max(...scores) - Math.min(...scores) : 0,
      scoreStandardDeviation: sampleStandardDeviation(scores),
      expectedScoreRange: label.scoreRange,
      scoreRangePassed: fixtureRecords.length > 0 && meanScore >= label.scoreRange[0] && meanScore <= label.scoreRange[1],
      majorityVerdict,
      acceptableVerdicts: label.acceptableVerdicts,
      verdictPassed: majorityVerdict !== null && label.acceptableVerdicts.includes(majorityVerdict),
      majorityTestKind: majorityKind,
      expectedTestKind: label.expectedTestKind,
      testKindPassed: majorityKind === label.expectedTestKind,
      risks,
      riskChecksPassed: riskChecks.filter(Boolean).length,
      riskChecksTotal: riskChecks.length,
    };
  });

  const completedFixtures = perFixture.filter((fixture) => fixture.runs > 0);
  const weakFixtures = perFixture.filter((fixture) => fixture.tier <= 2);
  const strongFixtures = perFixture.filter((fixture) => fixture.tier >= 4);
  const isFlagged = (fixture) => fixture.majorityVerdict === "low-value" || fixture.majorityVerdict === "questionable";
  const isRetained = (fixture) => fixture.majorityVerdict === "useful" || fixture.majorityVerdict === "high-value";
  const allRiskChecks = perFixture.flatMap((fixture) => Object.values(fixture.risks));
  const scoreStandardDeviations = completedFixtures.map((fixture) => fixture.scoreStandardDeviation);
  const modelVersions = [...new Set(successful.map((record) => record.report.model))];
  const providers = [...new Set(successful.map((record) => record.report.provider))];
  const latencies = successful.map((record) => record.latencyMs);

  return {
    fixtureCount: corpus.length,
    requestedRuns: records.length,
    successfulRuns: successful.length,
    errorRate: records.length === 0 ? 1 : (records.length - successful.length) / records.length,
    providers,
    modelVersions,
    scoreRangeAccuracy: mean(perFixture.map((fixture) => Number(fixture.scoreRangePassed))),
    verdictAccuracy: mean(perFixture.map((fixture) => Number(fixture.verdictPassed))),
    testKindAccuracy: mean(perFixture.map((fixture) => Number(fixture.testKindPassed))),
    riskExpectationAccuracy: mean(allRiskChecks.map((check) => Number(check.passed))),
    weakTestRecall: mean(weakFixtures.map((fixture) => Number(isFlagged(fixture)))),
    strongTestRetention: mean(strongFixtures.map((fixture) => Number(isRetained(fixture)))),
    tierScoreSpearman: spearmanCorrelation(
      completedFixtures.map((fixture) => fixture.tier),
      completedFixtures.map((fixture) => fixture.meanScore),
    ),
    repeatability: {
      pooledStandardDeviation: Math.sqrt(mean(scoreStandardDeviations.map((value) => value ** 2))),
      maximumFixtureRange: Math.max(0, ...completedFixtures.map((fixture) => fixture.scoreRange)),
      verdictFlipRate: mean(
        completedFixtures.map((fixture) => {
          const fixtureVerdicts = new Set(successful.filter((record) => record.fixtureId === fixture.fixtureId).map(benchmarkPrimaryVerdict));
          return Number(fixtureVerdicts.size > 1);
        }),
      ),
    },
    latencyMs: {
      p50: percentile(latencies, 0.5),
      p95: percentile(latencies, 0.95),
      maximum: Math.max(0, ...latencies),
    },
    perFixture,
  };
}

function riskExpectationMiss(check) {
  if (!check || check.mean === null) return Number.POSITIVE_INFINITY;
  if (check.expectation.min !== undefined && check.mean < check.expectation.min) return check.expectation.min - check.mean;
  if (check.expectation.max !== undefined && check.mean > check.expectation.max) return check.mean - check.expectation.max;
  return 0;
}

export function compareBenchmarkSummaries(baseline, candidate) {
  const checks = [
    ["scoreRangeAccuracy", baseline.scoreRangeAccuracy, candidate.scoreRangeAccuracy, -0.1],
    ["verdictAccuracy", baseline.verdictAccuracy, candidate.verdictAccuracy, -0.1],
    ["testKindAccuracy", baseline.testKindAccuracy, candidate.testKindAccuracy, -0.1],
    ["riskExpectationAccuracy", baseline.riskExpectationAccuracy, candidate.riskExpectationAccuracy, -0.1],
    ["weakTestRecall", baseline.weakTestRecall, candidate.weakTestRecall, -0.1],
    ["strongTestRetention", baseline.strongTestRetention, candidate.strongTestRetention, -0.1],
    ["tierScoreSpearman", baseline.tierScoreSpearman, candidate.tierScoreSpearman, -0.1],
    ["repeatability.pooledStandardDeviation", baseline.repeatability.pooledStandardDeviation, candidate.repeatability.pooledStandardDeviation, -1],
    ["repeatability.maximumFixtureRange", baseline.repeatability.maximumFixtureRange, candidate.repeatability.maximumFixtureRange, -3],
    ["repeatability.verdictFlipRate", baseline.repeatability.verdictFlipRate, candidate.repeatability.verdictFlipRate, -0.1],
  ].map(([metric, baselineValue, candidateValue, minimumImprovement]) => {
    const improvement = metric.startsWith("repeatability") ? baselineValue - candidateValue : candidateValue - baselineValue;
    return { metric, baseline: baselineValue, candidate: candidateValue, delta: candidateValue - baselineValue, passed: improvement >= minimumImprovement };
  });

  const baselineFixtures = new Map(baseline.perFixture.map((fixture) => [fixture.fixtureId, fixture]));
  const fixtureChecks = candidate.perFixture.map((fixture) => {
    const previous = baselineFixtures.get(fixture.fixtureId);
    const regressions = [];
    if (!previous) regressions.push("missing baseline fixture");
    else {
      if (previous.scoreRangePassed && !fixture.scoreRangePassed) regressions.push("score range regressed");
      if (previous.verdictPassed && !fixture.verdictPassed) regressions.push("verdict regressed");
      if (previous.testKindPassed && !fixture.testKindPassed) regressions.push("test kind regressed");
      for (const [riskName, previousRisk] of Object.entries(previous.risks)) {
        if (previousRisk.passed && riskExpectationMiss(fixture.risks[riskName]) > 3) {
          regressions.push(`${riskName} expectation regressed by more than 3 points`);
        }
      }
    }
    return { fixtureId: fixture.fixtureId, passed: regressions.length === 0, regressions };
  });
  return { passed: checks.every((check) => check.passed) && fixtureChecks.every((check) => check.passed), checks, fixtureChecks };
}

export function formatBenchmarkSummary(summary, comparison) {
  const percent = (value) => `${(value * 100).toFixed(1)}%`;
  const lines = [
    `Provider: ${summary.providers.join(", ") || "none"}; model: ${summary.modelVersions.join(", ") || "none"}`,
    `Runs: ${summary.successfulRuns}/${summary.requestedRuns}; errors: ${percent(summary.errorRate)}`,
    `Score range accuracy: ${percent(summary.scoreRangeAccuracy)}`,
    `Verdict accuracy: ${percent(summary.verdictAccuracy)}`,
    `Test-kind accuracy: ${percent(summary.testKindAccuracy)}`,
    `Risk expectation accuracy: ${percent(summary.riskExpectationAccuracy)}`,
    `Weak-test recall: ${percent(summary.weakTestRecall)}`,
    `Strong-test retention: ${percent(summary.strongTestRetention)}`,
    `Tier/score Spearman: ${summary.tierScoreSpearman.toFixed(3)}`,
    `Repeatability: pooled SD ${summary.repeatability.pooledStandardDeviation.toFixed(2)}, max range ${summary.repeatability.maximumFixtureRange}, verdict flips ${percent(summary.repeatability.verdictFlipRate)}`,
    `Latency: p50 ${summary.latencyMs.p50}ms, p95 ${summary.latencyMs.p95}ms, max ${summary.latencyMs.maximum}ms`,
    "",
    "Per fixture:",
    ...summary.perFixture.map(
      (fixture) =>
        `- ${fixture.fixtureId}: ${fixture.meanScore.toFixed(1)} (${fixture.majorityVerdict ?? "no majority"}, ${fixture.majorityTestKind ?? "no majority"}); score=${fixture.scoreRangePassed ? "✓" : "✗"} verdict=${fixture.verdictPassed ? "✓" : "✗"} kind=${fixture.testKindPassed ? "✓" : "✗"} risks=${fixture.riskChecksPassed}/${fixture.riskChecksTotal}`,
    ),
  ];
  if (comparison) {
    lines.push("", `Baseline comparison: ${comparison.passed ? "PASS" : "REGRESSION"}`);
    for (const check of comparison.checks) {
      lines.push(`- ${check.metric}: ${(check.delta >= 0 ? "+" : "") + check.delta.toFixed(3)} ${check.passed ? "✓" : "✗"}`);
    }
    for (const check of comparison.fixtureChecks.filter((fixture) => !fixture.passed)) {
      lines.push(`- ${check.fixtureId}: ${check.regressions.join(", ")} ✗`);
    }
  }
  return lines.join("\n");
}
