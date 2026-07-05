@echo off
:: Windows env stub for coursier

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%COURSIER_VERSION%"=="" (
    set "COURSIER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\coursier\%COURSIER_VERSION%\bin;%PATH%"
