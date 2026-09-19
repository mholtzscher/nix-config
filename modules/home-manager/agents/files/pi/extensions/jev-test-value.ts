import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { Type } from "@sinclair/typebox";

const HOSTED_JEV_API_URL = "https://api.typesafe.ai/v1/systemone";
const TEST_VALUE_API_URL = process.env.JEV_TEST_VALUE_API_URL?.trim() || HOSTED_JEV_API_URL;
const CONFIGURED_TEST_VALUE_MODEL = process.env.JEV_TEST_VALUE_MODEL?.trim();
const DEFAULT_SECRET_PATH = join(homedir(), ".local", "share", "agenix", "typesafe-api-key");
const LOCAL_MAX_STATE_CHARACTERS = 15_000;
const HOSTED_MAX_STATE_CHARACTERS = 150_000;
const REQUEST_TIMEOUT_MS = 10_000;
const MAX_REQUEST_ATTEMPTS = 3;

const TEST_VALUE_PARAMETERS = Type.Object(
  {
    testCode: Type.String({
      minLength: 1,
      description: "The complete test or focused test diff to evaluate.",
    }),
    productionCode: Type.Optional(
      Type.String({
        description: "Relevant production code or production diff. Strongly recommended for fault-detection judgments.",
      }),
    ),
    context: Type.Optional(
      Type.String({
        description: "Bug report, requirement, test output, framework details, or review context needed to understand intent.",
      }),
    ),
    language: Type.Optional(Type.String({ description: "Programming language and test framework, if known." })),
    model: Type.Optional(
      Type.String({
        description: "System One model identifier. Defaults to kev-latest for local Kev and jev-latest for hosted Jev.",
      }),
    ),
  },
  { additionalProperties: false },
);

type JevNoulAnswer = { type: "noul"; noul: number };
type JevScoreAnswer = {
  type: "score";
  score: number;
  confidence?: number;
  legend?: Record<string, string>;
  probabilities?: Record<string, number>;
};
type JevChoiceAnswer = {
  type: "choice";
  choice: string;
  confidence?: number;
  probabilities?: Record<string, number>;
};
type JevAnswer = JevNoulAnswer | JevScoreAnswer | JevChoiceAnswer;
type JevResponse = {
  model: string;
  answers: Record<string, JevAnswer>;
  usage?: { input_tokens?: number; output_tokens?: number };
};

class JevNonRetryableRequestError extends Error {}

type TestValueMetric = {
  score: number;
  confidence: number;
  rationale: string;
};

type TestValueVerdict = "high-value" | "useful" | "questionable" | "low-value";

type TestValueReport = {
  verdict: TestValueVerdict;
  modelVerdict: string;
  diagnosticVerdict: TestValueVerdict;
  overallScore: number;
  confidence: number;
  diagnosticConfidence: number;
  metrics: Record<string, TestValueMetric>;
  risks: Record<string, number>;
  model: string;
  provider: "local-kev" | "hosted-jev" | "custom-system-one";
  providerUsage?: JevResponse["usage"];
  limitations: string[];
};

const VALUE_SCORE_LEVELS = [
  "0: absent or actively misleading",
  "1: weak; catches only trivial mistakes",
  "2: useful but incomplete",
  "3: strong; catches realistic regressions",
  "4: exceptional; precise, robust, and hard to fool",
];

