@echo off
rem ## Overview
rem Test suite for the ollama component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where ollama >nul 2>nul
if %errorlevel% equ 0 (
  ollama --version
  exit /b 0
)

if exist "%~dp0cli.cmd" (
    call "%~dp0cli.cmd" --help >nul
)
exit /b 0
