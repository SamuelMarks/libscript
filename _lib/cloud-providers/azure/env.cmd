@echo off
:: Windows env stub for azure

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%AZURE_VERSION%"=="" (
    set "AZURE_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\azure\%AZURE_VERSION%\bin;%PATH%"
