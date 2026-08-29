@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for docker on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for docker.

:: Windows env stub for docker
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DOCKER_VERSION%"=="" (
    set "DOCKER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\docker\%DOCKER_VERSION%\bin;%PATH%"
