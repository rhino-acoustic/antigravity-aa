# patch_shortcuts.ps1 - Antigravity .lnk shortcut CDP flag patcher
# Finds all Antigravity shortcuts and adds --remote-debugging-port=9000

$cdpFlag = "--remote-debugging-port=9000"
$shell = New-Object -ComObject WScript.Shell

$searchDirs = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\OneDrive\Desktop",
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs",
    "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
)

$patched = 0
$skipped = 0
$found = 0

foreach ($dir in $searchDirs) {
    if (-not (Test-Path $dir)) { continue }

    Get-ChildItem -Path $dir -Filter "*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $lnk = $_.FullName
        $name = $_.Name

        # Only process Antigravity shortcuts
        if ($name -notmatch "(?i)antigravity") { return }

        $found++
        $shortcut = $shell.CreateShortcut($lnk)

        # Check if target is Antigravity.exe
        if ($shortcut.TargetPath -notmatch "(?i)antigravity") {
            return
        }

        $args = $shortcut.Arguments
        if ($args -match "remote-debugging-port") {
            Write-Host "[SKIP] $name - already has CDP flag" -ForegroundColor DarkGray
            $skipped++
            return
        }

        # Add CDP flag to arguments
        $shortcut.Arguments = ($args + " $cdpFlag").Trim()
        $shortcut.Save()

        Write-Host "[PATCH] $name" -ForegroundColor Green
        Write-Host "        Target: $($shortcut.TargetPath)" -ForegroundColor DarkGray
        Write-Host "        Args:   $($shortcut.Arguments)" -ForegroundColor DarkGray
        $patched++
    }
}

# Summary
Write-Host ""
if ($found -eq 0) {
    Write-Host "[WARN] No Antigravity shortcuts found." -ForegroundColor Yellow
    Write-Host "       If you use Antigravity, create a shortcut first, then run setup again." -ForegroundColor Yellow
} else {
    Write-Host "[DONE] Shortcuts: $found found, $patched patched, $skipped already configured" -ForegroundColor Cyan
}

if ($patched -gt 0) {
    Write-Host ""
    Write-Host "[!] Restart Antigravity for CDP to take effect." -ForegroundColor Yellow
}
