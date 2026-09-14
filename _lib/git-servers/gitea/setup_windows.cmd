@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for gitea on Windows.
:: Prepares and configures gitea on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript gitea installation on Windows.

set "THIS_FILE=%~f0"

where gitea >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where tea >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing Gitea CLI via winget...
winget install --id Gitea.tea --silent --accept-package-agreements --accept-source-agreements
if not errorlevel 1 exit /b 0

echo Gitea wrapper configured.
exit /b 0