const TEST_VALUE_QUESTIONS = {
  fault_detection: {
    type: "score",
    instructions: "How likely is this test to fail for a realistic defect in the behavior it claims to protect, while passing for a correct implementation?",
    criteria: VALUE_SCORE_LEVELS,
  },
  oracle_quality: {
    type: "score",
    instructions: "How strongly do the assertions distinguish correct observable behavior from incorrect behavior? Penalize snapshots or assertions that merely repeat setup values.",
    criteria: VALUE_SCORE_LEVELS,
  },
  behavior_relevance: {
    type: "score",
    instructions: "How directly does this test protect user-visible, contract-level, or otherwise meaningful behavior rather than incidental implementation details?",
    criteria: VALUE_SCORE_LEVELS,
  },
  boundary_coverage: {
    type: "score",
    instructions: "How well does the test exercise meaningful boundaries, failure modes, state transitions, or interactions that are plausible sources of defects? Do not reward irrelevant extra cases.",
    criteria: VALUE_SCORE_LEVELS,
  },
  maintainability: {
    type: "score",
    instructions: "How readable, deterministic, focused, and resistant to harmless refactoring is this test? Penalize unexplained fixtures, timing dependence, and excessive mocking.",
    criteria: VALUE_SCORE_LEVELS,
  },
  tautological: {
    type: "noul",
    instructions: "Is the test tautological—does it primarily assert a value it just constructed, mock the result it later expects, test the language/framework, or restate the implementation without independent evidence?",
    criteria: {
      true: "The arrange step or duplicated implementation logic effectively guarantees the asserted result without testing meaningful production behavior.",
      false: "The assertion obtains independent evidence by exercising meaningful production behavior.",
    },
  },
  false_confidence: {
    type: "noul",
    instructions: "Could the specific behavior declared in the review context or asserted by this exact test be materially broken while this test still passes because it does not reach the relevant production path or its assertions do not observe the breakage? Ignore unrelated features and behaviors the test does not claim to protect.",
    criteria: {
      true: "A plausible implementation defect that violates the specifically declared or asserted behavior could leave this exact test green.",
      false: "Breaking the specifically declared or asserted behavior would reliably make this exact test fail.",
    },
  },
  implementation_coupling: {
    type: "noul",
    instructions: "Is the test coupled to implementation details strongly enough that harmless refactoring is likely to break it?",
    criteria: {
      true: "The test overspecifies calls, private structure, ordering, or representation not required by the contract.",
      false: "The test is primarily coupled to stable behavior or a deliberate public contract.",
    },
  },
  flakiness_risk: {
    type: "noul",
    instructions: "Does the test have a material risk of nondeterminism from timing, concurrency, randomness, external services, mutable global state, ordering, locale, or environment?",
    criteria: {
      true: "At least one uncontrolled input can plausibly change the result.",
      false: "Inputs and synchronization appear controlled and deterministic.",
    },
  },
  mutation_survival: {
    type: "noul",
    instructions: "Would a small plausible mutation in the production path exercised by this test that violates the specifically declared or asserted behavior plausibly survive? Ignore mutations to unclaimed behavior, unrelated branches, and code this test is not intended to cover.",
    criteria: {
      true: "A branch, boundary, returned value, side effect, or error-path mutation that breaks the specifically protected behavior could leave this exact test green.",
      false: "The assertions are sensitive to plausible mutations that break the specifically protected behavior along the exercised path.",
    },
  },
  test_kind: {
    type: "choice",
    instructions: "Which description best characterizes what the test actually verifies?",
    criteria: {
      behavioral: "Observable behavior or a stable public contract.",
      interaction: "A meaningful collaboration protocol or side-effect boundary.",
      structural: "Implementation shape, wiring, calls, or representation.",
      smoke: "Only that execution completes or returns something minimally plausible.",
      tautological: "Setup or duplicated logic effectively guarantees the assertion.",
      insufficient_context: "The supplied material is insufficient to determine what is really exercised.",
    },
  },
  overall_value: {
    type: "choice",
    instructions: "What is the test's overall value as a regression detector? Judge fault-detection power, oracle quality, relevance, determinism, and maintenance cost together.",
    criteria: {
      high_value: "Strong independent evidence; likely to catch realistic regressions at acceptable maintenance cost.",
      useful: "Protects meaningful behavior but has notable gaps or moderate brittleness.",
      questionable: "Some signal exists, but false confidence or maintenance cost is substantial.",
      low_value: "Tautological, disconnected, very weak, or more harmful than helpful.",
      insufficient_context: "A defensible value judgment requires missing production behavior or requirements.",
    },
  },
} as const;

function clampProbability(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? Math.min(1, Math.max(0, value)) : 0.5;
}

function requireAnswer(answers: Record<string, JevAnswer>, name: string, type: JevAnswer["type"]): JevAnswer {
  const answer = answers[name];
  if (!answer || answer.type !== type) {
    throw new Error(`Jev test value response invalid: missing ${type} answer for ${name}`);
  }
  return answer;
}

function scoreMetric(answers: Record<string, JevAnswer>, name: string): TestValueMetric {
  const answer = requireAnswer(answers, name, "score") as JevScoreAnswer;
  const rawScore = Math.min(4, Math.max(0, answer.score));
  return {
    score: Math.round(rawScore * 25),
    confidence: Math.round(clampProbability(answer.confidence) * 100),
    rationale: answer.legend?.[String(Math.round(rawScore))] ?? "See the Jev score distribution in tool details.",
  };
}

