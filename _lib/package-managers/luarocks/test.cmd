@echo off
rem ## Overview
rem Test suite for the luarocks component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where luarocks >nul 2>nul
if %errorlevel% neq 0 (
  echo luarocks is not installed, skipping test.
  exit /b 0
)

luarocks --version || luarocks version || exit /b 0
