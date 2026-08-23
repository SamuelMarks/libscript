@echo off
rem ## Overview
rem Test suite for the dnf component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where dnf >nul 2>nul
if %errorlevel% neq 0 (
  echo dnf is not installed, skipping test.
  exit /b 0
)

dnf --version
