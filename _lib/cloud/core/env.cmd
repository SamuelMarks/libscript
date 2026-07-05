@echo off
:: Windows env stub for core

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CORE_VERSION%"=="" (
    set "CORE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\core\%CORE_VERSION%\bin;%PATH%"
