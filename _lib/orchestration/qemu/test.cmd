@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite script for QEMU on Windows.
::
:: ## Usage
:: Call this script to verify QEMU functionality on Windows.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where qemu-system-x86_64 >nul 2>&1
if !errorlevel! equ 0 (
    qemu-system-x86_64 --version
    exit /b 0
)
where qemu-img >nul 2>&1
if !errorlevel! equ 0 (
    qemu-img --version
    exit /b 0
)
echo QEMU binary not found in PATH.
exit /b 1
