@echo off
:: Windows env stub for python-server

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)

if "%PYTHON_SERVER_VERSION%"=="" (
    set "PYTHON_SERVER_VERSION=latest"
)

set "PATH=%LIBSCRIPT_HOME%\python-server\%PYTHON_SERVER_VERSION%\bin;%PATH%"
