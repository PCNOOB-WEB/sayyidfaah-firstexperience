<#
.SYNOPSIS
    Generates the branded SVG mockup artwork used across the IRON HAVEN website.

.DESCRIPTION
    The site ships without photography, so every image slot is filled with a
    generated "mockup": a stylised vector scene (figure silhouette + equipment +
    gradient backdrop + grid) rendered in the brand palette.

    Re-run after tweaking brand colours:
        powershell -ExecutionPolicy Bypass -File tools\generate-mockups.ps1

.NOTES
    To swap in real photography later, just replace the .svg files in
    assets\img with .jpg/.webp images of the same name and update the
    `src` attributes. The CSS uses object-fit: cover, so aspect ratios
    are handled automatically.
#>

$ErrorActionPreference = 'Stop'

# Join-Path only accepts two positional args in Windows PowerShell 5.1,
# so the path is composed explicitly for cross-version compatibility.
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ImgDir = [System.IO.Path]::Combine($ProjectRoot, 'assets', 'img')
if (-not (Test-Path $ImgDir)) { New-Item -ItemType Directory -Force -Path $ImgDir | Out-Null }

# ---------------------------------------------------------------- palette ---
$Ink      = '#f4f4f6'
$Ink3     = '#7e808d'
$Bg       = '#0d0d13'
$Accent   = '#ff5b2e'
$Lime     = '#d8ff3d'

# ------------------------------------------------------------- svg helpers ---

function New-Mockup {
    <#
    .SYNOPSIS
        Builds one mockup SVG file.
    .PARAMETER Name
        Output file name without extension.
    .PARAMETER W
        Viewbox width.
    .PARAMETER H
        Viewbox height.
    .PARAMETER Title
        Large display text rendered in the scene.
    .PARAMETER Sub
        Small caption under the title.
    .PARAMETER Scene
        Pre-built SVG markup drawn on top of the backdrop.
    .PARAMETER C1 / C2
        Gradient stops for the backdrop.
    .PARAMETER Grid
        Switch to render the technical grid overlay.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [int]$W = 1200,
        [int]$H = 900,
        [string]$Title = '',
        [string]$Sub = '',
        [string]$Scene = '',
        [string]$C1 = '#ff7a3d',
        [string]$C2 = '#e01f00',
        [switch]$Grid,
        [string]$Tone = 'dark'
    )

    $uid = ($Name -replace '[^a-zA-Z0-9]', '')

    $template = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 __W__ __H__" width="__W__" height="__H__" role="img" aria-label="__ARIALABEL__" preserveAspectRatio="xMidYMid slice">
  <defs>
    <linearGradient id="bg__UID__" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="__C1__" stop-opacity="0.55"/>
      <stop offset="55%" stop-color="__C2__" stop-opacity="0.22"/>
      <stop offset="100%" stop-color="__BG__" stop-opacity="1"/>
    </linearGradient>
    <radialGradient id="vig__UID__" cx="50%" cy="42%" r="72%">
      <stop offset="55%" stop-color="#000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000" stop-opacity="0.72"/>
    </radialGradient>
    <linearGradient id="fade__UID__" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#000" stop-opacity="0"/>
      <stop offset="100%" stop-color="#000" stop-opacity="0.85"/>
    </linearGradient>
    <pattern id="grid__UID__" width="64" height="64" patternUnits="userSpaceOnUse">
      <path d="M64 0H0V64" fill="none" stroke="#ffffff" stroke-opacity="0.07" stroke-width="1"/>
    </pattern>
  </defs>

  <rect width="__W__" height="__H__" fill="__BG__"/>
  <rect width="__W__" height="__H__" fill="url(#bg__UID__)"/>
  <g>__GRIDMARK__</g>
  <g>__SCENE__</g>
  <rect width="__W__" height="__H__" fill="url(#vig__UID__)"/>
  <g transform="translate(__PADX__ __PADY__)">
    <text x="0" y="0" fill="__INK__" font-family="Anton, Impact, sans-serif" font-size="__TFS__" letter-spacing="2">__TITLE__</text>
    <text x="2" y="__TSUBY__" fill="__INK3__" font-family="Inter, Segoe UI, Arial, sans-serif" font-size="22" font-weight="700" letter-spacing="6">__SUB__</text>
  </g>
  <rect y="__H__" width="__W__" height="40%" fill="url(#fade__UID__)"/>
