# Prompt Refine Extension

**Status:** Ready for implementation  
**Type:** Extension / workflow tool  
**Effort:** S  
**Date:** 2026-03-27

## Goal

Add a new Pi extension that:

1. starts a dedicated **fresh branch** for prompt refinement,
2. lets the user refine a pasted prompt in that branch,
3. returns to the original session position, and
4. sends back **only the refined prompt**.

This should reuse the same session-tree branching pattern already used by:

- `modules/home-manager/agents/files/pi/extensions/review.ts`

## Why

Prompt refinement is useful, but it should not clutter the main working session.
A separate branch gives the user a scratch space for clarifying and improving a prompt while preserving the original conversation path.

## Scope

Create a standalone extension file:

- `modules/home-manager/agents/files/pi/extensions/refine-prompt.ts`

### In scope

- `/refine-prompt` command
- `/end-refine` command
- always using a **fresh branch**
- origin tracking and return-to-origin behavior
- empty-session anchor handling
- active branch widget/state
- extraction of the final refined prompt
- returning without summary
- sending the extracted prompt back into the original branch

### Out of scope

- current-session mode
- branch summaries
- multiple end actions
- prompt presets/templates
- multiple input sources
- refactoring shared helpers out of `review.ts`

## Discovery

The existing `review.ts` extension already contains the branching behavior we want to mirror.

### Relevant behaviors to reuse from `review.ts`

- save current location with `ctx.sessionManager.getLeafId()`
- create a lightweight custom anchor entry if the session has no leaf yet
- branch by navigating to the first user message
- label the branch during navigation
- persist active branch state in a custom entry
- restore active state on:
  - `session_start`
  - `session_switch`
  - `session_tree`
- return later by navigating back to the saved origin id

### Things we do not need from `review.ts`

- git integration
- PR/branch/commit selection
- review summaries
- findings parsing
- loop-fixing
- custom review settings

## User experience

### `/refine-prompt`

Flow:

1. User runs `/refine-prompt`
2. Extension opens an editor prompt for the raw prompt text
3. Extension always creates a **fresh branch**
4. Branch is labeled `refine-prompt`
5. Extension sends a seed instruction that starts the refinement conversation

### `/end-refine`

Flow:

1. Extension reads the latest assistant response in the refine branch
2. Extension extracts the final refined prompt
3. Extension returns to the original session position with `summarize: false`
4. Extension sends the extracted refined prompt back into the original branch as a follow-up message
5. Extension clears active refine state

## Required agent output contract

To make extraction reliable, the refinement branch must end with a strict final section.

Use this exact shape in the seed prompt:

````md
## Final Refined Prompt
```text
<final refined prompt here>
```
````

The extension should extract only the contents of that fenced `text` block.

## Commands

### `/refine-prompt`

Responsibilities:

- require interactive UI
- collect prompt text from an editor dialog
- reject empty input
- start a fresh branch using the saved-origin pattern from `review.ts`
- send the refinement seed prompt

### `/end-refine`

Responsibilities:

- confirm an active refine branch exists
- read the latest assistant message in the current branch
- extract `## Final Refined Prompt`
- fail safely if extraction is missing
- navigate back to the saved origin without summary
- send only the extracted prompt as a follow-up message
- clear active state

## Technical design

### File

- `modules/home-manager/agents/files/pi/extensions/refine-prompt.ts`

### State model

Custom entry types:

- `PROMPT_REFINE_STATE_TYPE = "refine-prompt-session"`
- `PROMPT_REFINE_ANCHOR_TYPE = "refine-prompt-anchor"`

Persisted state shape:

```ts
{
  active: boolean;
  originId?: string;
}
```

Module-level runtime state:

- `refineOriginId: string | undefined`
- `endRefineInProgress: boolean`

### State restoration hooks

Restore state on:

- `session_start`
- `session_switch`
- `session_tree`

This should match the pattern used in `review.ts` so tree navigation does not lose refine-session state.

### Branching logic

When `/refine-prompt` starts:

1. Read the current leaf with `ctx.sessionManager.getLeafId()`
2. If no leaf exists, append an anchor custom entry and read the leaf again
3. Save that leaf as `originId`
4. Find the first user message in the current session entries
5. If one exists, navigate to it with:

