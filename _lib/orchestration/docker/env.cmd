@echo off
:: Windows env stub for docker

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DOCKER_VERSION%"=="" (
    set "DOCKER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\docker\%DOCKER_VERSION%\bin;%PATH%"
