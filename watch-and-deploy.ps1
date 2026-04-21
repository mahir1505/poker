$ErrorActionPreference = "Stop"
$repo = "c:\Projects\vo\poker"
Set-Location $repo

$watcher = New-Object System.IO.FileSystemWatcher $repo, "index.html"
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

$script:pending = $false

$action = {
    if ($script:pending) { return }
    $script:pending = $true
    Start-Sleep -Milliseconds 800
    $script:pending = $false

    Set-Location "c:\Projects\vo\poker"
    git add index.html | Out-Null
    $changed = git diff --cached --name-only
    if (-not $changed) { return }

    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    git commit -m "Auto-update $stamp" | Out-Null
    git push origin main 2>&1 | Tee-Object -FilePath "watch-and-deploy.log" -Append
    Write-Host "[$stamp] pushed" -ForegroundColor Green
}

Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null
Register-ObjectEvent $watcher "Created" -Action $action | Out-Null

Write-Host "Watching $repo\index.html - druk Ctrl+C om te stoppen"
while ($true) { Start-Sleep -Seconds 5 }
