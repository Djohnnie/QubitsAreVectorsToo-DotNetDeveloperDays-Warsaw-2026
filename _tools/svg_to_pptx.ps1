[CmdletBinding()]
param(
    [string]$SvgDir = (Join-Path (Split-Path $PSScriptRoot -Parent) '_slides'),
    [string]$Output = (Join-Path (Split-Path $PSScriptRoot -Parent) 'QubitsAreVectorsToo-DotNetDeveloperDays-Warsaw-2026.pptx'),
    [string]$EdgePath
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$SvgDir = (Resolve-Path $SvgDir).Path
$Output = [IO.Path]::GetFullPath($Output)
$files = @(Get-ChildItem $SvgDir -File | Where-Object Name -Match '^slide-\d{2}\.svg$' | Sort-Object Name)
if ($files.Count -eq 0) { throw "No numbered slide-NN.svg files found in $SvgDir" }
if (-not $EdgePath) {
    $EdgePath = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path $_ -PathType Leaf } | Select-Object -First 1
}
if (-not $EdgePath -or -not (Test-Path $EdgePath -PathType Leaf)) {
    throw 'Microsoft Edge not found. Supply -EdgePath with its executable location.'
}

function WritePart([IO.Compression.ZipArchive]$zip, [string]$name, [string]$content) {
    $entry = $zip.CreateEntry($name)
    $writer = [IO.StreamWriter]::new($entry.Open(), [Text.UTF8Encoding]::new($false))
    try { $writer.Write($content) } finally { $writer.Dispose() }
}

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("qubits-deck-" + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($tmp) | Out-Null
$stagedOutput = Join-Path $tmp 'deck.pptx'
try {
    $zip = [IO.Compression.ZipArchive]::new([IO.File]::Create($stagedOutput), [IO.Compression.ZipArchiveMode]::Create)
    try {
        $types = '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/><Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/><Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/><Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>'
        $ids = ''
        $rels = '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="master" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>'
        $group = '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>'
        for ($i = 0; $i -lt $files.Count; $i++) {
            $n = $i + 1
            $png = Join-Path $tmp "slide$n.png"
            $html = Join-Path $tmp "slide$n.html"
            # Inline the SVG to avoid the browser's standalone-image margins.
            $svg = [IO.File]::ReadAllText($files[$i].FullName) -replace '<\?xml[^>]*\?>', ''
            [IO.File]::WriteAllText($html, "<!doctype html><html><head><meta charset='utf-8'><style>html,body{margin:0;width:3840px;height:2160px;overflow:hidden}svg{display:block}</style></head><body>$svg</body></html>", [Text.UTF8Encoding]::new($false))
            $url = [Uri]::new($html).AbsoluteUri
            $arguments = @('--headless=new', '--disable-gpu', '--no-first-run', '--hide-scrollbars',
                "--user-data-dir=$(Join-Path $tmp 'edge-profile')", '--force-device-scale-factor=1',
                '--window-size=3840,2160', '--virtual-time-budget=3000', "--screenshot=$png", $url)
            $process = Start-Process -FilePath $EdgePath -ArgumentList ($arguments | ForEach-Object { '"' + $_ + '"' }) -PassThru -RedirectStandardError (Join-Path $tmp "edge$n.log")
            if (-not $process.WaitForExit(60000)) {
                Stop-Process -Id $process.Id -Force
                throw "Edge timed out rendering $($files[$i].Name)"
            }
            if ($process.ExitCode -ne 0 -or -not (Test-Path $png)) {
                throw "Edge failed rendering $($files[$i].Name): $([IO.File]::ReadAllText((Join-Path $tmp "edge$n.log")))"
            }
            $entry = $zip.CreateEntry("ppt/media/image$n.png", [IO.Compression.CompressionLevel]::NoCompression)
            $stream = $entry.Open()
            try { $bytes = [IO.File]::ReadAllBytes($png); $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
            $types += "<Override PartName='/ppt/slides/slide$n.xml' ContentType='application/vnd.openxmlformats-officedocument.presentationml.slide+xml'/>"
            $ids += "<p:sldId id='$($n + 255)' r:id='slide$n'/>"
            $rels += "<Relationship Id='slide$n' Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide' Target='slides/slide$n.xml'/>"
            WritePart $zip "ppt/slides/slide$n.xml" @"
<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><p:cSld name="$($files[$i].BaseName)"><p:spTree>$group<p:pic><p:nvPicPr><p:cNvPr id="2" name="$($files[$i].BaseName)"/><p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr><p:nvPr/></p:nvPicPr><p:blipFill><a:blip r:embed="image"/><a:stretch><a:fillRect/></a:stretch></p:blipFill><p:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="12192000" cy="6858000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></p:spPr></p:pic></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>
"@
            WritePart $zip "ppt/slides/_rels/slide$n.xml.rels" "<Relationships xmlns='http://schemas.openxmlformats.org/package/2006/relationships'><Relationship Id='image' Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/image' Target='../media/image$n.png'/><Relationship Id='layout' Type='http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout' Target='../slideLayouts/slideLayout1.xml'/></Relationships>"
            Write-Host "Rendered [$n/$($files.Count)] $($files[$i].Name)"
        }
        WritePart $zip '[Content_Types].xml' "$types</Types>"
        WritePart $zip '_rels/.rels' '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="presentation" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/></Relationships>'
        WritePart $zip 'ppt/presentation.xml' "<p:presentation xmlns:p='http://schemas.openxmlformats.org/presentationml/2006/main' xmlns:r='http://schemas.openxmlformats.org/officeDocument/2006/relationships'><p:sldMasterIdLst><p:sldMasterId id='2147483648' r:id='master'/></p:sldMasterIdLst><p:sldIdLst>$ids</p:sldIdLst><p:sldSz cx='12192000' cy='6858000' type='screen16x9'/><p:notesSz cx='6858000' cy='9144000'/></p:presentation>"
        WritePart $zip 'ppt/_rels/presentation.xml.rels' "$rels</Relationships>"
        WritePart $zip 'ppt/slideMasters/slideMaster1.xml' "<p:sldMaster xmlns:p='http://schemas.openxmlformats.org/presentationml/2006/main' xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main' xmlns:r='http://schemas.openxmlformats.org/officeDocument/2006/relationships'><p:cSld><p:spTree>$group</p:spTree></p:cSld><p:clrMap bg1='lt1' tx1='dk1' bg2='lt2' tx2='dk2' accent1='accent1' accent2='accent2' accent3='accent3' accent4='accent4' accent5='accent5' accent6='accent6' hlink='hlink' folHlink='folHlink'/><p:sldLayoutIdLst><p:sldLayoutId id='2147483649' r:id='layout'/></p:sldLayoutIdLst></p:sldMaster>"
        WritePart $zip 'ppt/slideMasters/_rels/slideMaster1.xml.rels' '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="layout" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/><Relationship Id="theme" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/></Relationships>'
        WritePart $zip 'ppt/slideLayouts/slideLayout1.xml' "<p:sldLayout xmlns:p='http://schemas.openxmlformats.org/presentationml/2006/main' xmlns:a='http://schemas.openxmlformats.org/drawingml/2006/main' type='blank' preserve='1'><p:cSld name='Blank'><p:spTree>$group</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>"
        WritePart $zip 'ppt/slideLayouts/_rels/slideLayout1.xml.rels' '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="master" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/></Relationships>'
        WritePart $zip 'ppt/theme/theme1.xml' @'
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="DeveloperDays Warsaw"><a:themeElements><a:clrScheme name="Warsaw"><a:dk1><a:srgbClr val="161616"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="282828"/></a:dk2><a:lt2><a:srgbClr val="CCCCCC"/></a:lt2><a:accent1><a:srgbClr val="BD0926"/></a:accent1><a:accent2><a:srgbClr val="FF6A3F"/></a:accent2><a:accent3><a:srgbClr val="DF1238"/></a:accent3><a:accent4><a:srgbClr val="B34242"/></a:accent4><a:accent5><a:srgbClr val="888888"/></a:accent5><a:accent6><a:srgbClr val="444444"/></a:accent6><a:hlink><a:srgbClr val="DF1238"/></a:hlink><a:folHlink><a:srgbClr val="FF6A3F"/></a:folHlink></a:clrScheme><a:fontScheme name="Warsaw"><a:majorFont><a:latin typeface="Raleway"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface="Open Sans"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme><a:fmtScheme name="Warsaw"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln><a:ln w="25400"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln><a:ln w="38100"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>
'@
    } finally { $zip.Dispose() }
    # Preserve an existing deck until the complete replacement has been built.
    [IO.File]::Copy($stagedOutput, $Output, $true)
    Write-Host "Saved: $Output"
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force
}
