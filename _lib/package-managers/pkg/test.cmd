@echo off
rem ## Overview
rem Test suite for the pkg component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

echo pkg is only available on FreeBSD. Skipping test.
exit /b 0
