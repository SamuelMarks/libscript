@echo off
:: Windows env stub for nats

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%NATS_VERSION%"=="" (
    set "NATS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\nats\%NATS_VERSION%\bin;%PATH%"
