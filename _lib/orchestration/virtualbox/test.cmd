@echo off
rem ## Overview
rem Test suite for VirtualBox component on Windows.
setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where VBoxManage >nul 2>&1
if !errorlevel! equ 0 (
    VBoxManage --version
    VBoxManage list extpacks 2>nul
    exit /b 0
)
echo VBoxManage not found in PATH.
exit /b 1
