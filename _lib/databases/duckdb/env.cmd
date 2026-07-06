@echo off
:: # env.cmd
::
:: ## Overview
:: Internal script for duckdb on Windows.
::
:: ## Usage
:: Executes initialization, logic, or testing for duckdb.

:: Windows env stub for duckdb

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%DUCKDB_VERSION%"=="" (
    set "DUCKDB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\duckdb\%DUCKDB_VERSION%\bin;%PATH%"
