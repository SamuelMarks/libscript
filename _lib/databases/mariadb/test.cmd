@echo off
rem ## Overview
rem Test suite for the mariadb component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

where mariadb >nul 2>nul
if %errorlevel% equ 0 (
  mariadb --version
  exit /b 0
)

where mysql >nul 2>nul
if %errorlevel% equ 0 (
  mysql --version
  exit /b 0
)

echo Neither mariadb nor mysql is available.
exit /b 1
