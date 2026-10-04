# Copilot instructions

## Build and validation

Run commands from the repository root in PowerShell.

- Regenerate all slide SVGs and the reusable template: `.\_tools\build-slides.ps1`
- Regenerate selected slides only, for example slide 3: `.\_tools\build-slides.ps1 -OnlySlides 3`
- Export all numbered slides to the root PowerPoint: `.\_tools\svg_to_pptx.ps1`
- Export to a custom path: `.\_tools\svg_to_pptx.ps1 -SvgDir .\_slides -Output .\MyDeck.pptx`

The SVG generator has no separate test mode; `-OnlySlides` is the narrowest
build check. There is no automated test or lint suite in the repository. The
PowerPoint exporter renders every numbered SVG with headless Microsoft Edge
and fails if rendering fails. If Edge is not in its standard install location,
pass `-EdgePath 'C:\path\to\msedge.exe'`.

## Architecture

The SVGs in `_slides` are the canonical presentation sources. `_tools\build-slides.ps1`
defines shared typography, colors, gradients, reusable drawing helpers, and
slide content; its `SaveSlide` helper wraps each body in the shared SVG frame
and writes `slide-01.svg` through `slide-10.svg` plus `slide-template.svg`.
The presentation assets used by the generator are embedded as data URIs, so
the exported SVGs are portable. Source assets, fonts, and notices live in
`_resources`.

`_slides\index.html` previews the numbered slides offline and uses its `titles`
array for navigation and accessible labels. `_tools\svg_to_pptx.ps1` consumes
only files matching `slide-NN.svg`, sorts them by filename, renders each as a
full-slide image, and packages those images into a 16:9 PowerPoint. The template
is not exported, and PowerPoint slides are images rather than editable text or
shapes.

## Conventions specific to this deck

- The SVG canvas is 3840 × 2160 with a 1920 × 1080 viewBox. Layout coordinates
  and font sizes in the generator use the viewBox units.
- Keep content inside the 100-unit horizontal safe margins and above the footer
  divider at y=985. Normal body copy is generally 28 units or larger.
- Shared styling is in `$defs` and the `Text`, `Lines`, `Panel`, and `Orbit`
  helpers in the generator. Use those for slide content where applicable.
- `Text` XML-escapes plain text. For raw SVG markup such as equations, use XML
  entities for special characters; do not pass markup through `Text`.
- The generator supports a selected-slide build to avoid overwriting unrelated
  SVGs. Full regeneration overwrites all numbered SVGs and the template.
- Slides 2–10 have the linked repository caption and right-aligned slide number;
  slide 1 intentionally has no footer. SVG links work in the preview, but are
  lost when exported as slide images.
- When changing slide titles or adding numbered slides, keep `_slides\index.html`
  navigation titles and the README slide previews/descriptions in sync.
- Shared visual tokens are documented in the root README. Fonts, conference
  logo, speaker portrait, and QR code have associated notices or source credits;
  retain those credits when changing or replacing assets.
