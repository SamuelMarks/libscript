@echo off
:: Windows env stub for rabbitmq

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%RABBITMQ_VERSION%"=="" (
    set "RABBITMQ_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\rabbitmq\%RABBITMQ_VERSION%\bin;%PATH%"
