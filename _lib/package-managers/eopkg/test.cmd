@echo off
rem ## Overview
rem Test suite for the eopkg component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where eopkg >nul 2>nul
if %errorlevel% neq 0 (
  echo eopkg is not installed, skipping test.
  exit /b 0
)

eopkg --version
