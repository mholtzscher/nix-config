import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { keyHint } from "@earendil-works/pi-coding-agent";
import { Container, Spacer, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

type Frame = Readonly<{ label: string; children?: readonly Frame[] }>;
type Trace = Readonly<{ command?: string; root: Frame }>;

type Details = Readonly<{
  trace: Trace;
}>;

export default function callStackViz(pi: ExtensionAPI) {
  pi.registerTool({
    name: "render_call_stack",
    label: "Render Call Stack",
    description: "Render a nested call stack tree as an ASCII terminal hierarchy.",
    promptSnippet: "Use render_call_stack to visualize call stacks, execution traces, request pipelines, or nested function flows.",
    promptGuidelines: [
      "Input is JSON shaped as { command?: string, root: { label: string, children?: [...] } }.",
      "Prefer concise labels that fit on one line.",
      "The terminal fallback uses pure ASCII for reliable alignment across fonts and terminals."
    ],
    parameters: Type.Object({
      traceJson: Type.String({ description: "JSON string for the call stack trace." }),
      fileName: Type.Optional(Type.String({ description: "Ignored legacy parameter." }))
    }),

    async execute(_toolCallId, params) {
      const trace = parseTrace(params.traceJson);
      const details: Details = { trace };

      return {
        content: [{
          type: "text",
          text: [
            "Rendered call stack hierarchy.",
            "",
            renderTree(trace, (_name, value) => value, true)
          ].join("\n")
        }],
        details
      };
    },

    renderCall(args, theme, _context) {
      const name = typeof args.fileName === "string" ? args.fileName : "call-stack";
      return new Text(
        theme.fg("toolTitle", theme.bold("render_call_stack ")) + theme.fg("dim", `${name} [ascii]`),
        0,
        0
      );
    },

    renderResult(result, options, theme, _context) {
      const details = readDetails(result.details);
      if (details === undefined) return new Text(theme.fg("error", "Failed to render call stack."), 0, 0);

      const container = new Container();
      container.addChild(new Text(theme.fg("success", "✓ Rendered call stack hierarchy"), 0, 0));
      container.addChild(new Spacer(1));
      container.addChild(new Text(renderTree(details.trace, (name, value) => theme.fg(name, value), options.expanded), 0, 0));

      if (!options.expanded) {
        container.addChild(new Spacer(1));
        container.addChild(new Text(theme.fg("dim", `${keyHint("app.tools.expand", "expand")} to show full hierarchy`), 0, 0));
      }

      return container;
    }
  });

  pi.registerCommand("call-stack-demo", {
    description: "Insert a demo render_call_stack payload",
    handler: async (_args, ctx) => {
      const demo: Trace = {
        command: "curl -X POST https://weather.example.com/api/ecowitt",
        root: {
          label: "worker.ts",
          children: [{
            label: "CloudflareWorker.fetch(request, env, ctx)",
            children: [{
              label: "HttpRouter.match(\"POST /api/ecowitt\")",
              children: [
                { label: "RequestBody.json(request)" },
                { label: "EcowittWebhookSchema.decodeUnknown(payload)", children: [
                  { label: "parseStationId" },
                  { label: "parseOutdoorTemperature" },
                  { label: "parseHumidity" },
                  { label: "parseWindAndRain" }
                ] },
                { label: "WeatherIngestService.recordObservation(payload)", children: [
                  { label: "StationRegistry.findByPasskey(payload.PASSKEY)" },
                  { label: "ObservationNormalizer.fromEcowitt(payload)", children: [
                    { label: "normalizeTemperatureUnits" },
                    { label: "normalizePressureUnits" },
                    { label: "calculateDewPoint" }
                  ] },
                  { label: "WeatherStationObject.ingest(observation)", children: [
                    { label: "TimeseriesStore.insertObservation" },
                    { label: "CurrentConditionsCache.update" },
                    { label: "RawPayloadArchive.putJson" }
                  ] }
                ] },
                { label: "HttpResponse.json({ ok: true })" }
              ]
            }]
          }]
        }
      };

      ctx.ui.pasteToEditor(JSON.stringify({
        traceJson: JSON.stringify(demo, null, 2),
        fileName: "ecowitt-call-stack"
      }, null, 2));
    }
  });
}

function parseTrace(value: string): Trace {
  const parsed: unknown = JSON.parse(value);
  if (!isTrace(parsed)) throw new Error("Invalid traceJson shape.");
  return parsed;
}

function isTrace(value: unknown): value is Trace {
  return isRecord(value) && (value.command === undefined || typeof value.command === "string") && isFrame(value.root);
}

function isFrame(value: unknown): value is Frame {
  return isRecord(value) && typeof value.label === "string" &&
    (value.children === undefined || (Array.isArray(value.children) && value.children.every(isFrame)));
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function readDetails(value: unknown): Details | undefined {
  if (!isRecord(value)) return undefined;
  if (!isTrace(value.trace)) return undefined;
  return { trace: value.trace };
}

function renderTree(trace: Trace, color: (name: string, value: string) => string, expanded: boolean | undefined): string {
  const lines: string[] = [];
  if (trace.command !== undefined) lines.push(color("text", `$ ${trace.command}`), "");
  const limit = expanded ? Number.POSITIVE_INFINITY : 18;
  let count = 0;
  let truncated = false;

  const visit = (frame: Frame, depth: number, prefix: string, isLast: boolean): void => {
    if (count >= limit) { truncated = true; return; }
    const connector = depth === 0 ? "" : isLast ? "`-- " : "|-- ";
    lines.push(color(depth === 0 ? "accent" : "text", `${prefix}${connector}${frame.label}`));
    count += 1;

    const children = frame.children ?? [];
    const childPrefix = depth === 0 ? "" : `${prefix}${isLast ? "    " : "|   "}`;
    for (let i = 0; i < children.length; i += 1) {
      visit(children[i], depth + 1, childPrefix, i === children.length - 1);
    }
  };

  visit(trace.root, 0, "", true);
  if (truncated) lines.push(color("dim", "..."));
  return lines.join("\n");
}
