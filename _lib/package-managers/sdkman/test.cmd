@echo off
rem ## Overview
rem Test suite for the sdkman component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

echo sdkman is only natively supported on POSIX systems.
exit /b 0
