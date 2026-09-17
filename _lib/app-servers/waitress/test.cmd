@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Waitress WSGI server on Windows.
::
:: ## Usage
:: Execute this script to test Waitress functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
waitress-serve --help >nul 2>&1
exit /b %ERRORLEVEL%
