@echo off
:: Windows env stub for mariadb

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%MARIADB_VERSION%"=="" (
    set "MARIADB_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\mariadb\%MARIADB_VERSION%\bin;%PATH%"
