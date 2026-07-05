@echo off
:: Windows env stub for conda

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%CONDA_VERSION%"=="" (
    set "CONDA_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\conda\%CONDA_VERSION%\bin;%PATH%"
