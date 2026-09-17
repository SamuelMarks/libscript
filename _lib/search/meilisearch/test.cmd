@echo off
:: # test.cmd
::
:: ## Overview
:: Verifies Meilisearch on Windows.
::
:: ## Usage
:: Execute this script to test Meilisearch functionality.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0env.cmd"
meilisearch --version
exit /b %ERRORLEVEL%
