@echo off
rem ## Overview
rem Test suite for the krew component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where kubectl-krew >nul 2>nul
if %errorlevel% neq 0 (
  echo kubectl-krew is not installed, skipping test.
  exit /b 0
)

kubectl-krew --version || kubectl-krew version || exit /b 0
