@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the Firecrawl crawler stack.
:: 
:: ## Usage
:: Execute this script to install and configure firecrawl on the local system.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if not defined LIBSCRIPT_ROOT_DIR set "LIBSCRIPT_ROOT_DIR=%~dp0..\..\.."
set "LOG_CMD=%~dp0\..\..\..\_lib\_common\log.cmd"
if not exist "!LOG_CMD!" set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"
call "!LOG_CMD!" :log_warn "firecrawl is not supported on Windows natively."
exit /b 0