```ts
ctx.navigateTree(firstUserMessage.id, {
  summarize: false,
  label: "refine-prompt",
});
```

6. Clear the editor after navigation
7. Persist active refine state with the saved origin id

### Return logic

When `/end-refine` runs:

1. Resolve the active origin id from runtime state or persisted custom state
2. Read the latest assistant message in the branch
3. Extract the final prompt block
4. If extraction fails:
   - notify the user
   - stay in the current refine branch
   - do **not** clear state
5. If extraction succeeds:
   - `ctx.navigateTree(originId, { summarize: false })`
   - `pi.sendUserMessage(extractedPrompt, { deliverAs: "followUp" })`
   - clear refine state

## Seed prompt behavior

The seed prompt should instruct the agent to:

- act as a prompt refinement assistant
- improve the pasted prompt through short, targeted clarification
- ask only the questions that materially improve the final prompt
- produce a final version suitable for direct reuse
- end with the required `## Final Refined Prompt` fenced block

Recommended output shape:

1. brief clarification questions if needed
2. refined version once enough information is available
3. final required section with the exact extractable block

## Acceptance criteria

- [ ] `/refine-prompt` always starts a fresh branch
- [ ] empty sessions work by creating an anchor before branching
- [ ] the branch label is `refine-prompt`
- [ ] active refine state survives session/tree navigation
- [ ] `/end-refine` returns using `summarize: false`
- [ ] `/end-refine` sends only the extracted refined prompt back to the original branch
- [ ] extraction failure leaves the user in the refine branch with state intact
- [ ] the extension typechecks in `modules/home-manager/agents/files/pi/extensions`

## Implementation plan

### D1. Create the extension file

Create:

- `modules/home-manager/agents/files/pi/extensions/refine-prompt.ts`

Include:

- command registration
- state types/constants
- widget helper
- session restore hooks

### D2. Adapt fresh-branch session logic from `review.ts`

Reuse the proven patterns for:

- origin capture
- empty-session anchor creation
- branch navigation
- persisted state
- return-to-origin behavior

### D3. Add prompt input and seed prompt sending

Implement `/refine-prompt` to:

- open an editor dialog
- validate non-empty input
- branch into `refine-prompt`
- send the refinement seed message

### D4. Add final prompt extraction and `/end-refine`

Implement helpers to:

- read the latest assistant message in the branch
- parse the `## Final Refined Prompt` section
- extract the fenced `text` block exactly
- return and re-send the extracted prompt

### D5. Validate

Run:

```bash
cd modules/home-manager/agents/files/pi/extensions
npm run check
```

## Test strategy

| Layer | What to verify | How |
|---|---|---|
| Static | Extension compiles | `cd modules/home-manager/agents/files/pi/extensions && npm run check` |
| Existing-session flow | Fresh branch is created from a populated session | Start `/refine-prompt` in an existing session and confirm branch label + active widget |
| Empty-session flow | Anchor handling works | Start `/refine-prompt` in a new session and confirm `/end-refine` can still return |
| Return flow | Only refined prompt is re-sent | Complete refinement, run `/end-refine`, verify original branch receives only the extracted prompt |
| Failure handling | Missing final block is safe | Try `/end-refine` when the latest response does not contain the required block and confirm no navigation/state loss |

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Final prompt extraction is brittle | Medium | Use a strict heading + fenced `text` block contract |
| Navigation events clear runtime state | Medium | Persist custom state and restore on session/tree events |
| Logic duplication from `review.ts` drifts over time | Low | Accept duplication for MVP; extract shared helpers later if needed |
| Agent asks too many or too few questions | Low | Make the seed prompt explicit about asking only high-value clarification questions |

## Trade-offs

| Decision | Alternative | Reason |
|---|---|---|
| Always use a fresh branch | Offer current-session mode | Keeps the workflow deterministic and matches the intended return behavior |
| Return and send only | Summaries or multiple end actions | The user explicitly does not want summaries |
| Standalone implementation | Extract shared session helper first | Faster, lower-risk MVP |
| Strict extraction format | Heuristic parsing of arbitrary assistant output | More reliable and easier to validate |

## Success criteria

Success means:

- prompt refinement happens off the main branch
- returning requires one command
- the original branch receives a ready-to-use refined prompt automatically
- the workflow works in both empty and populated sessions

## Open questions

None for MVP.
