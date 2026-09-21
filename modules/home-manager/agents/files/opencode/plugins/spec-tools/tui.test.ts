import { describe, expect, test } from "bun:test";

import { buildBackgroundScrubPrompt, buildSimplifyPrompt } from "./tui.js";

describe("spec prompts", () => {
  test("the simplify command remains advisory", () => {
    const prompt = buildSimplifyPrompt("specs/example.md");

    expect(prompt).toContain("Read @specs/example.md completely.");
    expect(prompt).toContain("Do not edit any files.");
  });

  test("the background scrub command delegates exactly once", () => {
    const prompt = buildBackgroundScrubPrompt("specs/example.md");

    expect(prompt).toContain('agent: "general"');
    expect(prompt).toContain("background: true");
    expect(prompt).toContain("Call the subagent tool exactly once");
  });
});
