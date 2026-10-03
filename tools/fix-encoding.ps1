<#
.SYNOPSIS
    Strips non-ASCII characters from the PowerShell scripts in tools\.

.DESCRIPTION
    Windows PowerShell 5.1 (the default powershell.exe on Windows 10/11)
    decodes BOM-less .ps1 files using the system ANSI code page rather than
    UTF-8. A single em dash or accented letter written as UTF-8 is therefore
    read as garbage and can break the parse with a confusing
    "string is missing the terminator" error.

    The reliable fix is to keep these scripts pure ASCII: all user-facing text
    they emit uses HTML entities (e.g. &mdash;) instead of literal characters.

    Run this after editing a script in an editor that strips or rewrites the BOM:
        powershell -ExecutionPolicy Bypass -File tools\fix-encoding.ps1
#>

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$toolsDir = [System.IO.Path]::Combine($ProjectRoot, 'tools')

$scripts = Get-ChildItem -Path $toolsDir -Filter *.ps1
if (-not $scripts) { Write-Error "No .ps1 scripts found in $toolsDir" }

# Replacement map for the few characters the scripts used.
# Values are [string] so that multi-character replacements (e.g. the
# ellipsis) bind to the string overload of String.Replace rather than
# the char overload.
$map = @{
    ([char]0x2014) = [string]'-'     # em dash
    ([char]0x2013) = [string]'-'     # en dash
    ([char]0x2018) = [string]"'"     # left single quote
    ([char]0x2019) = [string]"'"     # right single quote
    ([char]0x201C) = [string]'"'     # left double quote
    ([char]0x201D) = [string]'"'     # right double quote
    ([char]0x2026) = [string]'...'   # ellipsis
    ([char]0x00A0) = [string]' '     # non-breaking space
}

$changed = 0
foreach ($script in $scripts) {
    # Read as UTF-8 so existing correct characters are understood...
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $text = [System.IO.File]::ReadAllText($script.FullName, $utf8)
    $original = $text

    foreach ($k in $map.Keys) {
        $text = $text.Replace([string]$k, [string]$map[$k])
    }

    # ...then drop anything else non-ASCII that slipped in, so the file is
    # guaranteed to parse regardless of the active code page.
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $text.ToCharArray()) {
        if ([int]$ch -lt 128) { [void]$sb.Append($ch) } else { [void]$sb.Append('?') }
    }
    $text = $sb.ToString()

    if ($text -ne $original) {
        # Written WITHOUT a BOM on purpose: the file is pure ASCII now, so it
        # decodes identically under any code page.
        [System.IO.File]::WriteAllText($script.FullName, $text, $utf8)
        Write-Host ('  cleaned {0}' -f $script.Name) -ForegroundColor Yellow
        $changed++
    }
}

Write-Host ''
if ($changed -gt 0) {
    Write-Host ("Cleaned {0} script(s) to pure ASCII." -f $changed) -ForegroundColor Green
} else {
    Write-Host 'All scripts are already pure ASCII.' -ForegroundColor Green
}