</svg>
'@

    $titleFs = if ($H -le 700) { 66 } elseif ($W -ge 1000) { 84 } else { 60 }
    $padX = [int]($W * 0.07)
    $padY = [int]($H * 0.80)
    $subY = 44
    # NOTE: the grid overlay is interpolated with $uid directly rather than
    # the __UID__ token, because these fragments are inserted into the template
    # *after* the token substitution pass has already run.
    $gridMark = if ($Grid) { "<rect width=""$W"" height=""$H__"" fill=""url(#grid$uid)""/>" } else { '' }
    $sceneBlock = if ([string]::IsNullOrWhiteSpace($Scene)) { '' } else { "<g transform=""translate($([int]($W * 0.5)) $([int]($H * 0.46)))"">$Scene</g>" }
    $aria = if ($Title) { "$Title mockup" } else { "Iron Haven gym mockup" }

    $svg = $template.
        Replace('__GRIDMARK__', $gridMark).Replace('__SCENE__', $sceneBlock).
        Replace('__W__', $W).Replace('__H__', $H).Replace('__UID__', $uid).
        Replace('__C1__', $C1).Replace('__C2__', $C2).Replace('__BG__', $Bg).
        Replace('__INK__', $Ink).Replace('__INK3__', $Ink3).
        Replace('__TFS__', $titleFs).Replace('__TSUBY__', $subY).
        Replace('__PADX__', $padX).Replace('__PADY__', $padY).
        Replace('__TITLE__', $Title).Replace('__SUB__', $Sub.ToUpperInvariant()).
        Replace('__ARIALABEL__', $aria)

    $path = Join-Path $ImgDir "$Name.svg"
    Set-Content -LiteralPath $path -Value $svg -Encoding UTF8
    Write-Host ("  [ok] {0,-26} {1}x{2}" -f "$Name.svg", $W, $H)
}

# ------------------------------------------------------------- scene props --
# All scenes are authored in a local coordinate space of roughly -300..300 on
# both axes and are auto-centred by New-Mockup.

function Get-Barbell {
    param([string]$Color = $Accent, [double]$Scale = 1)
    $g = @"
<g transform="scale($Scale)" fill="none" stroke="$Color" stroke-width="18" stroke-linecap="round">
  <path d="M-150 0 H150"/>
  <path d="M-108 -46 V46 M-90 -34 V34"/>
  <path d="M108 -46 V46 M90 -34 V34"/>
</g>
"@
    return $g
}

function Get-Figure {
    <#
    .SYNOPSIS
        Stylised athlete silhouette in one of five poses.
    .PARAMETER Pose
        squat | deadlift | press | lunge | rest
    #>
    param([string]$Pose = 'squat', [string]$Color = $Ink, [string]$Opacity = '0.92')

    $body = switch ($Pose) {
        'squat' {
            @"
<circle cx="0" cy="-150" r="26" fill="$Color"/>
<path d="M0 -120 V0" stroke="$Color" stroke-width="52" stroke-linecap="round" fill="none"/>
<path d="M0 -108 L-78 -30" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 -108 L78 -30" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 0 L-62 96" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
<path d="M0 0 L62 96" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
"@
        }
        'deadlift' {
            @"
<circle cx="0" cy="-118" r="26" fill="$Color"/>
<path d="M0 -88 L0 44" stroke="$Color" stroke-width="52" stroke-linecap="round" fill="none"/>
<path d="M0 -70 L-84 44" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 -70 L84 44" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 44 L-46 128" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
<path d="M0 44 L46 128" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
"@
        }
        'press' {
            @"
<circle cx="0" cy="-158" r="26" fill="$Color"/>
<path d="M0 -126 V10" stroke="$Color" stroke-width="52" stroke-linecap="round" fill="none"/>
<path d="M0 -116 L-88 -172" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 -116 L88 -172" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 10 L-46 108" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
<path d="M0 10 L46 108" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
"@
        }
        'lunge' {
            @"
<circle cx="-18" cy="-150" r="26" fill="$Color"/>
<path d="M-18 -118 V0" stroke="$Color" stroke-width="52" stroke-linecap="round" fill="none"/>
<path d="M-18 -108 L64 -30" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M-18 -108 L-96 -20" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M-18 0 L54 96" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
<path d="M-18 0 L-70 92" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
"@
        }
        default {
            @"
<circle cx="0" cy="-150" r="26" fill="$Color"/>
<path d="M0 -118 V0" stroke="$Color" stroke-width="52" stroke-linecap="round" fill="none"/>
<path d="M0 -108 L-78 -14" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 -108 L78 -14" stroke="$Color" stroke-width="26" stroke-linecap="round" fill="none"/>
<path d="M0 0 L-40 100" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
<path d="M0 0 L40 100" stroke="$Color" stroke-width="30" stroke-linecap="round" fill="none"/>
"@
        }
    }

    return "<g opacity=""$Opacity"">$body</g>"
}

