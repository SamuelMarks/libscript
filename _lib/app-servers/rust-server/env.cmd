@echo off
:: Windows env stub for rust-server

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%RUST_SERVER_VERSION%"=="" (
    set "RUST_SERVER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\rust-server\%RUST_SERVER_VERSION%\bin;%PATH%"
