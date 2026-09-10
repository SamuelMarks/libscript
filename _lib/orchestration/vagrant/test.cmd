@echo off
rem ## Overview
rem Test suite for Vagrant component on Windows.
setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where vagrant >nul 2>&1
if !errorlevel! equ 0 (
    vagrant --version
    vagrant plugin list 2>nul
    exit /b 0
)
echo vagrant binary not found in PATH.
exit /b 1
