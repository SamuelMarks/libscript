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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

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

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

call "%REPO_ROOT%\_lib\orchestration\vm_builder.cmd" "%REPO_ROOT%\_lib\cloud-providers\hetzner\setup.sh" %*
exit /b %ERRORLEVEL%
