# Controleert dat de gespiegelde VO-regio's identiek zijn in alle drie de SPA's.
# MIRRORED-CODE.md schrijft voor dat design tokens en gedeelde chrome hand in hand
# gaan; dit script maakt die afspraak controleerbaar in plaats van hoopvol.
#
# - stats.html staat in .gitignore en ontbreekt op een schone clone -> Test-Path.
# - index.html gebruikt CRLF, retro/stats LF. Dat is bestaand en niet de moeite van
#   een repo-brede normalisatie waard, dus vergelijken we regeleindes-neutraal.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$regions = @('VO THEME BOOT', 'VO THEME', 'VO CHROME')
$files = @('index.html', 'retro.html', 'stats.html') | Where-Object { Test-Path $_ }
$failed = $false

foreach ($region in $regions) {
    $pattern = "(?s)$region START.*?$region END"
    $blocks = @()
    foreach ($f in $files) {
        $m = [regex]::Match((Get-Content $f -Raw -Encoding UTF8), $pattern)
        if (-not $m.Success) {
            Write-Host "ONTBREEKT: regio '$region' niet gevonden in $f" -ForegroundColor Red
            $failed = $true
            continue
        }
        $blocks += ($m.Value -replace "`r`n", "`n")
    }
    if ($blocks.Count -ne $files.Count) { continue }
    if (($blocks | Select-Object -Unique).Count -ne 1) {
        Write-Host "DRIFT in regio '$region' over: $($files -join ', ')" -ForegroundColor Red
        $failed = $true
    } else {
        Write-Host "OK: '$region' identiek in $($files.Count) bestand(en)" -ForegroundColor Green
    }
}

if ($failed) { exit 1 }
Write-Host "Alle gespiegelde regio's zijn in sync." -ForegroundColor Green
