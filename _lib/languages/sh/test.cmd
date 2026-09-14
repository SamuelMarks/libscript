@echo off
rem ## Overview
rem Test suite for the sh component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%USERPROFILE%\.local\bin" (
    set "PATH=%USERPROFILE%\.local\bin;!PATH!"
)

if exist "%ProgramFiles%\Git\bin\sh.exe" (
    "%ProgramFiles%\Git\bin\sh.exe" --version
    exit /b 0
)

where sh >nul 2>&1
if %errorlevel% equ 0 (
    sh -c "echo sh operational"
    exit /b 0
)

where busybox >nul 2>&1
if %errorlevel% equ 0 (
    busybox sh -c "echo sh operational"
    exit /b 0
)

echo sh not available
exit /b 1
