@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Uvicorn on Windows.
::
:: ## Usage
:: Execute this script to test Uvicorn functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
uvicorn --version
exit /b %ERRORLEVEL%
