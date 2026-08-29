@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # update_results.cmd
::
:: ## Overview
:: Updates the Supported Components table in README.md with test results on Windows.
::
:: ## Usage
:: Execute this script to update test results.

set "THIS_DIR=%~dp0"
set "REPO_ROOT=%THIS_DIR%.."

python "%THIS_DIR%update_results.py" "%REPO_ROOT%"
exit /b %ERRORLEVEL%
