@echo off
chcp 65001 >nul 2>&1
title Antigravity Auto-Accept Setup
color 0A

echo.
echo  ============================================
echo   Antigravity Auto-Accept - Setup
echo   CDP Port 9000 Configuration
echo  ============================================
echo.

:: ── 1. argv.json CDP port auto-config ──
set "AG_DIR=%USERPROFILE%\.antigravity"
set "ARGV_JSON=%AG_DIR%\argv.json"

if not exist "%AG_DIR%" (
    mkdir "%AG_DIR%"
    echo [SETUP] Created %AG_DIR%
)

findstr /C:"remote-debugging-port" "%ARGV_JSON%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [SETUP] Patching argv.json with remote-debugging-port=9000...
    powershell -NoProfile -Command ^
        "$f='%ARGV_JSON%';" ^
        "if(Test-Path $f){" ^
        "  $c=Get-Content $f -Raw -Encoding UTF8;" ^
        "  if($c -match '\}'){" ^
        "    $c=$c.TrimEnd() -replace '\}\s*$',',' + '\"remote-debugging-port\": 9000}';" ^
        "  }" ^
        "  [IO.File]::WriteAllText($f,$c,[Text.Encoding]::UTF8)" ^
        "}else{" ^
        "  [IO.File]::WriteAllText($f,'{\"remote-debugging-port\": 9000}',[Text.Encoding]::UTF8)" ^
        "}"
    echo [SETUP] OK - argv.json patched
) else (
    echo [SETUP] OK - CDP port 9000 already in argv.json
)

:: ── 2. Patch all Antigravity shortcuts (.lnk) ──
echo.
echo [SETUP] Scanning Antigravity shortcuts...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch_shortcuts.ps1"

echo.
echo [SETUP] Done. Restart Antigravity for changes to take effect.
echo.
