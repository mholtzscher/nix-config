#!/usr/bin/env node
import { readFile, mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import {
  compareBenchmarkSummaries,
  formatBenchmarkSummary,
  sha256,
  summarizeBenchmark,
  validateBenchmarkInputs,
} from "./lib.mjs";

const REPO_ROOT = resolve(import.meta.dirname, "../..");
const DEFAULT_EXTENSION_PATH = resolve(REPO_ROOT, "modules/home-manager/agents/files/pi/extensions/jev-test-value.ts");
const DEFAULT_ENDPOINT = "https://api.typesafe.ai/v1/systemone";
const DEFAULT_REPEATS = 3;
const DEFAULT_CONCURRENCY = 4;

function parseArguments(argv) {
  const options = {
    repeats: DEFAULT_REPEATS,
    concurrency: DEFAULT_CONCURRENCY,
    endpoint: DEFAULT_ENDPOINT,
    extension: DEFAULT_EXTENSION_PATH,
    out: resolve(import.meta.dirname, "runs/latest.json"),
  };
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    const value = argv[index + 1];
    if (argument === "--repeats") options.repeats = Number(value), index += 1;
    else if (argument === "--concurrency") options.concurrency = Number(value), index += 1;
    else if (argument === "--endpoint") options.endpoint = value, index += 1;
    else if (argument === "--model") options.model = value, index += 1;
    else if (argument === "--extension") options.extension = resolve(value), index += 1;
    else if (argument === "--out") options.out = resolve(value), index += 1;
    else if (argument === "--baseline") options.baseline = resolve(value), index += 1;
    else if (argument === "--help") options.help = true;
    else throw new Error(`Unknown argument: ${argument}`);
  }
  if (!Number.isInteger(options.repeats) || options.repeats < 1 || options.repeats > 20) throw new Error("--repeats must be an integer from 1 to 20");
  if (!Number.isInteger(options.concurrency) || options.concurrency < 1 || options.concurrency > 12) throw new Error("--concurrency must be an integer from 1 to 12");
  return options;
}

function usage() {
  return `Usage: node --experimental-strip-types benchmarks/test-value/run.mjs [options]\n\n` +
    `  --repeats N       Calls per fixture (default ${DEFAULT_REPEATS})\n` +
    `  --concurrency N   Maximum concurrent calls (default ${DEFAULT_CONCURRENCY})\n` +
    `  --endpoint URL    System One endpoint (default hosted Jev)\n` +
    `  --model ID        Explicit model override\n` +
    `  --extension PATH  Extension source to benchmark\n` +
    `  --out PATH        JSON artifact path\n` +
    `  --baseline PATH   Existing artifact to compare\n`;
}

async function loadActualTool(extensionPath, endpoint, model) {
  process.env.JEV_TEST_VALUE_API_URL = endpoint;
  if (model) process.env.JEV_TEST_VALUE_MODEL = model;
  else delete process.env.JEV_TEST_VALUE_MODEL;

  let capturedTool;
  const pi = {
    registerTool(tool) {
      if (tool.name === "evaluate_test_value") capturedTool = tool;
    },
  };
  const extensionUrl = `${pathToFileURL(extensionPath).href}?benchmark=${Date.now()}`;
  const extension = await import(extensionUrl);
  extension.default(pi);
  if (!capturedTool) throw new Error(`Extension did not register evaluate_test_value: ${extensionPath}`);
  return capturedTool;
}

