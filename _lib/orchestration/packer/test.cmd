@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite script for HashiCorp Packer on Windows.
::
:: ## Usage
:: Call this script to verify Packer functionality on Windows.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where packer >nul 2>&1
if !errorlevel! equ 0 (
    packer --version
    exit /b 0
)
echo packer binary not found in PATH.
exit /b 1