function Get-Floor {
    param([string]$Color = $Lime)
    return @"
<g opacity="0.5" fill="none" stroke="$Color" stroke-width="3">
  <ellipse cx="0" cy="140" rx="210" ry="20" stroke-opacity="0.35"/>
  <ellipse cx="0" cy="140" rx="140" ry="13" stroke-opacity="0.22"/>
</g>
<g opacity="0.35" fill="$Color">
  <circle cx="0" cy="-270" r="4"/>
  <circle cx="-40" cy="-250" r="3"/>
  <circle cx="42" cy="-258" r="3"/>
</g>
"@
}

# --------------------------------------------------------------- the build ---

Write-Host ''
Write-Host 'IRON HAVEN - generating mockup artwork' -ForegroundColor Cyan
Write-Host ("Output: {0}" -f $ImgDir)
Write-Host ''

# --- Home / hero ---------------------------------------------------------
New-Mockup -Name 'hero-main' -W 1100 -H 1250 -Title 'FORGE' -Sub 'Strength club' `
    -Scene ((Get-Floor) + (Get-Figure -Pose 'squat') + (Get-Barbell -Scale 0.85) `
        + "<g transform=""translate(0 30)""><rect x=""-170"" y=""-6"" width=""340"" height=""12"" rx=""6"" fill=""$Lime"" opacity=""0.85""/></g>") `
    -C1 '#ff9a5c' -C2 '#c81c00' -Grid

New-Mockup -Name 'hero-side' -W 900 -H 700 -Title '' -Sub 'Engine room' `
    -Scene ((Get-Floor) + (Get-Figure -Pose 'deadlift') + "<g transform=""translate(0 60)"">$(Get-Barbell -Color $Lime -Scale 0.7)</g>") `
    -C1 '#ff7a3d' -C2 '#7a1200' -Grid

# --- About / philosophy --------------------------------------------------
New-Mockup -Name 'about-floor' -W 1000 -H 1150 -Title 'THE FLOOR' -Sub 'Since 2009' `
    -Scene ((Get-Floor) + (Get-Figure -Pose 'press') + "<g transform=""translate(0 -30)"">$(Get-Barbell -Color $Ink -Scale 0.62)</g>") `
    -C1 '#ffb37a' -C2 '#a31500' -Grid

New-Mockup -Name 'facility' -W 1400 -H 900 -Title '12,000 SQ FT' -Sub 'Of pure iron' `
    -Scene @"
<g opacity="0.9">
  $(Get-Figure -Pose 'lunge' -Color $Ink)
  <g transform="translate(-250 0) scale(0.55)" opacity="0.6">$(Get-Barbell -Color $Lime -Scale 0.8)</g>
  <g transform="translate(250 0) scale(0.55)" opacity="0.6">$(Get-Barbell -Color $Lime -Scale 0.8)</g>
