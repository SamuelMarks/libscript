@echo off
:: Windows env stub for cargo

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CARGO_VERSION%"=="" (
    set "CARGO_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cargo\%CARGO_VERSION%\bin;%PATH%"
