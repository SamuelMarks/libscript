@echo off
:: Windows env stub for composer

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%COMPOSER_VERSION%"=="" (
    set "COMPOSER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\composer\%COMPOSER_VERSION%\bin;%PATH%"
