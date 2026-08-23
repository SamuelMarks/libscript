@echo off
rem ## Overview
rem Test suite for the gem component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where gem >nul 2>nul
if %errorlevel% neq 0 (
  echo gem is not installed, skipping test.
  exit /b 0
)

gem --version
