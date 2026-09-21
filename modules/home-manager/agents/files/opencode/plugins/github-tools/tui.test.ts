import { describe, expect, test } from "bun:test";

import { parsePullRequestCommandArguments } from "./tui.js";

describe("parsePullRequestCommandArguments", () => {
  test("separates control flags from user guidance", () => {
    expect(
      parsePullRequestCommandArguments("--watch --describe use branch feature-x")
    ).toEqual({
      describe: true,
      request: "use branch feature-x",
      watchChecks: true,
    });
  });

  test("accepts every description alias", () => {
    for (const flag of ["--describe", "--update", "--refresh"]) {
      expect(parsePullRequestCommandArguments(flag).describe).toBe(true);
    }
  });

  test("handles empty arguments", () => {
    expect(parsePullRequestCommandArguments("  ")).toEqual({
      describe: false,
      request: "",
      watchChecks: false,
    });
  });
});