function riskProbability(answers: Record<string, JevAnswer>, name: string): number {
  const answer = requireAnswer(answers, name, "noul") as JevNoulAnswer;
  return Math.round(clampProbability(answer.noul) * 100);
}

function choiceAnswer(answers: Record<string, JevAnswer>, name: string): JevChoiceAnswer {
  return requireAnswer(answers, name, "choice") as JevChoiceAnswer;
}

function modelChoiceToVerdict(choice: string): TestValueVerdict {
  const verdicts: Record<string, TestValueVerdict> = {
    high_value: "high-value",
    useful: "useful",
    questionable: "questionable",
    low_value: "low-value",
    insufficient_context: "questionable",
  };
  const verdict = verdicts[choice];
  if (!verdict) throw new Error(`Jev test value response invalid: unknown overall_value choice ${choice}`);
  return verdict;
}

function isLoopbackSystemOneEndpoint(endpoint: URL): boolean {
  const hostname = endpoint.hostname.replace(/^\[|\]$/g, "").toLowerCase();
  return hostname === "127.0.0.1" || hostname === "localhost" || hostname === "::1";
}

function classifySystemOneProvider(apiUrl: string): TestValueReport["provider"] {
  const endpoint = new URL(apiUrl);
  if (isLoopbackSystemOneEndpoint(endpoint)) return "local-kev";
  if (endpoint.protocol === "https:" && endpoint.hostname.toLowerCase() === "api.typesafe.ai") return "hosted-jev";
  return "custom-system-one";
}

/** Builds a conservative aggregate while preserving independent metric probabilities. */
export function buildTestValueReport(
  response: JevResponse,
  hasProductionCode: boolean,
  apiUrl = TEST_VALUE_API_URL,
): TestValueReport {
  const metrics = {
    faultDetection: scoreMetric(response.answers, "fault_detection"),
    oracleQuality: scoreMetric(response.answers, "oracle_quality"),
    behaviorRelevance: scoreMetric(response.answers, "behavior_relevance"),
    boundaryCoverage: scoreMetric(response.answers, "boundary_coverage"),
    maintainability: scoreMetric(response.answers, "maintainability"),
  };
  const risks = {
    tautology: riskProbability(response.answers, "tautological"),
    falseConfidence: riskProbability(response.answers, "false_confidence"),
    implementationCoupling: riskProbability(response.answers, "implementation_coupling"),
    flakiness: riskProbability(response.answers, "flakiness_risk"),
    mutationSurvival: riskProbability(response.answers, "mutation_survival"),
  };
  const qualityScore =
    metrics.faultDetection.score * 0.3 +
    metrics.oracleQuality.score * 0.2 +
    metrics.behaviorRelevance.score * 0.15 +
    metrics.boundaryCoverage.score * 0.1 +
    metrics.maintainability.score * 0.1;
  const riskPenalty =
    (risks.tautology + risks.falseConfidence + risks.implementationCoupling + risks.flakiness + risks.mutationSurvival) /
    5;
  const overallScore = Math.round(Math.min(100, Math.max(0, qualityScore + (100 - riskPenalty) * 0.15)));
  const confidenceValues = Object.values(metrics).map((metric) => metric.confidence);
  const modelVerdict = choiceAnswer(response.answers, "overall_value");
  const averageConfidence = confidenceValues.reduce((sum, value) => sum + value, 0) / confidenceValues.length;
  const diagnosticVerdict = overallScore >= 80 ? "high-value" : overallScore >= 60 ? "useful" : overallScore >= 40 ? "questionable" : "low-value";
  const diagnosticConfidence = Math.round((averageConfidence + clampProbability(modelVerdict.confidence) * 100) / 2);
  const evidenceConfidenceMultiplier = hasProductionCode ? 1 : 0.75;
  const confidence = Math.round(clampProbability(modelVerdict.confidence) * 100 * evidenceConfidenceMultiplier);
  const limitations: string[] = [];
  if (!hasProductionCode) {
    limitations.push("Production code was not supplied; model confidence was discounted by 25% because fault-detection and mutation-survival judgments have less evidence.");
  }
  if (modelVerdict.choice === "insufficient_context") {
    limitations.push("Jev classified the supplied evidence as insufficient; the primary verdict is reported as questionable.");
  }
  let verdict = modelChoiceToVerdict(modelVerdict.choice);
  if (risks.flakiness >= 70 && (verdict === "high-value" || verdict === "useful")) {
    limitations.push(`Primary verdict was capped at questionable because Jev estimated ${risks.flakiness}% flakiness risk.`);
    verdict = "questionable";
  }

  return {
    verdict,
    modelVerdict: modelVerdict.choice,
    diagnosticVerdict,
    overallScore,
    confidence,
    diagnosticConfidence,
    metrics,
    risks,
    model: response.model,
    provider: classifySystemOneProvider(apiUrl),
    providerUsage: response.usage,
    limitations,
  };
}

