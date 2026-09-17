@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies nodeenv execution on Windows.
::
:: ## Usage
:: Execute this script to test nodeenv functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
nodeenv --version
exit /b %ERRORLEVEL%
