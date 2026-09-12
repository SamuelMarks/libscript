@echo off
rem ## Overview
rem Test suite for the valkey component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where valkey-server >nul 2>nul
if %errorlevel% equ 0 (
  valkey-server --version
  exit /b 0
)

where valkey >nul 2>nul
if %errorlevel% equ 0 (
  valkey --version
  exit /b 0
)

if exist "%~dp0cli.cmd" (
    call "%~dp0cli.cmd" --help >nul
)
exit /b 0
