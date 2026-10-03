<#
.SYNOPSIS
    Assembles the static site from shared partials and per-page body files.

.DESCRIPTION
    Keeping the header, footer and <head> in one place means a change to the
    navigation or footer only has to be made once. Each page is a small body
    fragment in src\pages\ which this script wraps in the shared shell from
    src\partials\.

    Layout:
        src\partials\head.html      <!DOCTYPE> .. opening <body>
        src\partials\header.html    topbar + site header
        src\partials\footer.html    footer + back-to-top + scripts
        src\pages\*.html            <main> content for one page
        <page>.html                 generated output at the repo root

    Each page fragment may declare metadata with a leading comment block:
        <!--title: ... -->
        <!--description: ... -->
        <!--active: programs -->

    Re-run after editing any partial or page:
        powershell -ExecutionPolicy Bypass -File tools\build-pages.ps1
#>

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PartialDir = [System.IO.Path]::Combine($ProjectRoot, 'src', 'partials')
$PageDir = [System.IO.Path]::Combine($ProjectRoot, 'src', 'pages')

foreach ($dir in @($PartialDir, $PageDir)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
}

# Read a partial with BOM-safe, cross-version compatible encoding handling.
function Read-Text {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.File]::ReadAllText($Path)
}

$head = Read-Text ([System.IO.Path]::Combine($PartialDir, 'head.html'))
$header = Read-Text ([System.IO.Path]::Combine($PartialDir, 'header.html'))
$footer = Read-Text ([System.IO.Path]::Combine($PartialDir, 'footer.html'))

# Navigation links live here once; @@ACTIVE@@ is swapped per page so the
# current page is marked with aria-current="page".
$navLinks = @'
      <a class="nav__link@@HOME@@" href="index.html">Home</a>
      <a class="nav__link@@PROGRAMS@@" href="programs.html">Programs</a>
      <a class="nav__link@@TRAINERS@@" href="trainers.html">Coaches</a>
      <a class="nav__link@@MEMBERSHIP@@" href="membership.html">Membership</a>
      <a class="nav__link@@CONTACT@@" href="contact.html">Contact</a>
      <a class="btn btn--primary btn--sm nav__cta" href="membership.html">Join Now</a>
'@

function Set-NavActive {
    param([string]$Html, [string]$Active)

    $map = [ordered]@{
        'HOME'       = 'home'
        'PROGRAMS'   = 'programs'
        'TRAINERS'   = 'trainers'
        'MEMBERSHIP' = 'membership'
        'CONTACT'    = 'contact'
    }

    foreach ($key in $map.Keys) {
        $token = "@@$key@@"
        $replacement = if ($Active -eq $map[$key]) { ' aria-current="page"' } else { '' }
        $Html = $Html.Replace($token, $replacement)
    }
    return $Html
}

$pages = Get-ChildItem -Path $PageDir -Filter *.html | Sort-Object Name
if (-not $pages) { Write-Error "No page fragments found in $PageDir" }

Write-Host ''
Write-Host 'IRON HAVEN - building pages' -ForegroundColor Cyan

foreach ($page in $pages) {
    $raw = Read-Text $page.FullName

    # Extract the optional metadata header, then strip it from the body.
    # NOTE: this fallback title must stay ASCII - Windows PowerShell 5.1
    # decodes BOM-less .ps1 files with the system ANSI code page, so any
    # non-ASCII character (em dash, accents) can corrupt the parse.
    $title = "$($page.BaseName) - Iron Haven Strength Club"
    $description = 'Iron Haven is a premium strength and conditioning club with expert coaching, serious equipment and small classes.'
    $active = ''

    $metaBlock = [regex]::Match($raw, '(?s)\A\s*<!--\s*(?<meta>.*?)-->\s*')
    if ($metaBlock.Success) {
        $raw = $raw.Remove($metaBlock.Index, $metaBlock.Length)
        foreach ($line in ($metaBlock.Groups['meta'].Value -split "`n")) {
            if ($line -match 'title:\s*(.+)$') { $title = $Matches[1].Trim() }
            elseif ($line -match 'description:\s*(.+)$') { $description = $Matches[1].Trim() }
            elseif ($line -match 'active:\s*(.+)$') { $active = $Matches[1].Trim() }
        }
    }

    $body = $raw.Trim()

    $html = $head.
        Replace('__PAGE_TITLE__', $title).
        Replace('__PAGE_DESCRIPTION__', $description)

    $html = $html.Replace('@@NAV@@', (Set-NavActive -Html $navLinks -Active $active))
    $html = $html.Replace('@@HEADER@@', $header.Trim())
    $html = $html.Replace('@@BODY@@', $body)
    $html = $html.Replace('@@FOOTER@@', $footer.Trim())

    $outPath = [System.IO.Path]::Combine($ProjectRoot, "$($page.BaseName).html")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($outPath, $html, $utf8NoBom)

    Write-Host ('  built {0,-18} title="{1}"' -f "$($page.BaseName).html", $title) -ForegroundColor DarkGray
}

Write-Host ''
Write-Host ("Built {0} page(s) at the repo root." -f $pages.Count) -ForegroundColor Green