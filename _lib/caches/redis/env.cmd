@echo off
:: Windows env stub for redis

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%REDIS_VERSION%"=="" (
    set "REDIS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\redis\%REDIS_VERSION%\bin;%PATH%"
