@echo off
rem ## Overview
rem Test suite for Packer component on Windows.
setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where packer >nul 2>&1
if !errorlevel! equ 0 (
    packer --version
    exit /b 0
)
echo packer binary not found in PATH.
exit /b 1
