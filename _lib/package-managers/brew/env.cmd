@echo off
:: Windows env stub for brew

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%BREW_VERSION%"=="" (
    set "BREW_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\brew\%BREW_VERSION%\bin;%PATH%"
