# Pi call stack visualization extension

Tool-first Pi extension that registers `render_call_stack` and opens the visualization outside Pi with `glimpseui`.

## Install / reload

This extension is project-local at:

```txt
.pi/extensions/call-stack-viz/index.ts
```

Run `/reload` in Pi after checking out the branch.

## Tool parameters

- `traceJson`: required JSON string shaped like `{ command?: string, root: { label: string, children?: [...] } }`
- `fileName`: optional temporary file base name
- `pngOutputMode`: `never`, `if-available`, or `always`
- `pngWidth`: optional PNG width in pixels
- `inlinePngPreview`: retained for compatibility; Pi inline rendering is disabled
- `imageMaxWidthCells`: retained for compatibility
- `imageMaxHeightCells`: retained for compatibility

## Defaults

- `inlinePngPreview`: `when-expanded`
- `pngOutputMode`: `if-available` unless `inlinePngPreview` is `never`
- `imageMaxWidthCells`: `80`
- `imageMaxHeightCells`: `24`

## PNG rendering

The extension writes SVG and HTML only inside a temporary directory. When PNG output is enabled, it tries renderers in this order:

1. `sharp`
2. `magick` from ImageMagick
3. `rsvg-convert` from librsvg

The PNG is generated from a static SVG version so raster output does not capture the first hidden animation frame.

## GlimpseUI preview

The extension writes SVG/HTML to a temporary directory, imports `glimpseui`, reads the temporary HTML, and calls `open(html, ...)` to show the preview in a native window. The temporary directory is removed after launch. Tool call and result rendering inside Pi are intentionally blank.

Resolution order:

1. Bare import: `glimpseui`
2. Pi package install path: `~/.pi/agent/npm/node_modules/glimpseui/src/glimpse.mjs`

Install with:

```bash
pi install npm:glimpseui
```
