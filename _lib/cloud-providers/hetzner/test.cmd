@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Hetzner CLI on Windows.
::
:: ## Usage
:: Execute this script to test Hetzner functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where hcloud >nul 2>&1
if %errorlevel% equ 0 (
    hcloud version
    exit /b 0
)

echo [SKIP] hcloud CLI not found on PATH.
exit /b 0
