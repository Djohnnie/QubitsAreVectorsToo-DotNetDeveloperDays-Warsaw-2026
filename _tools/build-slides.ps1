[CmdletBinding()]
param(
    [int[]]$OnlySlides
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$slides = Join-Path $root '_slides'
$resources = Join-Path $root '_resources'

function DataUri([string]$path, [string]$mime) {
    "data:$mime;base64,$([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)))"
}

$regular = DataUri (Join-Path $resources 'fonts\OpenSans-Regular.ttf') 'font/ttf'
$bold = DataUri (Join-Path $resources 'fonts\OpenSans-Bold.ttf') 'font/ttf'
$heading = DataUri (Join-Path $resources 'fonts\Raleway-Bold.ttf') 'font/ttf'
$logo = DataUri (Join-Path $resources 'developerdays-logo.png') 'image/png'
$speakerPhoto = DataUri (Join-Path $resources 'speaker-photo.jpg') 'image/jpeg'
$qrCode = DataUri (Join-Path $resources 'qrcode.svg') 'image/svg+xml'
$defs = @"
<defs>
  <clipPath id="speaker-photo-clip"><circle cx="360" cy="560" r="215"/></clipPath>
  <style>
    @font-face{font-family:'Open Sans';font-weight:400;src:url('$regular') format('truetype')}
    @font-face{font-family:'Open Sans';font-weight:700;src:url('$bold') format('truetype')}
    @font-face{font-family:Raleway;font-weight:700;src:url('$heading') format('truetype')}
    text{font-family:'Open Sans',sans-serif;fill:#cccccc}
    .heading{font-family:Raleway,sans-serif;font-weight:700;fill:#ffffff;letter-spacing:-2px}
    .label{font-size:20px;letter-spacing:3px;font-weight:700;fill:#ff6a3f}
    .math{font-family:'Open Sans',sans-serif;fill:#ffffff}
  </style>
  <linearGradient id="accent" x1="0" y1="1" x2="1" y2="0">
    <stop stop-color="#bd0926"/><stop offset="1" stop-color="#ff6a3f"/>
  </linearGradient>
  <radialGradient id="glow">
    <stop stop-color="#bd0926" stop-opacity=".22"/><stop offset="1" stop-color="#bd0926" stop-opacity="0"/>
  </radialGradient>
  <pattern id="grid" width="60" height="60" patternUnits="userSpaceOnUse">
    <path d="M 60 0 L 0 0 0 60" fill="none" stroke="#444444" stroke-width="1" opacity=".25"/>
  </pattern>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 Z" fill="#ff6a3f"/>
  </marker>
</defs>
"@

function Text([int]$x, [int]$y, [string]$value, [int]$size = 32, [string]$class = '') {
    '<text x="{0}" y="{1}" font-size="{2}" class="{3}">{4}</text>' -f $x, $y, $size, $class, [Security.SecurityElement]::Escape($value)
}

function Lines([int]$x, [int]$y, [string[]]$values, [int]$size = 32, [int]$gap = 52, [string]$class = '') {
    for ($i = 0; $i -lt $values.Count; $i++) {
        Text $x ($y + $i * $gap) $values[$i] $size $class
    }
}

function Panel([int]$x, [int]$y, [int]$w, [int]$h) {
    "<rect x='$x' y='$y' width='$w' height='$h' rx='16' fill='#282828' stroke='#444444'/>"
}

function Orbit([int]$x = 1450, [int]$y = 560) {
    @"
<g transform="translate($x $y)">
  <circle r="460" fill="url(#glow)"/>
  <circle r="300" fill="url(#grid)" stroke="#444444" stroke-width="2"/>
  <ellipse rx="300" ry="110" fill="none" stroke="#bd0926" stroke-width="3" transform="rotate(-35)"/>
  <ellipse rx="300" ry="110" fill="none" stroke="#ff6a3f" stroke-width="3" transform="rotate(35)" opacity=".7"/>
  <path d="M-330 0H330 M0-330V330" stroke="#444444" stroke-width="2"/>
  <path d="M0 0L210-210" stroke="url(#accent)" stroke-width="8" marker-end="url(#arrow)"/>
  <circle r="12" fill="#ffffff"/><circle cx="210" cy="-210" r="16" fill="#ff6a3f"/>
  <text x="-205" y="385" class="math" font-size="46">|&#x03C8;&#x27E9; = &#x03B1;|0&#x27E9; + &#x03B2;|1&#x27E9;</text>
</g>
"@
}

function SaveSlide([string]$name, [string]$title, [string]$description, [string]$body, [string]$number, [string]$section = 'THE MATH BEHIND QUANTUM COMPUTING', [switch]$titleSlide) {
    if ($OnlySlides.Count -gt 0) {
        if ($name -notmatch '^slide-(\d+)\.svg$' -or [int]$Matches[1] -notin $OnlySlides) {
            return
        }
    }
    $safeTitle = [Security.SecurityElement]::Escape($title)
    $safeDescription = [Security.SecurityElement]::Escape($description)
    if ($titleSlide) {
        $slideHeader = "<image x='1170' y='405' width='600' height='273' href='$logo'/>"
        $slideFooter = ''
    } else {
        $slideHeader = @(
            (Text 100 100 $section 20 'label')
            "<image x='1580' y='55' width='240' height='109' href='$logo'/>"
        ) -join "`n"
        $slideFooter = @(
            '<path d="M100 985H1820" stroke="#444444"/>'
            "<a href='https://github.com/Djohnnie/QubitsAreVectorsToo-DotNetDeveloperDays-Warsaw-2026'>$(Text 100 1030 'github.com/Djohnnie/QubitsAreVectorsToo-DotNetDeveloperDays-Warsaw-2026' 24)</a>"
            "<text x='1820' y='1032' text-anchor='end' font-size='24' fill='#ffffff'>$number</text>"
        ) -join "`n"
    }
    $svg = @"
<?xml version="1.0" encoding="utf-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 1920 1080" role="img" aria-labelledby="title description">
<title id="title">$safeTitle</title>
<desc id="description">$safeDescription</desc>
$defs
<rect width="1920" height="1080" fill="#161616"/>
<rect width="1920" height="8" fill="url(#accent)"/>
$slideHeader
$body
$slideFooter
</svg>
"@
    [IO.File]::WriteAllText((Join-Path $slides $name), $svg, [Text.UTF8Encoding]::new($false))
}

$body = @(
    (Text 100 325 'Qubits Are' 104 'heading')
    (Text 100 445 'Vectors Too.' 104 'heading')
    '<rect x="100" y="495" width="180" height="8" fill="url(#accent)"/>'
    (Lines 100 585 @('The Math Behind', 'Quantum Computing') 44 62)
    (Text 100 805 'Johnny Hooyberghs' 34 'heading')
    (Text 100 860 '.NET DeveloperDays / Warsaw / 2026' 26)
) -join "`n"
SaveSlide 'slide-01.svg' 'Qubits Are Vectors Too' 'Title slide with an enlarged .NET DeveloperDays logo.' $body '01' 'LINEAR ALGEBRA. QUANTUM IDEAS. DEVELOPER INTUITION.' -titleSlide

$body = @(
    (Text 100 245 'Johnny Hooyberghs' 72 'heading')
    "<image x='145' y='345' width='430' height='430' preserveAspectRatio='xMidYMid slice' clip-path='url(#speaker-photo-clip)' href='$speakerPhoto'/>"
    '<circle cx="360" cy="560" r="215" fill="none" stroke="#bd0926" stroke-width="3"/>'
    '<circle cx="750" cy="380" r="7" fill="#ff6a3f"/>'
    (Lines 780 390 @('Focus on .NET custom application development,', 'Azure Cloud, and GenAI') 34 44)
    '<circle cx="750" cy="500" r="7" fill="#ff6a3f"/>'
    (Lines 780 510 @('18 years of professional experience as a', 'software enthusiast') 34 44)
    '<circle cx="750" cy="620" r="7" fill="#ff6a3f"/>'
    (Text 780 630 'Interested in Quantum Computing' 34)
    '<circle cx="750" cy="740" r="7" fill="#ff6a3f"/>'
    (Text 780 750 'Public speaker and trainer' 34)
    '<circle cx="750" cy="840" r="7" fill="#ff6a3f"/>'
    (Lines 780 850 @('Microsoft MVP in Developer Technologies', 'and Microsoft Azure since 2020') 34 44)
) -join "`n"
SaveSlide 'slide-02.svg' 'Johnny Hooyberghs' 'Johnny Hooyberghs, Microsoft MVP and speaker, with his professional background and interests.' $body '02' 'ABOUT THE SPEAKER'

$repoUrl = 'https://github.com/Djohnnie/QubitsAreVectorsToo-DotNetDeveloperDays-Warsaw-2026'
$body = @(
    (Text 100 245 'Scan to visit the repository.' 72 'heading')
    "<a href='$repoUrl'><image x='690' y='300' width='540' height='540' href='$qrCode'/></a>"
) -join "`n"
SaveSlide 'slide-03.svg' 'Scan to visit the repository' 'Centered QR code linking to the GitHub repository for this presentation.' $body '03' 'FOLLOW ALONG'

$body = @(
    (Text 100 245 'From vectors to qubits.' 72 'heading')
    (Text 100 315 'A suggested route through the talk' 28)
) -join "`n"
$topics = @(
    @('01', 'State', 'Vectors, basis states and amplitudes'),
    @('02', 'Change', 'Matrices, gates and interference'),
    @('03', 'Observe', 'Measurement and probabilities'),
    @('04', 'Build', 'A small developer-friendly demo')
)
for ($i = 0; $i -lt $topics.Count; $i++) {
    $y = 390 + $i * 132
    $body += (Text 110 ($y + 40) $topics[$i][0] 40 'label')
    $body += (Text 230 ($y + 40) $topics[$i][1] 42 'heading')
    $body += (Text 620 ($y + 40) $topics[$i][2] 32)
    $body += "<path d='M230 $($y + 85)H1810' stroke='#444444'/>"
}
SaveSlide 'slide-04.svg' 'Session roadmap' 'Four suggested sections: state, change, observe, and build.' $body '04' 'THE ROADMAP'

$body = @(
    '<circle cx="1500" cy="560" r="490" fill="url(#glow)"/>'
    '<text x="1170" y="800" font-family="Raleway" font-weight="700" font-size="550" style="fill:#282828">01</text>'
    (Text 100 395 'STATE' 24 'label')
    (Lines 100 535 @('Start with', 'a vector.') 100 130 'heading')
    (Text 100 835 'A qubit is a state, not a tiny classical switch.' 36)
) -join "`n"
SaveSlide 'slide-05.svg' 'Start with a vector' 'Reusable section-divider layout for the first chapter.' $body '05' 'SECTION 01 / STATE'

# Unicode is represented by XML entities in formula markup.
$body = @(
    (Text 100 245 'A qubit has two amplitudes.' 72 'heading')
    (Panel 100 365 920 480)
    '<text x="160" y="535" class="math" font-size="60">|&#x03C8;&#x27E9; = &#x03B1;|0&#x27E9; + &#x03B2;|1&#x27E9;</text>'
    '<text x="160" y="645" class="math" font-size="48">|&#x03B1;|&#xB2; + |&#x03B2;|&#xB2; = 1</text>'
    (Lines 160 745 @('Amplitudes are complex numbers.', 'Their squared magnitudes give probabilities.') 28 45)
    '<g transform="translate(1430 590)">'
    '<circle r="230" fill="url(#grid)" stroke="#444444" stroke-width="2"/>'
    '<path d="M-265 0H270 M0 265V-270" stroke="#888888" stroke-width="2"/>'
    '<path d="M0 0L163-163" stroke="url(#accent)" stroke-width="7" marker-end="url(#arrow)"/>'
    '<circle cx="163" cy="-163" r="12" fill="#ff6a3f"/>'
    '<text x="265" y="45" class="math" font-size="32">|0&#x27E9;</text>'
    '<text x="25" y="-250" class="math" font-size="32">|1&#x27E9;</text>'
    '</g>'
    (Text 1140 910 'Illustration: real amplitudes only.' 24)
) -join "`n"
SaveSlide 'slide-06.svg' 'A qubit has two amplitudes' 'A normalized complex state vector. The diagram shows only the real-amplitude slice, not a Bloch sphere.' $body '06' 'CONCEPT / STATE VECTOR'

$body = @(
    (Text 100 245 'One gate. Two possibilities.' 72 'heading')
    (Text 100 315 'A first worked example: the Hadamard gate' 28)
    (Panel 100 375 770 440)
    (Text 155 455 'THE TRANSFORMATION' 20 'label')
    '<text x="155" y="590" class="math" font-size="62">H|0&#x27E9; = (|0&#x27E9; + |1&#x27E9;) / &#x221A;2</text>'
    (Lines 155 710 @('A deterministic operation.', 'A superposition as its output.') 30 50)
    (Text 1010 450 'MEASURE IN THE 0 / 1 BASIS' 20 'label')
    '<rect x="1040" y="520" width="260" height="270" rx="10" fill="#bd0926"/>'
    '<rect x="1430" y="520" width="260" height="270" rx="10" fill="#b34242"/>'
    '<text x="1170" y="635" text-anchor="middle" class="math" font-size="58">50%</text>'
    '<text x="1560" y="635" text-anchor="middle" class="math" font-size="58">50%</text>'
    '<text x="1170" y="725" text-anchor="middle" class="math" font-size="40">0</text>'
    '<text x="1560" y="725" text-anchor="middle" class="math" font-size="40">1</text>'
    (Text 100 905 'Equal outcome probabilities do not mean two classical bits.' 32)
) -join "`n"
SaveSlide 'slide-07.svg' 'The Hadamard gate' 'Hadamard applied to zero gives equal amplitudes and equal computational-basis measurement probabilities.' $body '07' 'WORKED EXAMPLE / GATES'

$body = @(
    (Text 100 245 'A quantum program, at a glance.' 68 'heading')
    (Text 100 315 'A reusable diagram layout' 28)
) -join "`n"
$stages = @(
    @('Prepare', '|0>', 'Choose an initial state'),
    @('Transform', 'U', 'Apply unitary gates'),
    @('Measure', '0 / 1', 'Sample an outcome')
)
for ($i = 0; $i -lt $stages.Count; $i++) {
    $x = 100 + 600 * $i
    $body += (Panel $x 420 520 360)
    $body += (Text ($x + 45) 495 $stages[$i][0] 40 'heading')
    $body += (Text ($x + 45) 610 $stages[$i][1] 68 'math')
    $body += (Text ($x + 45) 715 $stages[$i][2] 28)
    if ($i -lt 2) {
        $body += "<path d='M$($x + 535) 600H$($x + 585)' stroke='#ff6a3f' stroke-width='4' marker-end='url(#arrow)'/>"
    }
}
$body += (Text 100 900 'Repeat the experiment to estimate the outcome distribution.' 32)
SaveSlide 'slide-08.svg' 'Prepare, transform, measure' 'A three-stage diagram showing preparation, unitary transformation, and measurement.' $body '08' 'DIAGRAM / PROGRAM FLOW'

$body = @(
    (Text 100 245 'Make the math executable.' 72 'heading')
    (Text 100 315 'Demo layout / implementation still to come' 28)
    (Panel 100 390 1030 470)
    (Text 155 470 'DEMO CANVAS' 20 'label')
    (Lines 155 570 @('Add a circuit, code excerpt,', 'or live-demo screenshot here.') 42 65 'heading')
    (Text 155 765 'Suggested demo: prepare |0>, apply H, sample outcomes.' 27)
    (Text 1230 455 'The audience should see' 34 'heading')
    (Lines 1230 555 @('01  The starting vector', '02  The gate operation', '03  The measurement counts') 28 75)
    (Lines 1230 820 @('Replace this placeholder', 'when the demo is ready.') 24 38)
) -join "`n"
SaveSlide 'slide-09.svg' 'Demo placeholder' 'A deliberately unfinished demo slide with a large content area and three suggested checkpoints.' $body '09' 'DEMO / RESERVED'

$body = @(
    (Text 100 395 'Thank you.' 112 'heading')
    (Text 100 525 'Any questions?' 64 'heading')
    '<rect x="100" y="590" width="180" height="8" fill="url(#accent)"/>'
    (Lines 100 695 @('States are vectors.', 'Gates transform them.', 'Measurement gives outcomes.') 34 58)
    (Orbit 1450 530)
    (Text 100 915 'Johnny Hooyberghs / Qubits Are Vectors Too' 26)
) -join "`n"
SaveSlide 'slide-10.svg' 'Thank you and questions' 'Closing slide with three starter takeaways and space for questions.' $body '10' 'LET US TALK QUANTUM'

$body = @(
    (Text 100 245 'Your slide title' 72 'heading')
    (Text 100 315 'Optional subtitle / one clear idea per slide' 28)
    (Panel 100 390 1720 490)
    (Text 155 470 'CONTENT AREA' 20 'label')
    (Lines 155 585 @('Replace with a diagram, a formula, or a short story.', 'Use the existing layouts as starting points.') 38 65 'heading')
    (Text 155 790 'Keep essential content inside the 100 px safe margins.' 28)
) -join "`n"
SaveSlide 'slide-template.svg' 'Reusable content template' 'Blank branded content layout, excluded from the PowerPoint export.' $body '--' 'SECTION / TOPIC'

if ($OnlySlides.Count -gt 0) {
    Write-Host "Built selected slides in $slides"
} else {
    Write-Host "Built 10 starter slides and slide-template.svg in $slides"
}
