@echo off
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for huggingface-cli on Windows.
:: Prepares and configures huggingface-cli on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript huggingface-cli installation on Windows.

set "THIS_FILE=%~f0"

where huggingface-cli >nul 2>&1
if %errorlevel% equ 0 exit /b 0

where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Installing huggingface-cli via pip...
    pip install -U "huggingface_hub[cli]" --quiet
    if not errorlevel 1 exit /b 0
)

echo Failed to install huggingface-cli.
exit /b 1
