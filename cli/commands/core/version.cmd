@echo off
:: # version.cmd
::
:: ## Overview
:: Outputs the current version information for libscript or its components.
:: 
:: ## Usage
:: Execute this script to display version details.
set "THIS_FILE=%~f0"

if "%cmd%" == "--version" goto :show_version
if "%cmd%" == "-v" goto :show_version
goto :eof

:: ## show_version
:: Executes show_version functionality.
:show_version
if defined LIBSCRIPT_VERSION (
    echo %LIBSCRIPT_VERSION%
) else (
    echo dev
)
exit /b 0
