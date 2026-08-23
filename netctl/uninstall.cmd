@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Handles the removal and uninstallation process for the component 'netctl' stack.
:: 
:: ## Usage
:: Execute this script to remove netctl and its associated configurations from the system.

setlocal EnableDelayedExpansion

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Handles the removal and uninstallation process for the component 'netctl' stack.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
echo Uninstalling netctl is not supported via this script.
exit /b 0
