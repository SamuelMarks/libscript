@echo off
rem ## Overview
rem Test suite for the go-pm component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where go >nul 2>nul
if %errorlevel% neq 0 (
  echo go is not installed, skipping test.
  exit /b 0
)

go --version
