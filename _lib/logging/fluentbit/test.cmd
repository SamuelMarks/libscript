@echo off
rem ## Overview
rem Test suite for the fluentbit component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where fluent-bit >nul 2>nul
if %errorlevel% neq 0 (
  if exist "%~dp0cli.cmd" (
      call "%~dp0cli.cmd" --help >nul
  )
  exit /b 0
)

fluent-bit --version