async function resolveSystemOneApiKey(apiUrl: string): Promise<string> {
  const endpoint = new URL(apiUrl);
  if (isLoopbackSystemOneEndpoint(endpoint)) return "local";

  if (classifySystemOneProvider(apiUrl) === "custom-system-one") {
    if (endpoint.protocol !== "https:") {
      throw new Error("Custom System One endpoints must use HTTPS so evaluation credentials and source code are not sent in plaintext.");
    }
    const customKey = process.env.JEV_TEST_VALUE_API_KEY?.trim();
    if (customKey) return customKey;
    throw new Error("Custom System One authentication missing: set JEV_TEST_VALUE_API_KEY for the configured endpoint.");
  }

  const environmentKey = process.env.TYPESAFE_API_KEY?.trim();
  if (environmentKey) return environmentKey;

  try {
    const fileKey = (await readFile(DEFAULT_SECRET_PATH, "utf8")).trim();
    if (fileKey) return fileKey;
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code !== "ENOENT") throw error;
  }

  throw new Error(
    `Hosted Jev authentication missing: set TYPESAFE_API_KEY or create ${DEFAULT_SECRET_PATH} with ./scripts/secrets; never place the key in Nix source.`,
  );
}

function retryDelayMilliseconds(response: Response | undefined, attempt: number): number {
  const retryAfter = response?.headers.get("retry-after");
  if (retryAfter) {
    const seconds = Number(retryAfter);
    if (Number.isFinite(seconds)) return Math.min(60_000, Math.max(0, seconds * 1000));
    const dateDelay = Date.parse(retryAfter) - Date.now();
    if (Number.isFinite(dateDelay)) return Math.min(60_000, Math.max(0, dateDelay));
  }
  return 500 * 2 ** attempt + Math.floor(Math.random() * 250);
}

function waitForRetry(delayMilliseconds: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, delayMilliseconds);
    signal?.addEventListener(
      "abort",
      () => {
        clearTimeout(timer);
        reject(signal.reason ?? new Error("Jev test value request cancelled"));
      },
      { once: true },
    );
  });
}

