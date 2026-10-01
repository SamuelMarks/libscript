@echo off
set "THIS_FILE=%~f0"
:: # grub_multiboot.cmd
::
:: ## Overview
:: Windows wrapper for grub_multiboot.sh
::
:: ## Usage
:: Call grub_multiboot.cmd [output_cfg]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:show_help
echo Usage: %~nx0 [output_cfg]
exit /b 0

:main
set "SCRIPT_DIR=%~dp0"

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%grub_multiboot.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%grub_multiboot.sh" %*
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
exit /b 1
