@echo off
rem ## Overview
rem Test suite for the julia component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where julia >nul 2>nul
if %errorlevel% neq 0 (
  echo julia is not installed, skipping test.
  exit /b 0
)

julia --version || julia version || exit /b 0
