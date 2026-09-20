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

/** Version tag for the extension-defined secondary diagnostic score formula. */
const DIAGNOSTIC_FORMULA_VERSION = "jev-test-value-diagnostic-v2";
/** Missing production code discounts model-derived fault-detection confidence to this fraction. */
const MISSING_PRODUCTION_CONFIDENCE_MULTIPLIER = 0.75;
/** Flakiness risk at or above this percentage caps a useful/high-value verdict at questionable. */
const FLAKINESS_VERDICT_CAP_PERCENT = 70;
/** Tautology risk at or above this percentage caps a useful/high-value verdict at questionable. */
const TAUTOLOGY_VERDICT_CAP_PERCENT = 70;

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
    protectedBehavior: Type.Optional(
      Type.String({
        minLength: 1,
        description: "The exact behavior this test claims to protect, stated observably. Improves behavior-relevance and false-confidence assessment.",
      }),
    ),
    regressionBeingPrevented: Type.Optional(
      Type.String({
        minLength: 1,
        description: "The concrete regression this test is meant to prevent. Improves false-confidence assessment.",
      }),
    ),
    outOfScope: Type.Optional(
      Type.Array(Type.String({ minLength: 1 }), {
        description: "Behaviors, branches, or defects this test is explicitly not expected to cover, to avoid over-penalizing it.",
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
  /** Details-only model uncertainty metadata; not rendered and not calibrated correctness. */
  confidence: number;
  rationale: string;
};

type TestValueVerdict = "high-value" | "useful" | "questionable" | "low-value";

/** Observable properties the model estimates, replacing the earlier abstract risk questions. */
type TestValueObservationName =
  | "oracleIndependent"
  | "claimedPathExercised"
  | "claimedBreakageObserved"
  | "claimedBoundariesExercised"
  | "implementationDetailsRequired"
  | "uncontrolledNondeterminism"
  | "plausibleMutationDetected";

type TestValueObservations = Record<TestValueObservationName, number>;

type TestValueAssessabilityStatus = "assessable" | "partially-assessable" | "not-assessable";

type TestValueRecommendation = {
  id: string;
  priority: "high" | "medium" | "low";
  category: string;
  message: string;
  evidence: Record<string, string | number>;
};

type TestValueAssessability = {
  overall: TestValueAssessabilityStatus;
  byDimension: Record<string, TestValueAssessabilityStatus>;
  missingEvidence: string[];
  note: string;
};

type TestValueConfidenceProvenance = {
  modelConfidence: number;
  evidenceMultiplier: number;
  /** @deprecated Read `capRisk` for the reason and probability of any deterministic verdict cap. */
  flakinessProbability?: number;
  capRisk?: { name: "flakiness" | "tautology"; probability: number; threshold: number };
  formula: string;
};

type TestValueDiagnosticScore = {
  score: number;
  band: TestValueVerdict;
  formulaVersion: string;
  status: "diagnostic-only";
};

type TestValueIntentEvidence = {
  protectedBehavior?: string;
  regressionBeingPrevented?: string;
  outOfScope?: string[];
};

type TestValueEvidence = {
  hasIntent?: boolean;
  intent?: TestValueIntentEvidence;
};

type TestValueFinalVerdictReason = "model-classification" | "insufficient-context" | "flakiness-cap" | "tautology-cap";

type TestValueReport = {
  /** Primary final verdict after deterministic high-flakiness or high-tautology caps. */
  verdict: TestValueVerdict;
  /** Explicit alias of `verdict`. */
  finalVerdict: TestValueVerdict;
  finalVerdictReason: TestValueFinalVerdictReason;
  modelVerdict: string;
  /**
   * @deprecated Use `finalVerdict`. The diagnostic band is structured-details-only and is not
   * rendered; read `observations`, `risks`, and `recommendations` for the user-facing summary.
   */
  diagnosticVerdict: TestValueVerdict;
  /** Compatibility alias of `finalVerdictConfidence`. */
  confidence: number;
  finalVerdictConfidence: number;
  modelVerdictConfidence: number;
  /**
   * @deprecated Use `finalVerdictConfidence`. Diagnostic confidence is structured-details-only and
   * is not rendered; read `observations`, `risks`, and `recommendations` for the user-facing summary.
   */
  diagnosticConfidence: number;
  /**
   * @deprecated Read `observations`, `risks`, and `finalVerdict`. The numeric compatibility aggregate
   * is structured-details-only and is not rendered.
   */
  overallScore: number;
  metrics: Record<string, TestValueMetric>;
  risks: Record<string, number>;
  observations: TestValueObservations;
  assessability: TestValueAssessability;
  recommendations: TestValueRecommendation[];
  confidenceProvenance: TestValueConfidenceProvenance;
  /**
   * @deprecated Read `observations`, `risks`, and `recommendations`. The secondary diagnostic score
   * is structured-details-only and is not rendered.
   */
  diagnosticScore: TestValueDiagnosticScore;
  intentEvidence?: TestValueIntentEvidence;
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
    instructions: "How directly does this test protect user-visible, contract-level, or otherwise meaningful behavior rather than incidental implementation details? Judge against review_context and regression_being_prevented as well as protected_behavior. Do not reward a narrowly declared behavior that excludes the stated regression.",
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
  oracleIndependent: {
    type: "noul",
    instructions: "Does the test obtain independent evidence for the asserted result? Estimate the probability that the assertion is supported by exercising meaningful production behavior rather than by re-asserting a value, stub, or duplicated implementation logic it just constructed. Higher means a more independent oracle.",
    criteria: {
      true: "The assertion is grounded in independently produced production behavior.",
      false: "The assertion mostly restates constructed setup, a stub, or duplicated implementation logic.",
    },
  },
  claimedPathExercised: {
    type: "noul",
    instructions: "Does the test execute the specific production path the claimed behavior depends on? Estimate the probability that control actually reaches that path rather than adjacent, stubbed, or unreachable code.",
    criteria: {
      true: "The claimed behavior's production path is actually executed.",
      false: "The relevant path is bypassed through stubs, short-circuits, or unreachable branches.",
    },
  },
  claimedBreakageObserved: {
    type: "noul",
    instructions: "Would breaking the protected behavior or regression_being_prevented make this exact test fail? Use the broader obligation when structured intent conflicts with review_context, and do not let out_of_scope exclude the stated regression. Estimate the probability that the assertions directly observe that outcome.",
    criteria: {
      true: "A defect in the claimed behavior would change an asserted observable outcome.",
      false: "The claimed behavior could break while the assertions still pass.",
    },
  },
  claimedBoundariesExercised: {
    type: "noul",
    instructions: "Does the test exercise the boundaries, failure modes, or state transitions belonging to the protected behavior and regression_being_prevented? Use review_context to resolve conflicting or artificially narrow scope. Estimate the probability those relevant boundaries are covered rather than only a happy path.",
    criteria: {
      true: "Claimed boundaries and failure modes are exercised.",
      false: "Only a narrow happy path is exercised.",
    },
  },
  implementationDetailsRequired: {
    type: "noul",
    instructions: "Does passing this test require matching incidental implementation details such as private structure, call order, exact call counts, or representation that the contract does not require? Estimate the probability. Higher means more refactoring brittleness.",
    criteria: {
      true: "The test pins incidental implementation detail.",
      false: "The test depends only on stable behavior or a deliberate public contract.",
    },
  },
  uncontrolledNondeterminism: {
    type: "noul",
    instructions: "Does the test depend on uncontrolled nondeterminism such as timing, concurrency, randomness, real clocks, external services, shared mutable state, ordering, locale, or environment? Estimate the probability. Higher means more flakiness.",
    criteria: {
      true: "At least one uncontrolled input can change the result.",
      false: "Inputs and synchronization are controlled and deterministic.",
    },
  },
  plausibleMutationDetected: {
    type: "noul",
    instructions: "Would the assertions detect a small plausible mutation along the exercised path that violates the specifically claimed behavior? Estimate the probability the test is sensitive to such a mutation.",
    criteria: {
      true: "A plausible mutation of the exercised path would fail the test.",
      false: "A plausible mutation could survive while the test stays green.",
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
    instructions: "What is the test's overall value as a regression detector? Judge fault-detection power, oracle quality, relevance, determinism, and maintenance cost together. Evaluate the review_context and regression_being_prevented, not merely a narrow protected_behavior. A test can correctly verify trivial behavior and still be questionable; out_of_scope cannot erase the stated regression.",
    criteria: {
      high_value: "Strong independent evidence; likely to catch realistic regressions at acceptable maintenance cost.",
      useful: "Protects meaningful behavior but has notable gaps or moderate brittleness.",
      questionable: "Some signal exists, but false confidence or maintenance cost is substantial.",
      low_value: "Tautological, disconnected, very weak, or more harmful than helpful.",
      insufficient_context: "A defensible value judgment requires missing production behavior or requirements.",
    },
  },
} as const;

const OBSERVATION_ASSESSABILITY_DIMENSIONS: Partial<Record<TestValueObservationName, string>> = {
  claimedPathExercised: "faultDetection",
  claimedBreakageObserved: "falseConfidence",
  plausibleMutationDetected: "mutationSurvival",
};

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

/** Reads a noul answer as a rounded percentage, or undefined when the answer is absent. */
function optionalNoulPercent(answers: Record<string, JevAnswer>, name: string): number | undefined {
  const answer = answers[name];
  if (!answer || answer.type !== "noul" || !Number.isFinite(answer.noul) || answer.noul < 0 || answer.noul > 1) return undefined;
  return Math.round(answer.noul * 100);
}

/**
 * Resolves all seven current observations, or all five legacy risks for compatibility. Mixed or
 * incomplete response shapes fail closed instead of turning missing provider answers into 50%.
 */
function deriveTestValueObservations(answers: Record<string, JevAnswer>): TestValueObservations {
  const currentAnswerNames: TestValueObservationName[] = [
    "oracleIndependent",
    "claimedPathExercised",
    "claimedBreakageObserved",
    "claimedBoundariesExercised",
    "implementationDetailsRequired",
    "uncontrolledNondeterminism",
    "plausibleMutationDetected",
  ];
  const currentValues = Object.fromEntries(
    currentAnswerNames.map((name) => [name, optionalNoulPercent(answers, name)]),
  ) as Record<TestValueObservationName, number | undefined>;
  if (Object.values(currentValues).some((value) => value !== undefined)) {
    const missing = currentAnswerNames.filter((name) => currentValues[name] === undefined);
    if (missing.length > 0) {
      throw new Error(`Jev test value response invalid: incomplete observable answers (${missing.join(", ")})`);
    }
    return currentValues as TestValueObservations;
  }

  const legacyTautology = optionalNoulPercent(answers, "tautological");
  const legacyFalseConfidence = optionalNoulPercent(answers, "false_confidence");
  const legacyImplementationCoupling = optionalNoulPercent(answers, "implementation_coupling");
  const legacyFlakiness = optionalNoulPercent(answers, "flakiness_risk");
  const legacyMutationSurvival = optionalNoulPercent(answers, "mutation_survival");
  const legacyValues = [legacyTautology, legacyFalseConfidence, legacyImplementationCoupling, legacyFlakiness, legacyMutationSurvival];
  if (legacyValues.some((value) => value === undefined)) {
    throw new Error("Jev test value response invalid: missing complete observable or legacy risk answer set");
  }
  return {
    oracleIndependent: 100 - legacyTautology!,
    claimedPathExercised: 100 - legacyFalseConfidence!,
    claimedBreakageObserved: 100 - legacyFalseConfidence!,
    claimedBoundariesExercised: 100 - legacyMutationSurvival!,
    implementationDetailsRequired: legacyImplementationCoupling!,
    uncontrolledNondeterminism: legacyFlakiness!,
    plausibleMutationDetected: 100 - legacyMutationSurvival!,
  };
}

/** Derives five compatibility risks from the seven independently estimated observable properties. */
export function deriveTestValueRisks(observations: TestValueObservations): Record<string, number> {
  const geometricMeanPercent = (values: number[]): number =>
    Math.round(100 * values.reduce((product, value) => product * (value / 100), 1) ** (1 / values.length));
  return {
    tautology: 100 - observations.oracleIndependent,
    falseConfidence:
      100 - geometricMeanPercent([observations.claimedPathExercised, observations.claimedBreakageObserved]),
    implementationCoupling: observations.implementationDetailsRequired,
    flakiness: observations.uncontrolledNondeterminism,
    mutationSurvival:
      100 -
      geometricMeanPercent([
        observations.claimedPathExercised,
        observations.claimedBoundariesExercised,
        observations.plausibleMutationDetected,
      ]),
  };
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

/** Builds the per-dimension and overall assessability verdict from the available evidence. */
function deriveTestValueAssessability(hasProductionCode: boolean, hasIntent: boolean): TestValueAssessability {
  const production: TestValueAssessabilityStatus = hasProductionCode ? "assessable" : "not-assessable";
  const intent: TestValueAssessabilityStatus = hasIntent ? "assessable" : "not-assessable";
  const byDimension: Record<string, TestValueAssessabilityStatus> = {
    faultDetection: production,
    mutationSurvival: production,
    behaviorRelevance: intent,
    falseConfidence: intent,
    oracleQuality: "assessable",
    boundaryCoverage: "assessable",
    maintainability: "assessable",
    tautology: "assessable",
    implementationCoupling: "assessable",
    flakiness: "assessable",
  };
  const missingEvidence: string[] = [];
  if (!hasProductionCode) missingEvidence.push("production-code");
  if (!hasIntent) missingEvidence.push("intent");
  const overall: TestValueAssessabilityStatus =
    !hasProductionCode && !hasIntent ? "not-assessable" : !hasProductionCode || !hasIntent ? "partially-assessable" : "assessable";
  return {
    overall,
    byDimension,
    missingEvidence,
    note: "Dimensions marked not-assessable still carry compatibility estimate numbers; treat those numbers as unvalidated estimates, not calibrated measurements.",
  };
}

/**
 * Derives deterministic, typed review recommendations from risks, metrics, and evidence flags.
 */
export function deriveTestValueRecommendations(input: {
  risks: Record<string, number>;
  metrics: Record<string, TestValueMetric>;
  hasProductionCode: boolean;
  hasIntent: boolean;
}): TestValueRecommendation[] {
  const recommendations: TestValueRecommendation[] = [];
  const risk = (name: string): number => input.risks[name] ?? 0;
  const boundaryCoverage = input.metrics.boundaryCoverage?.score ?? 0;

  if (!input.hasProductionCode) {
    recommendations.push({
      id: "supply-production-code",
      priority: "high",
      category: "evidence",
      message:
        "Supply the relevant production code or diff so fault-detection and mutation-survival judgments rest on observable behavior rather than inference.",
      evidence: { hasProductionCode: 0 },
    });
  }
  if (!input.hasIntent) {
    recommendations.push({
      id: "describe-protected-behavior",
      priority: "high",
      category: "intent",
      message:
        "Describe the protected behavior, the regression being prevented, and what is out of scope so relevance and false-confidence can be assessed.",
      evidence: { hasIntent: 0 },
    });
  }
  if (risk("tautology") >= 65) {
    recommendations.push({
      id: "use-independent-oracle",
      priority: "high",
      category: "oracle",
      message: "Replace setup-echoing or duplicated-logic assertions with an oracle that observes independently produced production behavior.",
      evidence: { tautology: risk("tautology"), oracleIndependent: 100 - risk("tautology") },
    });
  }
  if (risk("falseConfidence") >= 65) {
    recommendations.push({
      id: "strengthen-observable-assertions",
      priority: "high",
      category: "oracle",
      message: "Assert the claimed behavior's observable outcome directly so that breaking it fails this exact test.",
      evidence: { falseConfidence: risk("falseConfidence") },
    });
  }
  if (risk("mutationSurvival") >= 65 || boundaryCoverage < 50) {
    recommendations.push({
      id: "test-claimed-boundaries",
      priority: "high",
      category: "coverage",
      message: "Exercise the boundaries, failure modes, and state transitions of the claimed behavior, and add assertions sensitive to small mutations along the exercised path.",
      evidence: { mutationSurvival: risk("mutationSurvival"), boundaryCoverage },
    });
  }
  if (risk("implementationCoupling") >= 65) {
    recommendations.push({
      id: "avoid-implementation-detail-assertions",
      priority: "medium",
      category: "coupling",
      message: "Stop asserting private structure, call order, or representation that the public contract does not require.",
      evidence: { implementationCoupling: risk("implementationCoupling") },
    });
  }
  if (risk("flakiness") >= 50) {
    recommendations.push({
      id: "control-nondeterminism",
      priority: "high",
      category: "determinism",
      message: "Control timing, concurrency, randomness, clocks, external services, ordering, locale, and shared mutable state so the result is deterministic.",
      evidence: { flakiness: risk("flakiness") },
    });
  }
  return recommendations;
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

/**
 * Builds a conservative report from a System One response. Legacy callers may omit the optional
 * fourth evidence argument and may supply the older risk answer keys instead of observations.
 */
export function buildTestValueReport(
  response: JevResponse,
  hasProductionCode: boolean,
  apiUrl = TEST_VALUE_API_URL,
  evidence: TestValueEvidence = {},
): TestValueReport {
  const metrics = {
    faultDetection: scoreMetric(response.answers, "fault_detection"),
    oracleQuality: scoreMetric(response.answers, "oracle_quality"),
    behaviorRelevance: scoreMetric(response.answers, "behavior_relevance"),
    boundaryCoverage: scoreMetric(response.answers, "boundary_coverage"),
    maintainability: scoreMetric(response.answers, "maintainability"),
  };
  const observations = deriveTestValueObservations(response.answers);
  const risks = deriveTestValueRisks(observations);
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
  const modelVerdictConfidence = Math.round(clampProbability(modelVerdict.confidence) * 100);
  const diagnosticConfidence = Math.round((averageConfidence + modelVerdictConfidence) / 2);
  const evidenceConfidenceMultiplier = hasProductionCode ? 1 : MISSING_PRODUCTION_CONFIDENCE_MULTIPLIER;
  const modelChoiceVerdict = modelChoiceToVerdict(modelVerdict.choice);
  const modelVerdictCanBeCapped = modelChoiceVerdict === "high-value" || modelChoiceVerdict === "useful";
  const capRisk =
    modelVerdictCanBeCapped && risks.flakiness >= FLAKINESS_VERDICT_CAP_PERCENT
      ? { name: "flakiness" as const, probability: risks.flakiness, threshold: FLAKINESS_VERDICT_CAP_PERCENT }
      : modelVerdictCanBeCapped && risks.tautology >= TAUTOLOGY_VERDICT_CAP_PERCENT
        ? { name: "tautology" as const, probability: risks.tautology, threshold: TAUTOLOGY_VERDICT_CAP_PERCENT }
        : undefined;
  const confidenceBase = capRisk ? Math.min(modelVerdictConfidence, capRisk.probability) : modelVerdictConfidence;
  const finalVerdictConfidence = Math.round(confidenceBase * evidenceConfidenceMultiplier);
  const confidenceProvenance: TestValueConfidenceProvenance = {
    modelConfidence: modelVerdictConfidence,
    evidenceMultiplier: evidenceConfidenceMultiplier,
    ...(capRisk?.name === "flakiness" ? { flakinessProbability: capRisk.probability } : {}),
    ...(capRisk ? { capRisk } : {}),
    formula: capRisk
      ? "round(min(modelConfidence, capRiskProbability) * evidenceMultiplier)"
      : "round(modelConfidence * evidenceMultiplier)",
  };
  const hasIntent =
    evidence.hasIntent ??
    Boolean(
      evidence.intent &&
        (evidence.intent.protectedBehavior?.trim() || evidence.intent.regressionBeingPrevented?.trim()),
    );
  const assessability = deriveTestValueAssessability(hasProductionCode, hasIntent);
  const recommendations = deriveTestValueRecommendations({ risks, metrics, hasProductionCode, hasIntent });

  const limitations: string[] = [];
  if (!hasProductionCode) {
    limitations.push("Production code was not supplied; model confidence was discounted by 25% because fault-detection and mutation-survival judgments have less evidence.");
  }
  if (modelVerdict.choice === "insufficient_context") {
    limitations.push("Jev classified the supplied evidence as insufficient; the primary verdict is reported as questionable.");
  }
  if (capRisk) {
    limitations.push(
      `Primary verdict was capped at questionable because the derived ${capRisk.name} risk reached ${capRisk.probability}% (threshold ${capRisk.threshold}%).`,
    );
  }
  if (assessability.overall !== "assessable") {
    limitations.push(
      `Assessability is ${assessability.overall} because missing evidence (${assessability.missingEvidence.join(", ")}) leaves some dimensions unvalidated; their numbers are compatibility estimates, not measurements.`,
    );
  }

  let verdict = modelChoiceVerdict;
  if (capRisk) verdict = "questionable";
  const finalVerdictReason: TestValueFinalVerdictReason = capRisk
    ? `${capRisk.name}-cap`
    : modelVerdict.choice === "insufficient_context"
      ? "insufficient-context"
      : "model-classification";

  const intentEvidence =
    evidence.intent && (evidence.intent.protectedBehavior?.trim() || evidence.intent.regressionBeingPrevented?.trim())
      ? evidence.intent
      : undefined;

  return {
    verdict,
    finalVerdict: verdict,
    finalVerdictReason,
    modelVerdict: modelVerdict.choice,
    diagnosticVerdict,
    confidence: finalVerdictConfidence,
    finalVerdictConfidence,
    modelVerdictConfidence,
    diagnosticConfidence,
    overallScore,
    metrics,
    risks,
    observations,
    assessability,
    recommendations,
    confidenceProvenance,
    diagnosticScore: {
      score: overallScore,
      band: diagnosticVerdict,
      formulaVersion: DIAGNOSTIC_FORMULA_VERSION,
      status: "diagnostic-only",
    },
    ...(intentEvidence ? { intentEvidence } : {}),
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
  state: Record<string, unknown>,
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

/** Synthesizes the legacy noul risk answers so older benchmark consumers keep reading them. */
function synthesizeLegacyRiskAnswers(risks: Record<string, number>): Record<string, JevAnswer> {
  return {
    tautological: { type: "noul", noul: risks.tautology / 100 },
    false_confidence: { type: "noul", noul: risks.falseConfidence / 100 },
    implementation_coupling: { type: "noul", noul: risks.implementationCoupling / 100 },
    flakiness_risk: { type: "noul", noul: risks.flakiness / 100 },
    mutation_survival: { type: "noul", noul: risks.mutationSurvival / 100 },
  };
}

const TEST_VALUE_DISPLAY_LABELS: Record<string, string> = {
  tautology: "Tautology",
  falseConfidence: "False confidence",
  implementationCoupling: "Implementation coupling",
  flakiness: "Flakiness",
  mutationSurvival: "Mutation survival",
  faultDetection: "Fault detection",
  oracleQuality: "Oracle quality",
  behaviorRelevance: "Behavior relevance",
  boundaryCoverage: "Boundary coverage",
  maintainability: "Maintainability",
  oracleIndependent: "Independent oracle",
  claimedPathExercised: "Claimed path exercised",
  claimedBreakageObserved: "Claimed breakage observed",
  claimedBoundariesExercised: "Claimed boundaries exercised",
  plausibleMutationDetected: "Plausible mutation detected",
};

const TEST_VALUE_REASON_LABELS: Record<TestValueFinalVerdictReason, string> = {
  "model-classification": "model classification",
  "insufficient-context": "insufficient context",
  "flakiness-cap": "high flakiness",
  "tautology-cap": "high tautology",
};

const TEST_VALUE_MISSING_EVIDENCE_LABELS: Record<string, string> = {
  "production-code": "production code",
  intent: "protected behavior or regression",
};

const TEST_VALUE_SHORT_RECOMMENDATIONS: Record<string, string> = {
  "supply-production-code": "Supply the relevant production code or diff.",
  "describe-protected-behavior": "State the protected behavior and regression being prevented.",
  "use-independent-oracle": "Use an independent oracle instead of setup-derived expectations.",
  "strengthen-observable-assertions": "Assert the claimed observable outcome directly.",
  "test-claimed-boundaries": "Add relevant boundary and failure-path cases.",
  "avoid-implementation-detail-assertions": "Assert stable behavior rather than implementation details.",
  "control-nondeterminism": "Replace uncontrolled timing or external state with deterministic controls.",
};

const RISK_TO_OVERLAPPING_METRICS: Record<string, string[]> = {
  tautology: ["oracleQuality"],
  falseConfidence: ["faultDetection", "behaviorRelevance"],
  implementationCoupling: ["maintainability"],
  flakiness: ["maintainability"],
  mutationSurvival: ["faultDetection", "boundaryCoverage"],
};

/** Renders a compact advisory summary; full signals and provenance remain in structured tool details. */
export function formatTestValueReport(report: TestValueReport, testKind: string): string {
  const dimensionStatus = (name: string): TestValueAssessabilityStatus => report.assessability.byDimension[name] ?? "assessable";
  const findings: Array<{ name: string; value: number; text: string }> = Object.entries(report.risks)
    .filter(([name, probability]) => dimensionStatus(name) !== "not-assessable" && probability >= 40)
    .map(([name, probability]) => ({
      name,
      value: probability,
      text: `- ${TEST_VALUE_DISPLAY_LABELS[name] ?? name} risk: ${probability}%`,
    }))
    .sort((left, right) => right.value - left.value);

  const overlappingMetrics = new Set(findings.flatMap((finding) => RISK_TO_OVERLAPPING_METRICS[finding.name] ?? []));
  const weakMetrics = Object.entries(report.metrics)
    .filter(
      ([name, metric]) =>
        dimensionStatus(name) !== "not-assessable" && metric.score < 50 && !overlappingMetrics.has(name),
    )
    .map(([name, metric]) => ({
      name,
      value: metric.score,
      text: `- ${TEST_VALUE_DISPLAY_LABELS[name] ?? name}: ${metric.score}/100`,
    }))
    .sort((left, right) => left.value - right.value);
  findings.push(...weakMetrics);

  const findingLines = findings.slice(0, 4).map((finding) => finding.text);
  if (findingLines.length === 0) {
    const strengthNames: TestValueObservationName[] = [
      "oracleIndependent",
      "claimedPathExercised",
      "claimedBreakageObserved",
      "claimedBoundariesExercised",
      "plausibleMutationDetected",
    ];
    findingLines.push(
      ...strengthNames
        .filter((name) => {
          const assessabilityDimension = OBSERVATION_ASSESSABILITY_DIMENSIONS[name];
          return (
            (!assessabilityDimension || dimensionStatus(assessabilityDimension) !== "not-assessable") &&
            report.observations[name] >= 70
          );
        })
        .sort((left, right) => report.observations[right] - report.observations[left])
        .slice(0, 3)
        .map((name) => `- ${TEST_VALUE_DISPLAY_LABELS[name]}: ${report.observations[name]}%`),
    );
  }
  if (findingLines.length === 0) findingLines.push("- No dominant signal; inspect structured details if needed.");

  const evidenceGapLine =
    report.assessability.missingEvidence.length > 0
      ? `Evidence gaps: ${report.assessability.missingEvidence
          .map((name) => TEST_VALUE_MISSING_EVIDENCE_LABELS[name] ?? name)
          .join(", ")}`
      : undefined;
  const shownRecommendations = report.recommendations.slice(0, 3);
  const recommendationLines = shownRecommendations.map(
    (recommendation) =>
      `- ${TEST_VALUE_SHORT_RECOMMENDATIONS[recommendation.id] ?? recommendation.message}`,
  );
  if (report.recommendations.length > shownRecommendations.length) {
    recommendationLines.push(`- +${report.recommendations.length - shownRecommendations.length} more in tool details.`);
  }

  return [
    `Test value: ${report.finalVerdict} · ${report.finalVerdictConfidence}% model-derived confidence`,
    `Reason: ${TEST_VALUE_REASON_LABELS[report.finalVerdictReason]} · Kind: ${testKind}`,
    evidenceGapLine,
    "",
    "Key findings:",
    ...findingLines,
    ...(recommendationLines.length > 0 ? ["", "Recommendations:", ...recommendationLines] : []),
    "",
    "Advisory only. Full analysis and probabilities are in tool details.",
  ]
    .filter((line): line is string => line !== undefined)
    .join("\n");
}

/** Registers the System One test value classifier tool, using local Kev when configured. */
export default function jevTestValueExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "evaluate_test_value",
    label: "Evaluate Test Value",
    description:
      "Use a System One decision model—local Kev when configured—to classify one test and return observable test-quality properties, derived legacy-like risks, assessability, deterministic recommendations, and full probability details. Supply production code, the protected behavior, and the regression being prevented whenever possible. The output is advisory and must not be used as the sole merge gate.",
    promptSnippet: "Evaluate whether a test provides meaningful regression protection with a System One decision model",
    promptGuidelines: [
      "Use evaluate_test_value when reviewing a newly added or changed test, especially to detect tautological tests, false confidence, weak oracles, implementation coupling, flakiness, and likely mutation survival.",
      "Provide protectedBehavior and regressionBeingPrevented (and outOfScope where useful) so behavior relevance and false confidence can be assessed; provide productionCode so fault detection and mutation survival can be assessed.",
      "Do not use evaluate_test_value scores or confidence as calibrated measurements or as the sole reason to accept or reject a test; combine them with code inspection and test execution.",
    ],
    parameters: TEST_VALUE_PARAMETERS,
    async execute(_toolCallId, params, signal, onUpdate) {
      const state: Record<string, unknown> = {
        language_and_framework: params.language ?? "Not supplied",
        review_context: params.context ?? "Not supplied",
        protected_behavior: params.protectedBehavior ?? "Not supplied",
        regression_being_prevented: params.regressionBeingPrevented ?? "Not supplied",
        out_of_scope: params.outOfScope && params.outOfScope.length > 0 ? params.outOfScope : ["Not supplied"],
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
      const report = buildTestValueReport(response, Boolean(params.productionCode), TEST_VALUE_API_URL, {
        hasIntent: Boolean(params.context?.trim() || params.protectedBehavior?.trim() || params.regressionBeingPrevented?.trim()),
        intent: {
          protectedBehavior: params.protectedBehavior,
          regressionBeingPrevented: params.regressionBeingPrevented,
          outOfScope: params.outOfScope,
        },
      });
      const testKind = choiceAnswer(response.answers, "test_kind").choice;

      return {
        content: [{ type: "text", text: formatTestValueReport(report, testKind) }],
        details: {
          report,
          testKind,
          answers: response.answers,
          derivedRiskAnswers: synthesizeLegacyRiskAnswers(report.risks),
          methodology: {
            primaryVerdict:
              "Direct System One overall_value classification; insufficient context plus derived flakiness or tautology risk of 70% or more can cap a useful/high-value verdict at questionable.",
            confidence:
              "Final confidence derives from the model's overall_value confidence, discounted to 75% when production code is absent, and bounded by the derived cap-risk probability when a deterministic cap changes the verdict.",
            observations:
              "Seven observable noul properties (oracleIndependent, claimedPathExercised, claimedBreakageObserved, claimedBoundariesExercised, implementationDetailsRequired, uncontrolledNondeterminism, plausibleMutationDetected) replace the earlier abstract risk questions.",
            legacyRisks:
              "Legacy risks are derived deterministically: tautology=100-oracleIndependent; falseConfidence=100-geometricMean(claimedPathExercised, claimedBreakageObserved); implementationCoupling=implementationDetailsRequired; flakiness=uncontrolledNondeterminism; mutationSurvival=100-geometricMean(claimedPathExercised, claimedBoundariesExercised, plausibleMutationDetected). Geometric means reflect that every positive observation is necessary for confidence.",
            assessability:
              "Missing production code marks fault detection and mutation survival not-assessable; missing intent marks behavior relevance and false confidence not-assessable; both missing makes the overall report not-assessable.",
            recommendations: "Deterministic rule-based; see report.recommendations. Not model-generated.",
            aggregate:
              "Structured-details-only compatibility aggregate: weighted quality dimensions (85%) plus inverse average risk (15%). It is not rendered in the tool text; read finalVerdict, observations, risks, and recommendations instead.",
            caveat: "System One questions are independent; the diagnostic aggregate is extension-defined and advisory.",
            endpoint: TEST_VALUE_API_URL,
          },
        },
      };
    },
  });
}
