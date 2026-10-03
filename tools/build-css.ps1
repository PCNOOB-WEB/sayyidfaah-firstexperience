<#
.SYNOPSIS
    Concatenates the CSS partials in assets\css into a single assets\css\main.css.

.DESCRIPTION
    The stylesheets are authored as numbered partials so they stay readable and
    easy to review. Browsers would otherwise need one request per partial, so
    this script flattens them, in load order, into main.css - which is what the
    HTML actually links to.

    Re-run after editing any partial:
        powershell -ExecutionPolicy Bypass -File tools\build-css.ps1

.NOTES
    main.css is generated - edit the partials, never the bundle.
#>

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CssDir = [System.IO.Path]::Combine($ProjectRoot, 'assets', 'css')
$Bundle = [System.IO.Path]::Combine($CssDir, 'main.css')

# Load order matters: tokens -> utilities -> layout -> components -> pages.
$Partials = @(
    'tokens.css'
    'utilities.css'
    'header.css'
    'footer.css'
    'components.css'
    'elements.css'
    'elements2.css'
    'forms.css'
    'hero.css'
    'pages.css'
    'pages2.css'
)

$missing = $Partials | Where-Object { -not (Test-Path (Join-Path $CssDir $_)) }
if ($missing) {
    Write-Error ("Missing CSS partial(s): {0}" -f ($missing -join ', '))
}

$builder = New-Object System.Text.StringBuilder
[void]$builder.AppendLine('/*!')
[void]$builder.AppendLine(' * IRON HAVEN - main.css')
[void]$builder.AppendLine(' * GENERATED FILE. Do not edit directly.')
[void]$builder.AppendLine(' * Source partials live in assets/css/*.css')
[void]$builder.AppendLine(' * Rebuild:  powershell -ExecutionPolicy Bypass -File tools\build-css.ps1')
[void]$builder.AppendLine(' */')
[void]$builder.AppendLine()

foreach ($partial in $Partials) {
    $path = Join-Path $CssDir $partial
    [void]$builder.AppendLine('/* ===== {0} ===== */' -f $partial)
    [void]$builder.AppendLine((Get-Content -LiteralPath $path -Raw).TrimEnd())
    [void]$builder.AppendLine()
    Write-Host ('  bundled {0}' -f $partial)
}

# Write as UTF-8 without BOM so the file stays byte-clean.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Bundle, $builder.ToString(), $utf8NoBom)

$sizeKb = [math]::Round((Get-Item -LiteralPath $Bundle).Length / 1KB, 1)
Write-Host ''
Write-Host ('Bundled {0} partials -> assets\css\main.css ({1} KB)' -f $Partials.Count, $sizeKb) -ForegroundColor Green