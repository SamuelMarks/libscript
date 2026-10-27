@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for filestore on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for filestore.

:: Windows environment configuration and PATH probes for gcp-filestore
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if "%GCP_FILESTORE_ENABLED%"=="" set "GCP_FILESTORE_ENABLED=1"
if "%FILESTORE_VERSION%"=="" set "FILESTORE_VERSION=latest"
set "_CAND_P=%LIBSCRIPT_HOME%\filestore\%FILESTORE_VERSION%\bin"
echo ";!PATH!;" | findstr /I /C:";!_CAND_P!;" >nul 2>&1
if errorlevel 1 set "PATH=!_CAND_P!;!PATH!"
set "CALLER_SCRIPT_DIR=%SCRIPT_DIR%"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "gcp-filestore" "%GCP_FILESTORE_VERSION%"

endlocal & (
    set "FILESTORE_VERSION=%FILESTORE_VERSION%"
    set "GCP_FILESTORE_ENABLED=%GCP_FILESTORE_ENABLED%"
    set "PATH=%PATH%"
)
exit /b 0
