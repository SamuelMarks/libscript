@echo off
:: Windows env stub for duckdb

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DUCKDB_VERSION%"=="" (
    set "DUCKDB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%\bin;%PATH%"
