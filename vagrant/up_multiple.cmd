@echo off
:: # up_multiple.cmd
::
:: ## Overview
:: Vagrant environment configuration and setup scripts.
:: 
:: ## Usage
:: Execute this script within the context of Vagrant provisioning.

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Vagrant environment configuration and setup scripts.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
echo This script (%~nx0) is not implemented natively for Windows.
exit /b 1
