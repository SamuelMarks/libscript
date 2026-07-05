@echo off
:: Windows env stub for jetstream

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%JETSTREAM_VERSION%"=="" (
    set "JETSTREAM_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\jetstream\%JETSTREAM_VERSION%\bin;%PATH%"