async function evaluateTestWithSystemOne(
  apiUrl: string,
  apiKey: string,
  state: Record<string, string>,
  model: string,
  signal?: AbortSignal,
): Promise<JevResponse> {
  let lastError: unknown;

  for (let attempt = 0; attempt < MAX_REQUEST_ATTEMPTS; attempt += 1) {
    const timeoutSignal = AbortSignal.timeout(REQUEST_TIMEOUT_MS);
    const requestSignal = signal ? AbortSignal.any([signal, timeoutSignal]) : timeoutSignal;
    let response: Response | undefined;
    try {
      response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          authorization: `Bearer ${apiKey}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({ state, model, questions: TEST_VALUE_QUESTIONS }),
        signal: requestSignal,
      });

      if (response.ok) return (await response.json()) as JevResponse;

      const errorBody = (await response.text()).slice(0, 2_000);
      const retryable = response.status === 408 || response.status === 429 || response.status >= 500;
      const errorMessage = `Jev test value request failed (${response.status}): ${errorBody || response.statusText}`;
      if (!retryable) throw new JevNonRetryableRequestError(errorMessage);
      lastError = new Error(errorMessage);
      if (attempt === MAX_REQUEST_ATTEMPTS - 1) throw lastError;
    } catch (error) {
      if (signal?.aborted) throw signal.reason ?? error;
      if (error instanceof JevNonRetryableRequestError) throw error;
      lastError = error;
      if (attempt === MAX_REQUEST_ATTEMPTS - 1) throw error;
    }

    await waitForRetry(retryDelayMilliseconds(response, attempt), signal);
  }

  throw lastError instanceof Error ? lastError : new Error("Jev test value request failed without an error response");
}

function formatTestValueReport(report: TestValueReport, testKind: string): string {
  const metricLines = Object.entries(report.metrics).map(
    ([name, metric]) => `- ${name}: ${metric.score}/100 (${metric.confidence}% confidence)`,
  );
  const riskLines = Object.entries(report.risks).map(([name, probability]) => `- ${name}: ${probability}% risk`);
  const limitations = report.limitations.length > 0 ? `\nLimitations:\n${report.limitations.map((item) => `- ${item}`).join("\n")}` : "";
  return [
    `Test value: ${report.verdict} (${report.confidence}% model confidence)`,
    `Diagnostic aggregate: ${report.overallScore}/100 — ${report.diagnosticVerdict} (${report.diagnosticConfidence}% confidence)`,
    `Model classification: ${report.modelVerdict}; test kind: ${testKind}; provider: ${report.provider}; model: ${report.model}`,
    "",
    "Quality metrics:",
    ...metricLines,
    "",
    "Failure risks:",
    ...riskLines,
    limitations,
    "",
    "Treat these scores as review evidence, not a merge gate. Inspect full probabilities in tool details.",
  ].join("\n");
}

/** Registers the System One test value classifier tool, using local Kev when configured. */
export default function jevTestValueExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "evaluate_test_value",
    label: "Evaluate Test Value",
    description:
      "Use a System One decision model—local Kev when configured—to classify one test and return independent quality scores, defect-detection risks, confidence, and full probability details. Supply relevant production code whenever possible. The output is advisory and must not be used as the sole merge gate.",
    promptSnippet: "Evaluate whether a test provides meaningful regression protection with a System One decision model",
    promptGuidelines: [
      "Use evaluate_test_value when reviewing a newly added or changed test, especially to detect tautological tests, false confidence, weak oracles, implementation coupling, flakiness, and likely mutation survival.",
      "Do not use evaluate_test_value scores as the sole reason to accept or reject a test; combine them with code inspection and test execution.",
    ],
    parameters: TEST_VALUE_PARAMETERS,
    async execute(_toolCallId, params, signal, onUpdate) {
      const state = {
        language_and_framework: params.language ?? "Not supplied",
        review_context: params.context ?? "Not supplied",
        test_code: params.testCode,
        production_code: params.productionCode ?? "Not supplied",
      };
      const stateLength = JSON.stringify(state).length;
      const provider = classifySystemOneProvider(TEST_VALUE_API_URL);
      const maxStateCharacters = provider === "local-kev" ? LOCAL_MAX_STATE_CHARACTERS : HOSTED_MAX_STATE_CHARACTERS;
      if (stateLength > maxStateCharacters) {
        throw new Error(
          `Test value input too large for ${provider}: ${stateLength} characters exceeds the ${maxStateCharacters} character safety limit. Send a focused test and only relevant production code.`,
        );
      }

      onUpdate?.({
        content: [{ type: "text", text: `${provider === "local-kev" ? "Kev" : "Jev"} is evaluating independent test-quality signals…` }],
        details: { status: "evaluating", provider },
      });
      const apiKey = await resolveSystemOneApiKey(TEST_VALUE_API_URL);
      const model = params.model ?? CONFIGURED_TEST_VALUE_MODEL ?? (provider === "local-kev" ? "kev-latest" : "jev-latest");
      const response = await evaluateTestWithSystemOne(TEST_VALUE_API_URL, apiKey, state, model, signal);
      const report = buildTestValueReport(response, Boolean(params.productionCode), TEST_VALUE_API_URL);
      const testKind = choiceAnswer(response.answers, "test_kind").choice;

      return {
        content: [{ type: "text", text: formatTestValueReport(report, testKind) }],
        details: {
          report,
          testKind,
          answers: response.answers,
          methodology: {
            primaryVerdict: "Direct System One overall_value classification; insufficient context and independently estimated flakiness risk of 70% or more cap the verdict at questionable.",
            confidence: "Direct overall_value confidence, discounted by 25% when production code is absent.",
            aggregate: "Secondary diagnostic: weighted quality dimensions (85%) plus inverse average risk (15%).",
            caveat: "System One questions are independent; the diagnostic aggregate is extension-defined and advisory.",
            endpoint: TEST_VALUE_API_URL,
          },
        },
      };
    },
  });
}
