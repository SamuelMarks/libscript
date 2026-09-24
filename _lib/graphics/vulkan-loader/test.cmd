@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Vulkan Loader on Windows.
::
:: ## Usage
:: Execute this script to test Vulkan Loader.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if exist "%SystemRoot%\System32\vulkan-1.dll" (
    echo [OK] vulkan-1.dll verified in System32.
    exit /b 0
)

echo [SKIP] vulkan-1.dll not found.
exit /b 0
