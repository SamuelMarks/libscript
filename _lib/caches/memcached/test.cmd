@echo off
:: # test.cmd
::
:: ## Overview
:: Test suite for the memcached component.
::
:: ## Usage
:: Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if exist "%~dp0env.cmd" (
    call "%~dp0env.cmd"
)

where memcached >nul 2>nul
if %errorlevel% equ 0 (
  memcached -V
  exit /b 0
)

if exist "%~dp0cli.cmd" (
    call "%~dp0cli.cmd" --help >nul
)
exit /b 0
