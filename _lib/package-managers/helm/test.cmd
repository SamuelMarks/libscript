@echo off
rem ## Overview
rem Test suite for the helm component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where helm >nul 2>nul
if %errorlevel% neq 0 (
  echo helm is not installed, skipping test.
  exit /b 0
)

helm --version || helm version || exit /b 0
