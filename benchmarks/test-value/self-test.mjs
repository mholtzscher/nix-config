#!/usr/bin/env node
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { resolve } from "node:path";
import {
  compareBenchmarkSummaries,
  mean,
  percentile,
  sampleStandardDeviation,
  spearmanCorrelation,
  summarizeBenchmark,
  validateBenchmarkInputs,
} from "./lib.mjs";
import { buildTestValueReport } from "../../modules/home-manager/agents/files/pi/extensions/jev-test-value.ts";

const corpus = JSON.parse(await readFile(resolve(import.meta.dirname, "fixtures/corpus.json"), "utf8"));
const labels = JSON.parse(await readFile(resolve(import.meta.dirname, "fixtures/labels.json"), "utf8"));
validateBenchmarkInputs(corpus, labels);

const corpusWithLeak = structuredClone(corpus);
corpusWithLeak[0].params.tier = 1;
assert.throws(() => validateBenchmarkInputs(corpusWithLeak, labels), /unexpected params/);
const labelsWithBadKind = structuredClone(labels);
labelsWithBadKind[0].expectedTestKind = "nonsense";
assert.throws(() => validateBenchmarkInputs(corpus, labelsWithBadKind), /expectedTestKind/);
const labelsWithBadRisk = structuredClone(labels);
labelsWithBadRisk[0].riskExpectations.typo = { min: 20 };
assert.throws(() => validateBenchmarkInputs(corpus, labelsWithBadRisk), /Unknown risk expectation/);
const labelsWithContradiction = structuredClone(labels);
labelsWithContradiction[0].riskExpectations.tautology = { min: 90, max: 10 };
assert.throws(() => validateBenchmarkInputs(corpus, labelsWithContradiction), /contradictory/);

assert.equal(mean([1, 2, 3]), 2);
assert.equal(sampleStandardDeviation([1, 2, 3]), 1);
assert.equal(percentile([9, 1, 5], 0.5), 5);
assert.equal(spearmanCorrelation([1, 2, 3, 4], [10, 20, 30, 40]), 1);
assert.equal(spearmanCorrelation([1, 2, 3, 4], [40, 30, 20, 10]), -1);

const answerNames = {
  tautology: "tautological",
  falseConfidence: "false_confidence",
  implementationCoupling: "implementation_coupling",
  flakiness: "flakiness_risk",
  mutationSurvival: "mutation_survival",
};
const records = labels.flatMap((label) => {
  const meanScore = Math.round((label.scoreRange[0] + label.scoreRange[1]) / 2);
  const answers = Object.fromEntries(
    Object.entries(label.riskExpectations).map(([riskName, expectation]) => {
      const percent = expectation.min !== undefined ? Math.min(100, expectation.min + 1) : Math.max(0, (expectation.max ?? 50) - 1);
      return [answerNames[riskName], { type: "noul", noul: percent / 100 }];
    }),
  );
  answers.overall_value = {
    type: "choice",
    choice: label.acceptableVerdicts[0].replace("-", "_"),
    confidence: 0.9,
  };
  return [1, 2, 3].map((repeat) => ({
    fixtureId: label.fixtureId,
    repeat,
    latencyMs: 100 + repeat,
    ok: true,
    report: {
      overallScore: meanScore,
      verdict: label.acceptableVerdicts[0],
      model: "jev-test",
      provider: "hosted-jev",
    },
    testKind: label.expectedTestKind,
    answers,
  }));
});

const invalidVerdictRecords = structuredClone(records);
invalidVerdictRecords[0].report.verdict = "high_value";
assert.throws(() => summarizeBenchmark(corpus, labels, invalidVerdictRecords), /invalid verdict/);

const summary = summarizeBenchmark(corpus, labels, records);
assert.equal(summary.successfulRuns, 36);
assert.equal(summary.errorRate, 0);
assert.equal(summary.scoreRangeAccuracy, 1);
assert.equal(summary.verdictAccuracy, 1);
assert.equal(summary.testKindAccuracy, 1);
assert.equal(summary.riskExpectationAccuracy, 1);
assert.equal(summary.weakTestRecall, 1);
assert.equal(summary.strongTestRetention, 1);
assert.equal(summary.repeatability.maximumFixtureRange, 0);
assert.ok(summary.tierScoreSpearman > 0.9);

const firstFixtureId = labels[0].fixtureId;
const tiedRecords = records
  .filter((record) => record.fixtureId !== firstFixtureId || record.repeat <= 2)
  .map((record) => record.fixtureId === firstFixtureId
    ? {
        ...record,
        answers: {
          ...record.answers,
          overall_value: {
            type: "choice",
            choice: record.repeat === 1 ? "low_value" : "high_value",
            confidence: 0.9,
          },
        },
      }
    : record);
const tiedSummary = summarizeBenchmark(corpus, labels, tiedRecords);
assert.equal(tiedSummary.perFixture.find((fixture) => fixture.fixtureId === firstFixtureId).majorityVerdict, null);
assert.equal(tiedSummary.perFixture.find((fixture) => fixture.fixtureId === firstFixtureId).verdictPassed, false);

