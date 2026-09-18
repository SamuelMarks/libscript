@echo off
:: # provision.cmd
::
:: ## Overview
:: Provisions necessary cloud infrastructure resources.
:: 
:: ## Usage
:: Execute this script to create cloud resources.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\..\.."
)
shift
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\deploy_cloud.cmd" %*
goto :eof

