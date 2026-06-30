# Pi call stack hierarchy extension

Tool-first Pi extension that registers `render_call_stack`.

The extension renders call stacks as a pure ASCII terminal hierarchy. It does not generate SVG, HTML, PNG, or inline image artifacts.

## Install / reload

This extension is project-local at:

```txt
.pi/extensions/call-stack-viz/index.ts
```

Run `/reload` in Pi after checking out the branch.

## Tool parameters

- `traceJson`: required JSON string shaped like `{ command?: string, root: { label: string, children?: [...] } }`
- `fileName`: optional legacy parameter used only in the tool call label

## Output

The terminal hierarchy uses pure ASCII for reliable alignment across fonts and terminals:

```txt
worker.ts
`-- CloudflareWorker.fetch(request, env, ctx)
    `-- HttpRouter.match("POST /api/ecowitt")
        |-- RequestBody.json(request)
        |-- EcowittWebhookSchema.decodeUnknown(payload)
        |   |-- parseStationId
        |   |-- parseOutdoorTemperature
        |   |-- parseHumidity
        |   `-- parseWindAndRain
        `-- HttpResponse.json({ ok: true })
```
