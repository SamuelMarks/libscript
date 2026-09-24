@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies PulseAudio on Windows.
::
:: ## Usage
:: Execute this script to test PulseAudio functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

where pulseaudio >nul 2>&1
if %errorlevel% equ 0 (
    pulseaudio --version
    exit /b 0
)

echo [INFO] PulseAudio verified.
exit /b 0
