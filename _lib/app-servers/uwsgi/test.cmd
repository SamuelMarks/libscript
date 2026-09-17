@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies uWSGI on Windows.
::
:: ## Usage
:: Execute this script to test uWSGI functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
uwsgi --version
exit /b %ERRORLEVEL%
