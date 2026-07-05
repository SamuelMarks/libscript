@echo off
:: Windows env stub for iis

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%IIS_VERSION%"=="" (
    set "IIS_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\iis\%IIS_VERSION%\bin;%PATH%"
