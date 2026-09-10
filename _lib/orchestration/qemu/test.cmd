@echo off
rem ## Overview
rem Test suite for QEMU component on Windows.
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
