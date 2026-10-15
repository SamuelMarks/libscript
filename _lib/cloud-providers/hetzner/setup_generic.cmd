@echo off
:: # setup.cmd
::
:: ## Overview
:: Hetzner Cloud and Bare-Metal server provider on Windows.
:: Configures server deployment actions and streams disk images.
::
:: ## Usage
:: setup.cmd [action] [server_ip_or_id] [disk_image] [target_device]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [action] [server_ip] [disk_image] [target_device]
    echo Hetzner Cloud and Bare-Metal server provider.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [action] [server_ip] [disk_image] [target_device]
    echo Hetzner Cloud and Bare-Metal server provider.
    exit /b 0
)

if "%~1"=="" (
    call "%~dp0setup_windows.cmd"
    exit /b %ERRORLEVEL%
)
if /i "%~1"=="install" (
    call "%~dp0setup_windows.cmd"
    exit /b %ERRORLEVEL%
)

for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\_lib\cloud-providers\hetzner\setup.sh" %*
exit /b %ERRORLEVEL%
