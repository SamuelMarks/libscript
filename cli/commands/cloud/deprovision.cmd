@echo off
:: # deprovision.cmd
::
:: ## Overview
:: Tears down and deprovisions cloud infrastructure resources.
:: 
:: ## Usage
:: Execute this script to destroy cloud resources.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\..\.."
)
shift
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\teardown_cloud.cmd" %*
goto :eof


