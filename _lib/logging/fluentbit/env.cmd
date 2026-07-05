@echo off
:: Windows env stub for fluentbit

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%FLUENTBIT_VERSION%"=="" (
    set "FLUENTBIT_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\fluentbit\%FLUENTBIT_VERSION%\bin;%PATH%"
