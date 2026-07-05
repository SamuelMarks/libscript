@echo off
:: Windows env stub for gcp

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%GCP_VERSION%"=="" (
    set "GCP_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\gcp\%GCP_VERSION%\bin;%PATH%"
