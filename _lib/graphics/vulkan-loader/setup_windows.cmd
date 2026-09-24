@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Windows setup script for Vulkan Loader.
:: Verifies presence of vulkan-1.dll or installs the Vulkan Runtime.
::
:: ## Usage
:: Automatically invoked during libscript vulkan-loader installation on Windows.

set "THIS_FILE=%~f0"

if exist "%SystemRoot%\System32\vulkan-1.dll" exit /b 0

echo Installing Vulkan Runtime via winget...
winget install --id KhronosGroup.Vulkan.Runtime --silent --accept-package-agreements --accept-source-agreements >nul 2>&1

exit /b 0
