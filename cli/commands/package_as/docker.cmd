@echo off
:: # docker.cmd
::
:: ## Overview
:: Dual-modality container export driver for Docker and Docker Compose on Windows.
:: Generates online layer-cached or air-gapped offline Dockerfile and docker-compose.yml.
::
:: ## Usage
:: docker.cmd [--compose] [--offline|--online] [args...]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)

for %%I in ("!SCRIPT_DIR!\..\..\..") do set "REPO_ROOT=%%~fI"

set "IS_COMPOSE=0"
for %%A in (%*) do (
    if "%%~A"=="--compose" set "IS_COMPOSE=1"
)

if "%IS_COMPOSE%"=="1" (
    call "%REPO_ROOT%\cli\commands\packaging\formats\pkg_docker_compose.cmd" %*
) else (
    call "%REPO_ROOT%\cli\commands\packaging\formats\pkg_docker.cmd" %*
)
exit /b %ERRORLEVEL%
