# Pi call stack visualization extension

Tool-first Pi extension that registers `render_call_stack`.

## Install / reload

This extension is project-local at:

```txt
.pi/extensions/call-stack-viz/index.ts
```

Run `/reload` in Pi after checking out the branch.

## Tool parameters

- `traceJson`: required JSON string shaped like `{ command?: string, root: { label: string, children?: [...] } }`
- `fileName`: optional artifact base name
- `pngOutputMode`: `never`, `if-available`, or `always`
- `pngWidth`: optional PNG width in pixels
- `inlinePngPreview`: `never`, `when-expanded`, or `always`
- `imageMaxWidthCells`: max inline image width in terminal cells
- `imageMaxHeightCells`: max inline image height in terminal cells

## Defaults

- `inlinePngPreview`: `when-expanded`
- `pngOutputMode`: `if-available` unless `inlinePngPreview` is `never`
- `imageMaxWidthCells`: `80`
- `imageMaxHeightCells`: `24`

## PNG rendering

The extension always writes SVG and HTML artifacts. When PNG output is enabled, it tries renderers in this order:

1. `sharp`
2. `magick` from ImageMagick
3. `rsvg-convert` from librsvg

The PNG is generated from a static SVG version so raster output does not capture the first hidden animation frame.

## Inline preview

If PNG rendering succeeds and `inlinePngPreview` allows it, the tool result renders an inline `Image` component. If the terminal does not support inline images, artifact paths are still shown in expanded output.
