@echo off
:: # service_install.cmd
::
:: ## Overview
:: Internal script for service_install on Windows. Registers or removes a Windows service.
::
:: ## Usage
:: service_install.cmd <install|uninstall> <service_name> [exec_start] [description]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

if "%~1"=="--uninstall" (
    echo Uninstalling Windows service: %~2
    sc.exe stop "%~2" >nul 2>&1
    sc.exe delete "%~2"
    exit /b 0
)
if "%~1"=="uninstall" (
    echo Uninstalling Windows service: %~2
    sc.exe stop "%~2" >nul 2>&1
    sc.exe delete "%~2"
    exit /b 0
)

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
    sc.exe stop "%_SERVICE_NAME%" >nul 2>&1
    sc.exe delete "%_SERVICE_NAME%"
    exit /b 0
)

if "%_DESCRIPTION%"=="" set "_DESCRIPTION=%_SERVICE_NAME% service"

echo Installing Windows service: %_SERVICE_NAME%
sc.exe create "%_SERVICE_NAME%" binPath= "%_EXEC_START%" start= auto obj= LocalSystem
sc.exe description "%_SERVICE_NAME%" "%_DESCRIPTION%"

exit /b 0
