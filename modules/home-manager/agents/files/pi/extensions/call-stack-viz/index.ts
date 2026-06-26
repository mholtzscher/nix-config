import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import { existsSync, readFileSync } from "node:fs";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";
import { tmpdir } from "node:os";
import { join } from "node:path";

type Frame = Readonly<{ label: string; children?: readonly Frame[] }>;
type Trace = Readonly<{ command?: string; root: Frame }>;
type PngMode = "never" | "if-available" | "always";
type InlineMode = "never" | "when-expanded" | "always";

type Details = Readonly<{
  trace: Trace;
  svgPath: string;
  htmlPath: string;
  pngPath?: string;
  pngMode: PngMode;
  pngStatus: "skipped" | "rendered" | "unavailable";
  pngMessage?: string;
  inlinePngPreview: InlineMode;
  imageMaxWidthCells: number;
  imageMaxHeightCells: number;
}>;

export default function callStackViz(pi: ExtensionAPI) {
  pi.registerTool({
    name: "render_call_stack",
    label: "Render Call Stack",
    description: "Render a nested call stack tree as a temporary Catppuccin SVG/HTML preview with GlimpseUI.",
    promptSnippet: "Use render_call_stack to visualize call stacks, execution traces, request pipelines, or nested function flows.",
    promptGuidelines: [
      "Input is JSON shaped as { command?: string, root: { label: string, children?: [...] } }.",
      "Prefer concise labels that fit on one line.",
      "The visualization opens outside Pi in a GlimpseUI window; Pi output stays hidden."
    ],
    parameters: Type.Object({
      traceJson: Type.String({ description: "JSON string for the call stack trace." }),
      fileName: Type.Optional(Type.String({ description: "Artifact base name without extension." })),
      pngOutputMode: Type.Optional(Type.Union([Type.Literal("never"), Type.Literal("if-available"), Type.Literal("always")])),
      pngWidth: Type.Optional(Type.Number({ minimum: 320, maximum: 4096 })),
      inlinePngPreview: Type.Optional(Type.Union([Type.Literal("never"), Type.Literal("when-expanded"), Type.Literal("always")])),
      imageMaxWidthCells: Type.Optional(Type.Number({ minimum: 20, maximum: 240 })),
      imageMaxHeightCells: Type.Optional(Type.Number({ minimum: 4, maximum: 80 }))
    }),

    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      const trace = parseTrace(params.traceJson);
      const inlineMode = normalizeInline(params.inlinePngPreview);
      const pngMode = normalizePngMode(params.pngOutputMode, inlineMode);
      const imageMaxWidthCells = normalizeNumber(params.imageMaxWidthCells, 80);
      const imageMaxHeightCells = normalizeNumber(params.imageMaxHeightCells, 24);
      const fileName = safeFileName(params.fileName ?? "call-stack");
      const tempDir = await mkdtemp(join(tmpdir(), "pi-call-stack-viz-"));

      try {
        const animatedSvg = renderSvg(trace, { animated: true });
        const staticSvg = renderSvg(trace, { animated: false });
        const svgPath = join(tempDir, `${fileName}.svg`);
        const htmlPath = join(tempDir, `${fileName}.html`);
        const pngPath = join(tempDir, `${fileName}.png`);

        await writeFile(svgPath, animatedSvg, "utf8");
        await writeFile(htmlPath, renderHtml(animatedSvg), "utf8");
        const glimpseResult = await openGlimpseui(htmlPath);

        const pngResult = await maybeRenderPng({
          svg: staticSvg,
          pngPath,
          pngMode,
          pngWidth: typeof params.pngWidth === "number" ? params.pngWidth : undefined
        });

        if (pngMode === "always" && pngResult.status !== "rendered") {
          throw new Error(pngResult.message ?? "PNG output was required but no renderer was available.");
        }

        const details: Details = {
          trace,
          svgPath,
          htmlPath,
          pngPath: pngResult.status === "rendered" ? pngPath : undefined,
          pngMode,
          pngStatus: pngResult.status,
          pngMessage: pngResult.message,
          inlinePngPreview: inlineMode,
          imageMaxWidthCells,
          imageMaxHeightCells
        };

        return {
          content: [],
          details: { ...details, temporary: true, glimpseStatus: glimpseResult.status, glimpseMessage: glimpseResult.message }
        };
      } finally {
        void rm(tempDir, { recursive: true, force: true });
      }
    },

    renderCall(_args, _theme, _context) {
      return new Text("", 0, 0);
    },

    renderResult(_result, _options, _theme, _context) {
      return new Text("", 0, 0);
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
        fileName: "ecowitt-call-stack",
        pngOutputMode: "if-available",
        pngWidth: 1600,
        inlinePngPreview: "when-expanded",
        imageMaxWidthCells: 88,
        imageMaxHeightCells: 28
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
  if (typeof value.svgPath !== "string" || typeof value.htmlPath !== "string") return undefined;
  if (!isPngMode(value.pngMode) || !isPngStatus(value.pngStatus) || !isInline(value.inlinePngPreview)) return undefined;
  if (typeof value.imageMaxWidthCells !== "number" || typeof value.imageMaxHeightCells !== "number") return undefined;
  if (value.pngPath !== undefined && typeof value.pngPath !== "string") return undefined;
  if (value.pngMessage !== undefined && typeof value.pngMessage !== "string") return undefined;
  return {
    trace: value.trace,
    svgPath: value.svgPath,
    htmlPath: value.htmlPath,
    pngPath: value.pngPath,
    pngMode: value.pngMode,
    pngStatus: value.pngStatus,
    pngMessage: value.pngMessage,
    inlinePngPreview: value.inlinePngPreview,
    imageMaxWidthCells: value.imageMaxWidthCells,
    imageMaxHeightCells: value.imageMaxHeightCells
  };
}

function normalizePngMode(value: unknown, inlineMode: InlineMode): PngMode {
  if (isPngMode(value)) return value;
  return inlineMode === "never" ? "never" : "if-available";
}
function isPngMode(value: unknown): value is PngMode { return value === "never" || value === "if-available" || value === "always"; }
function isPngStatus(value: unknown): value is Details["pngStatus"] { return value === "skipped" || value === "rendered" || value === "unavailable"; }
function normalizeInline(value: unknown): InlineMode { return isInline(value) ? value : "when-expanded"; }
function isInline(value: unknown): value is InlineMode { return value === "never" || value === "when-expanded" || value === "always"; }
function normalizeNumber(value: unknown, fallback: number): number { return typeof value === "number" && Number.isFinite(value) ? value : fallback; }
function safeFileName(value: string): string { const v = value.replaceAll(/[^a-zA-Z0-9._-]/g, "-").replaceAll(/-+/g, "-"); return v.length === 0 ? "call-stack" : v; }

function shouldShowImage(details: Details, expanded: boolean | undefined): boolean {
  if (details.pngStatus !== "rendered" || details.pngPath === undefined) return false;
  if (details.inlinePngPreview === "always") return true;
  if (details.inlinePngPreview === "when-expanded") return expanded === true;
  return false;
}

function readPng(path: string | undefined): string | undefined {
  if (path === undefined) return undefined;
  try { return readFileSync(path).toString("base64"); } catch { return undefined; }
}

function pngStatus(details: Details): string {
  if (details.pngStatus === "rendered") return details.pngPath ?? "rendered";
  return details.pngMessage ?? details.pngStatus;
}

function renderTree(trace: Trace, color: (name: string, value: string) => string, expanded: boolean | undefined): string {
  const lines: string[] = [];
  if (trace.command !== undefined) lines.push(color("muted", `$ ${trace.command}`), "");
  const limit = expanded ? Number.POSITIVE_INFINITY : 18;
  let count = 0;
  let truncated = false;
  const visit = (frame: Frame, depth: number, isLast: boolean): void => {
    if (count >= limit) { truncated = true; return; }
    const prefix = depth === 0 ? "● " : `${"  ".repeat(Math.max(0, depth - 1))}${isLast ? "└─" : "├─"} `;
    lines.push(color(depth === 0 ? "accent" : depth % 2 === 0 ? "text" : "muted", `${prefix}${frame.label}`));
    count += 1;
    const children = frame.children ?? [];
    for (let i = 0; i < children.length; i += 1) visit(children[i], depth + 1, i === children.length - 1);
  };
  visit(trace.root, 0, true);
  if (truncated) lines.push(color("dim", "…"));
  return lines.join("\n");
}

type PngResult = Readonly<{ status: "skipped" | "rendered" | "unavailable"; message?: string }>;

async function maybeRenderPng(input: { svg: string; pngPath: string; pngMode: PngMode; pngWidth?: number }): Promise<PngResult> {
  if (input.pngMode === "never") return { status: "skipped", message: "disabled by pngOutputMode=never" };
  const sharp = await trySharp(input);
  if (sharp.status === "rendered") return sharp;
  const cli = await tryCli(input);
  if (cli.status === "rendered") return cli;
  return { status: "unavailable", message: cli.message ?? sharp.message ?? "no PNG renderer available" };
}

type SharpPipeline = { resize: (o: { width?: number }) => SharpPipeline; png: () => SharpPipeline; toFile: (path: string) => Promise<unknown> };
type SharpFactory = (input: Buffer) => SharpPipeline;

async function trySharp(input: { svg: string; pngPath: string; pngWidth?: number }): Promise<PngResult> {
  try {
    const mod: unknown = await import("sharp");
    const sharp = typeof mod === "function" ? mod as SharpFactory : isRecord(mod) && typeof mod.default === "function" ? mod.default as SharpFactory : undefined;
    if (sharp === undefined) return { status: "unavailable", message: "sharp could not be loaded" };
    let pipeline = sharp(Buffer.from(input.svg));
    if (typeof input.pngWidth === "number") pipeline = pipeline.resize({ width: Math.floor(input.pngWidth) });
    await pipeline.png().toFile(input.pngPath);
    return { status: "rendered", message: "rendered with sharp" };
  } catch {
    return { status: "unavailable", message: "sharp not available" };
  }
}

async function tryCli(input: { svg: string; pngPath: string; pngWidth?: number }): Promise<PngResult> {
  const svgPath = join(tmpdir(), `pi-call-stack-${Date.now()}-${Math.random().toString(16).slice(2)}.svg`);
  await writeFile(svgPath, input.svg, "utf8");
  const width = typeof input.pngWidth === "number" ? Math.floor(input.pngWidth) : undefined;
  const attempts = [
    { command: "magick", args: width === undefined ? [svgPath, input.pngPath] : [svgPath, "-resize", `${width}x`, input.pngPath], label: "ImageMagick" },
    { command: "rsvg-convert", args: width === undefined ? [svgPath, "-o", input.pngPath] : [svgPath, "-o", input.pngPath, "-w", `${width}`], label: "librsvg" }
  ];
  for (const attempt of attempts) {
    if (await run(attempt.command, attempt.args)) return { status: "rendered", message: `rendered with ${attempt.label}` };
  }
  return { status: "unavailable", message: "no supported CLI PNG renderer found" };
}

function run(command: string, args: readonly string[]): Promise<boolean> {
  return new Promise((resolveRun) => {
    const child = spawn(command, args, { stdio: "ignore" });
    child.on("error", () => resolveRun(false));
    child.on("exit", (code) => resolveRun(code === 0));
  });
}

type GlimpseResult = Readonly<{ status: "launched" | "unavailable"; message: string }>;

type GlimpseModule = Readonly<{ open?: (html: string, options?: Record<string, unknown>) => unknown }>;

async function openGlimpseui(htmlPath: string): Promise<GlimpseResult> {
  const html = readFileSync(htmlPath, "utf8");
  const home = process.env.HOME;
  const localModule = home === undefined ? undefined : join(home, ".pi", "agent", "npm", "node_modules", "glimpseui", "src", "glimpse.mjs");
  const specifiers = [
    "glimpseui",
    ...(localModule !== undefined && existsSync(localModule) ? [pathToFileURL(localModule).href] : [])
  ];

  for (const specifier of specifiers) {
    try {
      const mod = (await import(specifier)) as GlimpseModule;
      if (typeof mod.open !== "function") continue;
      mod.open(html, {
        width: 1200,
        height: 820,
        title: "Call Stack Trace",
        openLinks: true
      });
      return { status: "launched", message: `opened with ${specifier === "glimpseui" ? "glimpseui" : localModule}` };
    } catch {
      // try next candidate
    }
  }

  return { status: "unavailable", message: "glimpseui could not be imported" };
}

type Line = Readonly<{ label: string; depth: number; index: number }>;

function flatten(root: Frame): readonly Line[] {
  const lines: Line[] = [];
  const visit = (frame: Frame, depth: number): void => {
    lines.push({ label: frame.label, depth, index: lines.length });
    for (const child of frame.children ?? []) visit(child, depth + 1);
  };
  visit(root, 0);
  return lines;
}

function renderSvg(trace: Trace, options: { animated: boolean }): string {
  const p = { mauve: "#cba6f7", pink: "#f5c2e7", blue: "#89b4fa", lavender: "#b4befe", green: "#a6e3a1", teal: "#94e2d5", yellow: "#f9e2af", peach: "#fab387", text: "#cdd6f4", subtext1: "#bac2de", overlay1: "#7f849c", surface1: "#45475a", surface0: "#313244", base: "#1e1e2e", crust: "#11111b" };
  const c = { width: 1450, padding: 36, rowHeight: 34, indentWidth: 34, fontSize: 18, animationMs: 360, animationDelayMs: 90, headerHeight: 64, headerInset: 16, sectionLabelGap: 18, sectionToRowsGap: 20, bottomPadding: 28 };
  const accents = [p.mauve, p.blue, p.teal, p.green, p.yellow, p.peach, p.pink, p.lavender];
  const lines = flatten(trace.root);
  const maxDepth = Math.max(...lines.map((line) => line.depth), 0);
  const cardX = c.padding;
  const cardY = c.padding;
  const cardWidth = c.width - c.padding * 2;
  const headerY = cardY + c.headerInset;
  const sectionY = headerY + c.headerHeight + c.sectionLabelGap;
  const firstRowY = sectionY + c.sectionToRowsGap;
  const cardHeight = firstRowY - cardY + lines.length * c.rowHeight + c.bottomPadding;
  const height = cardY + cardHeight + c.padding;
  const timelineLeft = cardX + 48;
  const markerRadius = 5;
  const markerX = (depth: number): number => timelineLeft + depth * c.indentWidth;
  const baseline = (index: number): number => firstRowY + index * c.rowHeight + c.rowHeight * 0.66;
  const markerY = (index: number): number => baseline(index) - 1;
  const command = trace.command ?? "call-stack";
  const pillWidth = Math.min(c.width - c.padding * 2 - 32, command.length * c.fontSize * 0.67 + 36);

  const header = [
    `<g class="header-wrap">`,
    `<rect class="header-panel" x="${cardX + 16}" y="${headerY}" width="${cardWidth - 32}" height="${c.headerHeight}" rx="18" />`,
    `<text class="title-text" x="${cardX + 38}" y="${headerY + 25}">Call Stack Trace</text>`,
    `<rect class="command-pill-bg" x="${cardX + 34}" y="${headerY + 34}" width="${fmt(pillWidth)}" height="22" rx="11" />`,
    `<circle class="command-pill-dot" cx="${cardX + 47}" cy="${headerY + 45}" r="4" />`,
    `<text class="command-text" x="${cardX + 58}" y="${headerY + 49}">${xml(command)}</text>`,
    `</g>`
  ].join("\n");

  const guides = Array.from({ length: maxDepth + 1 }, (_, depth) => {
    const x = markerX(depth);
    const opacity = Math.max(0.1, 0.34 - depth * 0.025);
    return `<line class="indent-guide" x1="${fmt(x)}" y1="${fmt(markerY(0) + 8)}" x2="${fmt(x)}" y2="${fmt(markerY(lines.length - 1) - 8)}" style="opacity:${fmt(opacity)}" />`;
  }).join("\n");

  const rows = lines.map((line) => {
    const y = firstRowY + line.index * c.rowHeight;
    const cy = markerY(line.index);
    const cx = markerX(line.depth);
    const accent = accents[line.depth % accents.length];
    const branch = line.depth === 0 ? "" : `<path class="branch-elbow" d="M ${fmt(markerX(line.depth - 1))} ${fmt(cy)} H ${fmt(cx - markerRadius - 4)}" style="stroke:${accent}" />`;
    return [
      `<g class="trace-line" style="animation-delay:${line.index * c.animationDelayMs}ms">`,
      `<rect class="line-bg" x="${cardX + 14}" y="${fmt(y + 4)}" width="${cardWidth - 28}" height="${c.rowHeight - 8}" rx="10" />`,
      branch,
      `<circle class="line-marker" cx="${fmt(cx)}" cy="${fmt(cy)}" r="${markerRadius}" style="fill:${accent};filter:url(#glow)" />`,
      `<text class="trace-text" x="${fmt(cx + 18)}" y="${fmt(baseline(line.index))}">${xml(line.label)}</text>`,
      `</g>`
    ].join("\n");
  }).join("\n");

  return [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${c.width}" height="${fmt(height)}" viewBox="0 0 ${c.width} ${fmt(height)}" role="img">`,
    `<title>Catppuccin call stack trace</title>`,
    `<defs><linearGradient id="bgGradient" x1="0" y1="0" x2="1" y2="1"><stop offset="0%" stop-color="${p.crust}"/><stop offset="100%" stop-color="${p.base}"/></linearGradient><filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="2.5" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter><style>${css(c, p, options.animated)}</style></defs>`,
    `<rect class="page-bg" x="0" y="0" width="${c.width}" height="${fmt(height)}" />`,
    `<rect class="outer-glow" x="${cardX - 1}" y="${cardY - 1}" width="${cardWidth + 2}" height="${fmt(cardHeight + 2)}" rx="24" />`,
    `<rect class="card" x="${cardX}" y="${cardY}" width="${cardWidth}" height="${fmt(cardHeight)}" rx="24" />`,
    header,
    `<text class="section-label" x="${cardX + 22}" y="${fmt(sectionY)}">Execution path</text>`,
    guides,
    rows,
    `</svg>`
  ].join("\n");
}

function css(c: { fontSize: number; animationMs: number }, p: Record<string, string>, animated: boolean): string {
  const animation = animated
    ? `.header-wrap{opacity:0;animation:fade-in 500ms ease-out forwards}.trace-line{opacity:0;transform:translateY(10px);animation:trace-enter ${c.animationMs}ms cubic-bezier(.22,1,.36,1) forwards}@keyframes trace-enter{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}@keyframes fade-in{from{opacity:0}to{opacity:1}}`
    : `.header-wrap{opacity:1}.trace-line{opacity:1;transform:translateY(0)}`;
  return `.page-bg{fill:url(#bgGradient)}.outer-glow{fill:none;stroke:${p.surface0};stroke-width:1;opacity:.7}.card{fill:rgba(30,30,46,.92);stroke:${p.surface0};stroke-width:1}.header-panel{fill:rgba(24,24,37,.96);stroke:${p.surface0};stroke-width:1}.title-text{font-family:Inter,ui-sans-serif,system-ui,sans-serif;font-size:18px;font-weight:700;fill:${p.text};letter-spacing:.2px}.command-pill-bg{fill:${p.surface0};stroke:${p.surface1};stroke-width:1}.command-pill-dot{fill:${p.mauve}}.command-text{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:13px;fill:${p.subtext1}}.section-label{font-family:Inter,ui-sans-serif,system-ui,sans-serif;font-size:12px;font-weight:600;fill:${p.overlay1};letter-spacing:1px;text-transform:uppercase}.indent-guide{stroke:${p.surface1};stroke-width:1;stroke-dasharray:2 8}.branch-elbow{fill:none;stroke-width:2;stroke-linecap:round;opacity:.82}.line-bg{fill:rgba(49,50,68,0);stroke:rgba(69,71,90,0)}.trace-text{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace;font-size:${c.fontSize}px;fill:${p.text};white-space:pre}.line-marker{stroke:rgba(17,17,27,.6);stroke-width:1.5}${animation}`;
}

function renderHtml(svg: string): string {
  return `<!doctype html><html lang="en"><head><meta charset="utf-8"/><title>Call Stack Preview</title><style>html,body{margin:0;min-height:100%;background:#11111b}body{display:grid;place-items:start center;padding:24px;box-sizing:border-box}svg{max-width:100%;height:auto;border-radius:24px;box-shadow:0 20px 60px rgba(0,0,0,.35)}</style></head><body>${svg}</body></html>`;
}

function xml(value: string): string { return value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&apos;"); }
function fmt(value: number): string { return Number.isInteger(value) ? String(value) : value.toFixed(2); }
