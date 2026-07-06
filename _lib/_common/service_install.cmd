:: LibScript Service Installer for Windows
:: Registers a Windows service
@echo off
:: # service_install.cmd
::
:: ## Overview
:: Internal script for service_install on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for service_install.

setlocal EnableDelayedExpansion

set "_SERVICE_NAME=%~1"
set "_EXEC_START=%~2"
set "_WORKING_DIR=%~3"
set "_DESCRIPTION=%~4"

if "%_SERVICE_NAME%"=="" (
    echo Usage: %0 [SERVICE_NAME] [EXEC_START] [WORKING_DIR] [DESCRIPTION]
    exit /b 1
)

if "%~5"=="uninstall" (
    echo Uninstalling Windows service: %_SERVICE_NAME%
    sc.exe stop "%_SERVICE_NAME%"
    sc.exe delete "%_SERVICE_NAME%"
    exit /b 0
)

if "%_DESCRIPTION%"=="" set "_DESCRIPTION=%_SERVICE_NAME% service"

echo Installing Windows service: %_SERVICE_NAME%
sc.exe create "%_SERVICE_NAME%" binPath= "%_EXEC_START%" start= auto obj= LocalSystem
sc.exe description "%_SERVICE_NAME%" "%_DESCRIPTION%"

exit /b 0
