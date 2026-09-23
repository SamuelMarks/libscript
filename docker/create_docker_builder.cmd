@echo off
:: # create_docker_builder.cmd
::
:: ## Overview
:: Creates a Docker-based builder environment for isolated compilation on Windows.
:: 
:: ## Usage
:: Execute this script to generate docker_builder.cmd for building Docker images.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "PREFIX=%DOCKER_IMAGE_PREFIX%"
if "%PREFIX%"=="" set "PREFIX=deploysh-"
set "SUFFIX=%DOCKER_IMAGE_SUFFIX%"
if "%SUFFIX%"=="" set "SUFFIX=-latest"
set "BUILDER_OUT=%SCRIPT_DIR%\docker_builder.cmd"

echo Generating %BUILDER_OUT%...
> "%BUILDER_OUT%" (
    echo @echo off
    echo :: Auto-generated docker build script
    echo.
)

for /f "delims=" %%D in ('dir /b /s "%SCRIPT_DIR%\*Dockerfile*" 2^>nul') do (
    set "df=%%D"
    set "fname=%%~nxD"
    if not "!fname!"=="create_docker_builder.cmd" if not "!fname!"=="create_docker_builder.sh" (
        for %%I in ("!df!\..") do set "dir_name=%%~nxI"
        >> "%BUILDER_OUT%" echo docker build %DOCKER_BUILD_ARGS% -f "%%D" -t "%PREFIX%!dir_name!%SUFFIX%" .
    )
)

echo %BUILDER_OUT% generated successfully.
exit /b 0
