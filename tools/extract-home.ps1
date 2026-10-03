<#
.SYNOPSIS
    One-off helper: splits the original hand-written index.html into
    src\pages\home.html (the <main> content) so the page can be maintained
    as a source fragment.

.NOTES
    Safe to delete once src\pages\home.html exists - the site is built from
    src\pages\* via tools\build-pages.ps1.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$src = [System.IO.Path]::Combine($root, 'index.html')

$lines = [System.IO.File]::ReadAllLines($src)

$start = [Array]::IndexOf($lines, '<main id="main">')
if ($start -lt 0) { Write-Error 'Could not find <main id="main">' }

# Walk forward to the matching </main> at column 0.
$end = -1
for ($i = $start + 1; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -eq '</main>') { $end = $i; break }
}
if ($end -lt 0) { Write-Error 'Could not find closing </main>' }

$body = $lines[($start + 1)..($end - 1)]

$header = @"
<!--
title: Iron Haven &mdash; Premium Strength &amp; Conditioning Club
description: Iron Haven is a premium strength and conditioning club. Expert coaches, elite equipment and small classes built for people serious about getting stronger.
active: home
-->

"@

$out = [System.IO.Path]::Combine($root, 'src', 'pages', 'home.html')
if (-not (Test-Path ([System.IO.Path]::GetDirectoryName($out)))) {
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($out)) | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($out, ($header + ($body -join "`n")), $utf8NoBom)

Write-Host ("Extracted {0} body lines (source {1}..{2}) -> src\pages\home.html" -f $body.Count, ($start + 2), $end) -ForegroundColor Green