@echo off
chcp 65001 >nul 2>&1
title Antigravity Auto-Accept
color 0D

echo.
echo  ============================================
echo   Antigravity Auto-Accept
echo   Setup + Auto-Click (CDP:9000)
echo  ============================================
echo.

:: Step 1: Setup CDP port
call "%~dp0setup.bat"

:: Step 2: Run auto-accept loop
echo [AA] Starting auto-accept loop...
echo [AA] Press Ctrl+C to stop
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0aa.ps1"

echo.
echo [AA] Stopped.
pause
