@echo off
rem ## Overview
rem Test suite for the postgres component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where psql >nul 2>nul
if %errorlevel% equ 0 (
  psql --version
  exit /b 0
)

echo psql not found
exit /b 1
