@echo off
:: Windows env stub for cargo-binstall

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CARGO_BINSTALL_VERSION%"=="" (
    set "CARGO_BINSTALL_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\cargo-binstall\%CARGO_BINSTALL_VERSION%\bin;%PATH%"
