@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Gunicorn on Windows.
::
:: ## Usage
:: Execute this script to test Gunicorn functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
gunicorn --version
exit /b %ERRORLEVEL%
