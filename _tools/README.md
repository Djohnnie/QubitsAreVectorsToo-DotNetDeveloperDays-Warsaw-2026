# Presentation tools

The reference deck uses numbered SVG sources in `_slides`, a reusable SVG
template, and a full-bleed image-based PowerPoint export. This repository keeps
that structure. The tools use PowerShell and Microsoft Edge, with no Python,
Node.js, or package installation required.

## Build the SVG sources

From the repository root:

```powershell
.\_tools\build-slides.ps1
```

To regenerate only selected numbered slides without touching the others:

```powershell
.\_tools\build-slides.ps1 -OnlySlides 1
```

Edit the content and layouts in `build-slides.ps1` and rerun it. It regenerates
`slide-01.svg` through `slide-10.svg` and `slide-template.svg`, including embedded
fonts, the conference logo, speaker photo, and QR code from `_resources`.
**Regeneration overwrites those SVG files.**
Alternatively, edit or duplicate the SVGs directly and do not regenerate them.

The slides have a 3840 x 2160 canvas and a 1920 x 1080 coordinate system. Keep
important content within the 100-unit horizontal margins and above the footer
at y=985. Use Raleway 700 for headings, Open Sans for body text, and at least
28 units for normal body copy. XML-escape text; use XML entities for mathematical
symbols when editing the generator.

Slides 2–10 include a small linked repository caption in the footer; slide
numbers remain aligned at the far right. The title slide has no footer.

## Export PowerPoint

```powershell
.\_tools\svg_to_pptx.ps1
```

Custom input and output:

```powershell
.\_tools\svg_to_pptx.ps1 -SvgDir .\_slides -Output .\MyDeck.pptx
```

The exporter collects only `slide-NN.svg` files, sorts them by name, renders each
at 3840 x 2160 using headless Edge, and writes a standard 16:9 PowerPoint package.
The template is excluded. A rendering failure stops generation, preserving an
existing output deck. Edge uses a temporary, isolated browser profile, which is
removed afterward.

If Edge is not installed in its standard Windows location, pass
`-EdgePath 'C:\path\to\msedge.exe'`.

**The exported PowerPoint slides are images, not editable text or shapes.**
Edit the SVG source and export again. SVG hyperlinks are not preserved in the
image-based PowerPoint export. Fonts are embedded in SVGs and rasterized into
the exported slides; they do not need to be installed to view the deck.

## Preview

Open `_slides\index.html` in a browser, without a server or internet connection.
Use the buttons or Left/Right, Page Up/Down, Home/End, and Space keys. The
**Open SVG** link opens the current slide with its selectable text and links.
When adding slides, also update the preview's `titles` array and README previews.
