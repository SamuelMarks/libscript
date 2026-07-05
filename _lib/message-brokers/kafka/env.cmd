@echo off
:: Windows env stub for kafka

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%KAFKA_VERSION%"=="" (
    set "KAFKA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\kafka\%KAFKA_VERSION%\bin;%PATH%"
