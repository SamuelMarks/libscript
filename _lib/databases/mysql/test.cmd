@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies MySQL client or server on Windows.
::
:: ## Usage
:: Execute this script to test MySQL functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
mysql --version
exit /b %ERRORLEVEL%