</g>
<g opacity="0.45" fill="none" stroke="$Ink3" stroke-width="4">
  <rect x="-460" y="-230" width="920" height="400" rx="18"/>
  <path d="M-320 -230 V170 M-160 -230 V170 M0 -230 V170 M160 -230 V170 M320 -230 V170"/>
</g>
$(Get-Floor)
"@ -C1 '#ff8c4f' -C2 '#1a1005' -Grid

# --- Programs ------------------------------------------------------------
$programs = @(
    @{ n = 'program-strength';  p = 'deadlift'; c = '#ff7a3d'; t = 'STRENGTH';   s = 'Barbell fundamentals' },
    @{ n = 'program-hiit';      p = 'lunge';    c = '#ffb37a'; t = 'HIIT';       s = 'Conditioning' },
    @{ n = 'program-hypertrophy'; p = 'squat';  c = '#e01f00'; t = 'HYPERTROPHY'; s = 'Hypertrophy' },
    @{ n = 'program-mobility';  p = 'rest';     c = '#d8ff3d'; t = 'MOBILITY';   s = 'Recovery' }
)
foreach ($pr in $programs) {
    $figure = Get-Figure -Pose $pr.p -Color $Ink
    $bar = if ($pr.t -eq 'MOBILITY') { '' } else { "<g transform=""translate(0 25)"">$(Get-Barbell -Color $Lime -Scale 0.66)</g>" }
    New-Mockup -Name $pr.n -W 900 -H 680 -Title $pr.t -Sub $pr.s `
        -Scene ((Get-Floor -Color $pr.c) + $figure + $bar) -C1 $pr.c -C2 '#120800' -Grid
}

# --- Trainers ------------------------------------------------------------
$trainers = @(
    @{ n = 'coach-marcus'; p = 'squat';    c = '#ff7a3d'; t = 'MARCUS';  s = 'Head coach' },
    @{ n = 'coach-aisha';  p = 'deadlift'; c = '#d8ff3d'; t = 'AISHA';   s = 'Powerlifting' },
    @{ n = 'coach-diego';  p = 'lunge';    c = '#ffb37a'; t = 'DIEGO';   s = 'Conditioning' },
    @{ n = 'coach-elena';  p = 'press';    c = '#e01f00'; t = 'ELENA';   s = 'Mobility' }
)
foreach ($tr in $trainers) {
    $bar = "<g transform=""translate(0 30)"">$(Get-Barbell -Color $tr.c -Scale 0.6)</g>"
    New-Mockup -Name $tr.n -W 760 -H 950 -Title '' -Sub $tr.s `
        -Scene ((Get-Floor -Color $tr.c) + (Get-Figure -Pose $tr.p -Color $Ink) + $bar) `
        -C1 $tr.c -C2 '#0f0a06' -Grid
}

# --- Misc ----------------------------------------------------------------
New-Mockup -Name 'cta-banner' -W 1600 -H 700 -Title '' -Sub '' `
    -Scene ((Get-Floor) + (Get-Figure -Pose 'press' -Color $Ink) + "<g transform=""translate(0 -34)"">$(Get-Barbell -Scale 0.6)</g>") `
    -C1 '#ff5b2e' -C2 '#3d0d00'

New-Mockup -Name 'class-live' -W 900 -H 600 -Title '' -Sub 'Class in session' `
    -Scene @"
<g opacity="0.85">
  <g transform="translate(-150 0) scale(0.7)">$(Get-Figure -Pose 'lunge' -Color $Ink)</g>
  <g transform="translate(150 0) scale(0.7)">$(Get-Figure -Pose 'deadlift' -Color $Ink)</g>
</g>
<g transform="translate(0 40)" opacity="0.8">$(Get-Barbell -Color $Lime -Scale 0.9)</g>
$(Get-Floor)
"@ -C1 '#ff7a3d' -C2 '#120800' -Grid

Write-Host ''
Write-Host ("Done. {0} mockup(s) written to assets\img" -f (Get-ChildItem -Path $ImgDir -Filter *.svg).Count) -ForegroundColor Green