const missingFixtureSummary = summarizeBenchmark(corpus, labels, records.filter((record) => record.fixtureId !== firstFixtureId));
const missingFixture = missingFixtureSummary.perFixture.find((fixture) => fixture.fixtureId === firstFixtureId);
assert.equal(missingFixture.scoreRangePassed, false);
assert.equal(missingFixture.verdictPassed, false);
assert.ok(missingFixtureSummary.weakTestRecall < 1);
assert.ok(missingFixtureSummary.scoreRangeAccuracy < 1);

const firstStrongFixtureId = labels.find((label) => label.tier >= 4).fixtureId;
const missingStrongSummary = summarizeBenchmark(corpus, labels, records.filter((record) => record.fixtureId !== firstStrongFixtureId));
assert.ok(missingStrongSummary.strongTestRetention < 1);

const missingRisks = structuredClone(records);
for (const record of missingRisks.filter((item) => item.fixtureId === firstFixtureId)) {
  const { overall_value, flakiness_risk } = record.answers;
  record.answers = { overall_value, flakiness_risk };
}
const missingRiskFixture = summarizeBenchmark(corpus, labels, missingRisks).perFixture.find((fixture) => fixture.fixtureId === firstFixtureId);
assert.equal(missingRiskFixture.riskChecksPassed, 1);

function syntheticJevResponse(overallChoice = "high_value") {
  const score = { type: "score", score: 3, confidence: 0.8, legend: { 3: "strong" } };
  const noul = { type: "noul", noul: 0.1 };
  return {
    model: "jev-test",
    answers: {
      fault_detection: score,
      oracle_quality: score,
      behavior_relevance: score,
      boundary_coverage: score,
      maintainability: score,
      tautological: noul,
      false_confidence: noul,
      implementation_coupling: noul,
      flakiness_risk: noul,
      mutation_survival: noul,
      overall_value: { type: "choice", choice: overallChoice, confidence: 0.8 },
    },
  };
}

const reportWithProduction = buildTestValueReport(syntheticJevResponse(), true);
assert.equal(reportWithProduction.verdict, "high-value");
assert.equal(reportWithProduction.modelVerdict, "high_value");
assert.equal(reportWithProduction.diagnosticVerdict, "useful");
assert.equal(reportWithProduction.confidence, 80);
assert.equal(reportWithProduction.diagnosticConfidence, 80);

const reportWithoutProduction = buildTestValueReport(syntheticJevResponse(), false);
assert.equal(reportWithoutProduction.confidence, 60);
assert.match(reportWithoutProduction.limitations[0], /discounted by 25%/);

for (const [modelChoice, expectedVerdict] of [
  ["low_value", "low-value"],
  ["questionable", "questionable"],
  ["useful", "useful"],
  ["high_value", "high-value"],
  ["insufficient_context", "questionable"],
]) {
  assert.equal(buildTestValueReport(syntheticJevResponse(modelChoice), true).verdict, expectedVerdict);
}
const insufficientReport = buildTestValueReport(syntheticJevResponse("insufficient_context"), true);
assert.match(insufficientReport.limitations[0], /insufficient/);

const flakyResponse = syntheticJevResponse("useful");
flakyResponse.answers.flakiness_risk = { type: "noul", noul: 0.7 };
const flakyReport = buildTestValueReport(flakyResponse, true);
assert.equal(flakyReport.verdict, "questionable");
assert.match(flakyReport.limitations[0], /flakiness risk/);

const belowFlakinessCapResponse = syntheticJevResponse("useful");
belowFlakinessCapResponse.answers.flakiness_risk = { type: "noul", noul: 0.69 };
assert.equal(buildTestValueReport(belowFlakinessCapResponse, true).verdict, "useful");

assert.throws(() => buildTestValueReport(syntheticJevResponse("unexpected"), true), /unknown overall_value choice/);

const unchanged = compareBenchmarkSummaries(summary, structuredClone(summary));
assert.equal(unchanged.passed, true);

const boundaryNoise = structuredClone(summary);
const boundaryNoiseRisk = boundaryNoise.perFixture[0].risks.tautology;
boundaryNoiseRisk.mean = boundaryNoiseRisk.expectation.min - 2;
boundaryNoiseRisk.passed = false;
assert.equal(compareBenchmarkSummaries(summary, boundaryNoise).passed, true);

const materialRiskRegression = structuredClone(summary);
const materialRisk = materialRiskRegression.perFixture[0].risks.tautology;
materialRisk.mean = materialRisk.expectation.min - 4;
materialRisk.passed = false;
assert.equal(compareBenchmarkSummaries(summary, materialRiskRegression).passed, false);

const regressed = structuredClone(summary);
regressed.weakTestRecall -= 0.2;
assert.equal(compareBenchmarkSummaries(summary, regressed).passed, false);

console.log("test-value benchmark self-tests passed");
