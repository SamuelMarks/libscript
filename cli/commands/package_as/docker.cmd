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
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [--compose] [--offline^|--online] [args...]
    echo Generates Dockerfile or docker-compose.yml.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"

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
