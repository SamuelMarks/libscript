@echo off
rem ## Overview
rem Test suite for the duckdb component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion

where duckdb >nul 2>nul
if %errorlevel% neq 0 (
  if exist "%~dp0cli.cmd" (
      call "%~dp0cli.cmd" --help >nul
  )
  exit /b 0
)

duckdb -c "SELECT 1;"
