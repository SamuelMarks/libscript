@echo off
:: Windows env stub for 7zip

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%SEVENZIP_VERSION%"=="" (
    set "SEVENZIP_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\7zip\%SEVENZIP_VERSION%\bin;%PATH%"
