@echo off
rem ## Overview
rem Test suite for the emerge component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where emerge >nul 2>nul
if %errorlevel% neq 0 (
  echo emerge is not installed, skipping test.
  exit /b 0
)

emerge --version