async function runWithConcurrency(jobs, concurrency, worker) {
  const results = new Array(jobs.length);
  let nextIndex = 0;
  async function consume() {
    while (true) {
      const index = nextIndex;
      nextIndex += 1;
      if (index >= jobs.length) return;
      results[index] = await worker(jobs[index], index);
    }
  }
  await Promise.all(Array.from({ length: Math.min(concurrency, jobs.length) }, consume));
  return results;
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  if (options.help) {
    console.log(usage());
    return;
  }

  const corpusPath = resolve(import.meta.dirname, "fixtures/corpus.json");
  const labelsPath = resolve(import.meta.dirname, "fixtures/labels.json");
  const [corpusText, labelsText, extensionText] = await Promise.all([
    readFile(corpusPath, "utf8"),
    readFile(labelsPath, "utf8"),
    readFile(options.extension, "utf8"),
  ]);
  const corpus = JSON.parse(corpusText);
  const labels = JSON.parse(labelsText);
  validateBenchmarkInputs(corpus, labels);

  let baselineArtifact;
  let baselineSummary;
  if (options.baseline) {
    baselineArtifact = JSON.parse(await readFile(options.baseline, "utf8"));
    if (baselineArtifact.schemaVersion !== 1 || !Array.isArray(baselineArtifact.records)) {
      throw new Error("Unsupported or incomplete baseline artifact");
    }
    if (baselineArtifact.corpusHash !== sha256(corpusText) || baselineArtifact.labelsHash !== sha256(labelsText)) {
      throw new Error("Fixture corpus or labels differ from the baseline; capture a new baseline instead of comparing incompatible runs");
    }
    if (baselineArtifact.repeats !== options.repeats) {
      throw new Error(`Repeat count differs from baseline: baseline=${baselineArtifact.repeats} candidate=${options.repeats}`);
    }
    for (const fixture of corpus) {
      const baselineRunCount = baselineArtifact.records.filter((record) => record.fixtureId === fixture.id).length;
      if (baselineRunCount !== baselineArtifact.repeats) {
        throw new Error(`Baseline has ${baselineRunCount} records for ${fixture.id}; expected ${baselineArtifact.repeats}`);
      }
    }
    try {
      baselineSummary = summarizeBenchmark(corpus, labels, baselineArtifact.records);
    } catch (error) {
      throw new Error(`Baseline records cannot be summarized: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  const tool = await loadActualTool(options.extension, options.endpoint, options.model);
  const jobs = corpus.flatMap((fixture) =>
    Array.from({ length: options.repeats }, (_, repeat) => ({ fixture, repeat: repeat + 1 })),
  );
  let completed = 0;
  const records = await runWithConcurrency(jobs, options.concurrency, async ({ fixture, repeat }) => {
    const startedAt = performance.now();
    try {
      const controller = new AbortController();
      const result = await tool.execute(
        `benchmark-${fixture.id}-${repeat}`,
        options.model ? { ...fixture.params, model: options.model } : fixture.params,
        controller.signal,
        undefined,
        { cwd: REPO_ROOT },
      );
      const details = result.details;
      if (!details?.report || !details?.answers || !details?.testKind) {
        throw new Error("Tool result omitted structured report, answers, or testKind details");
      }
      return {
        fixtureId: fixture.id,
        repeat,
        latencyMs: Math.round(performance.now() - startedAt),
        ok: true,
        report: details.report,
        testKind: details.testKind,
        answers: details.answers,
        renderedText: result.content?.find((item) => item.type === "text")?.text,
      };
    } catch (error) {
      return {
        fixtureId: fixture.id,
        repeat,
        latencyMs: Math.round(performance.now() - startedAt),
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      };
    } finally {
      completed += 1;
      process.stderr.write(`\rEvaluated ${completed}/${jobs.length}`);
    }
  });
  process.stderr.write("\n");

  const summary = summarizeBenchmark(corpus, labels, records);
  let comparison;
  let comparisonError;
  if (baselineArtifact) {
    const baselineModels = baselineSummary.modelVersions;
    if (summary.modelVersions.length === 0) {
      comparisonError = "Candidate produced no successful model responses; inspect the recorded call errors.";
    } else if (baselineModels.join(",") !== summary.modelVersions.join(",")) {
      comparisonError = `Resolved model mismatch: baseline=${baselineModels.join(",")} candidate=${summary.modelVersions.join(",")}`;
    } else {
      comparison = compareBenchmarkSummaries(baselineSummary, summary);
    }
  }

  const artifact = {
    schemaVersion: 1,
    createdAt: new Date().toISOString(),
    endpoint: options.endpoint,
    requestedModel: options.model ?? null,
    repeats: options.repeats,
    concurrency: options.concurrency,
    extensionPath: options.extension,
    extensionHash: sha256(extensionText),
    corpusHash: sha256(corpusText),
    labelsHash: sha256(labelsText),
    summary,
    records,
    comparison: comparison ?? null,
    comparisonError: comparisonError ?? null,
  };
  await mkdir(dirname(options.out), { recursive: true });
  await writeFile(options.out, `${JSON.stringify(artifact, null, 2)}\n`);
  console.log(formatBenchmarkSummary(summary, comparison));
  if (comparisonError) console.error(`\nBaseline comparison unavailable: ${comparisonError}`);
  console.log(`\nArtifact: ${options.out}`);

  if (summary.errorRate > 0 || comparison?.passed === false || comparisonError) process.exitCode = 1;
}

await main();
